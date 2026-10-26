/// Los marcadores que el tutor escribe dentro del texto y la app convierte en
/// componentes.
///
/// - `[pregunta:<id>]` y `[clase:<curso>/<clase>]` van **en línea**, dentro de
///   un párrafo: son chips de cita. Los resuelve [TextoDelTutor] al pintar.
/// - `[comp:practica:{…}]` y `[opciones:[…]]` son **bloques**: una tarjeta y
///   una fila de botones. Los separa [partirRespuesta].
///
/// El texto llega en trozos, así que un marcador puede estar a medias al
/// pintar. Mientras la respuesta no termina, lo que podría ser el comienzo de
/// uno no se enseña: si no, el alumno vería `[comp:prac` un instante y luego
/// una tarjeta.
library;

import 'dart:convert';

/// Un trozo de la respuesta, ya clasificado.
sealed class ParteDeRespuesta {
  const ParteDeRespuesta();
}

/// Markdown, con los chips de cita todavía dentro.
final class TextoDeRespuesta extends ParteDeRespuesta {
  const TextoDeRespuesta(this.markdown);

  final String markdown;
}

/// «Practicar ahora»: la sesión se crea solo al tocar la tarjeta.
final class PracticaPropuesta extends ParteDeRespuesta {
  const PracticaPropuesta({this.areaId, this.temaId, this.cantidad = 10});

  final String? areaId;
  final String? temaId;
  final int cantidad;

  @override
  bool operator ==(Object other) =>
      other is PracticaPropuesta &&
      other.areaId == areaId &&
      other.temaId == temaId &&
      other.cantidad == cantidad;

  @override
  int get hashCode => Object.hash(areaId, temaId, cantidad);
}

/// Respuestas rápidas: cada botón envía su texto como mensaje del alumno.
final class OpcionesRapidas extends ParteDeRespuesta {
  const OpcionesRapidas(this.opciones);

  final List<String> opciones;
}

/// Los dos marcadores en línea.
final citaDePregunta = RegExp(r'\[pregunta:([\w.\-]+)\]');
final citaDeClase = RegExp(r'\[clase:([\w.\-]+)/([\w.\-]+)\]');

const _inicioPractica = '[comp:practica:';
const _inicioOpciones = '[opciones:';
const _prefijos = ['[pregunta:', '[clase:', _inicioPractica, _inicioOpciones];

/// Separa [texto] en párrafos de markdown, tarjetas de práctica y opciones.
///
/// Con [completo] en `false` (la respuesta sigue llegando) se esconde lo que
/// quede de un marcador sin cerrar. Con la respuesta completa, un marcador mal
/// formado se queda como texto: es mejor ver algo raro que perder la frase.
List<ParteDeRespuesta> partirRespuesta(String texto, {bool completo = true}) {
  final partes = <ParteDeRespuesta>[];
  final texto0 = completo ? texto : _sinMarcadorAMedias(texto);

  var desde = 0;
  final buffer = StringBuffer();

  void cerrarTexto() {
    final t = buffer.toString().trim();
    if (t.isNotEmpty) partes.add(TextoDeRespuesta(t));
    buffer.clear();
  }

  while (desde < texto0.length) {
    final practica = texto0.indexOf(_inicioPractica, desde);
    final opciones = texto0.indexOf(_inicioOpciones, desde);
    final siguiente = [practica, opciones]
        .where((i) => i >= 0)
        .fold<int?>(null, (min, i) => min == null || i < min ? i : min);

    if (siguiente == null) {
      buffer.write(texto0.substring(desde));
      break;
    }

    buffer.write(texto0.substring(desde, siguiente));
    final esPractica = siguiente == practica;
    final inicioJson =
        siguiente + (esPractica ? _inicioPractica : _inicioOpciones).length;
    final fin = _finDelMarcador(texto0, inicioJson);

    final parte = fin == null
        ? null
        : esPractica
        ? _practica(texto0.substring(inicioJson, fin))
        : _opciones(texto0.substring(inicioJson, fin));

    if (parte == null) {
      // Mal formado o sin cerrar. Sin cerrar con la respuesta en curso ya se
      // recortó arriba; aquí solo llega con la respuesta completa.
      buffer.write(texto0.substring(siguiente, fin == null ? null : fin + 1));
      desde = fin == null ? texto0.length : fin + 1;
      continue;
    }

    cerrarTexto();
    partes.add(parte);
    desde = fin! + 1;
  }
  cerrarTexto();
  return partes;
}

/// El texto para copiar: sin marcadores de bloque y con las citas en palabras.
String textoParaCopiar(String texto) {
  final partes = partirRespuesta(texto);
  return partes
      .whereType<TextoDeRespuesta>()
      .map(
        (p) => p.markdown
            .replaceAll(citaDePregunta, '')
            .replaceAll(citaDeClase, '')
            .replaceAll(RegExp(r'[ \t]{2,}'), ' ')
            .replaceAllMapped(RegExp(r' ([.,;:])'), (m) => m[1]!),
      )
      .join('\n\n')
      .trim();
}

/// Esconde un marcador que empezó pero aún no se cierra.
///
/// Busca el último `[` sin su `]` y mira si lo que sigue es, o puede llegar a
/// ser, uno de los marcadores. Un corchete cualquiera («[ver tabla]») se deja.
String _sinMarcadorAMedias(String texto) {
  // Primero los de bloque: su JSON lleva corchetes, así que el último `[` del
  // texto puede ser uno de dentro. «Cerrado» es que el de apertura tenga su
  // pareja, no que haya un `]` cualquiera.
  for (final prefijo in [_inicioPractica, _inicioOpciones]) {
    final i = texto.lastIndexOf(prefijo);
    if (i >= 0 && _finDelMarcador(texto, i + prefijo.length) == null) {
      return texto.substring(0, i).trimRight();
    }
  }

  final abre = texto.lastIndexOf('[');
  if (abre < 0) return texto;
  final cola = texto.substring(abre);
  if (cola.contains(']')) return texto;

  final esMarcador = _prefijos.any(
    (p) => p.startsWith(cola) || cola.startsWith(p),
  );
  return esMarcador ? texto.substring(0, abre).trimRight() : texto;
}

/// El índice del `]` que cierra el marcador cuyo JSON empieza en [desde], o
/// `null` si todavía no llegó. Respeta corchetes, llaves y cadenas del JSON.
int? _finDelMarcador(String texto, int desde) {
  var profundidad = 0;
  var enCadena = false;
  var escapado = false;
  for (var i = desde; i < texto.length; i++) {
    final c = texto[i];
    if (enCadena) {
      if (escapado) {
        escapado = false;
      } else if (c == r'\') {
        escapado = true;
      } else if (c == '"') {
        enCadena = false;
      }
      continue;
    }
    switch (c) {
      case '"':
        enCadena = true;
      case '[' || '{':
        profundidad++;
      case ']' || '}':
        if (profundidad == 0) return c == ']' ? i : null;
        profundidad--;
    }
  }
  return null;
}

PracticaPropuesta? _practica(String json) {
  try {
    final m = jsonDecode(json);
    if (m is! Map<String, dynamic>) return null;
    String? texto(Object? v) => v is String && v.isNotEmpty ? v : null;
    final n = m['n'];
    return PracticaPropuesta(
      areaId: texto(m['area']),
      temaId: texto(m['tema']),
      // La práctica pide al menos 10 (PracticeMinQuestions) y el contrato
      // fija 20 de tope.
      cantidad: n is int ? n.clamp(10, 20) : 10,
    );
  } on FormatException {
    return null;
  }
}

OpcionesRapidas? _opciones(String json) {
  try {
    final l = jsonDecode(json);
    if (l is! List) return null;
    final opciones = [
      for (final o in l)
        if (o is String && o.trim().isNotEmpty) o.trim(),
    ];
    // Más de cuatro no caben como botones en un teléfono.
    return opciones.isEmpty ? null : OpcionesRapidas(opciones.take(4).toList());
  } on FormatException {
    return null;
  }
}
