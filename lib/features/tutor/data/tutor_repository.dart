import 'dart:async';
import 'dart:convert';

import '../../../core/config/api_endpoints.dart';
import '../../../core/error/failure.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/network/api_client.dart';
import '../../session/domain/session_models.dart';
import '../domain/tutor_models.dart';

/// El tutor con IA, según `TUTOR-CONTRATO.md` del backend (v3).
abstract interface class TutorRepository {
  /// `GET /tutor/estado`: si está disponible, su nombre, el cupo y las
  /// sugerencias del estado vacío.
  Future<EstadoDelServicio> estado();

  /// Manda un mensaje y devuelve la respuesta a medida que llega.
  ///
  /// Los errores de **antes** del stream (el muro, el límite del día) salen
  /// como error del stream con su [Failure], igual que en cualquier petición.
  Stream<EventoDelTutor> enviar({
    required String mensaje,
    String? sesionId,
    TipoDeMensaje tipo = TipoDeMensaje.normal,
    ContextoDelTutor? contexto,
  });

  /// 👍 / 👎, o `null` para quitarlo.
  Future<void> valorar(String mensajeId, {required bool? util});

  /// La pregunta de un chip `[pregunta:…]`, con la clave y la explicación.
  Future<Question> pregunta(String id);
}

class ApiTutorRepository implements TutorRepository {
  ApiTutorRepository(this._client);

  final ApiClient _client;

  @override
  Future<EstadoDelServicio> estado() async {
    final json = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.tutorEstado,
    );
    return estadoDesdeJson(json);
  }

  @override
  Stream<EventoDelTutor> enviar({
    required String mensaje,
    String? sesionId,
    TipoDeMensaje tipo = TipoDeMensaje.normal,
    ContextoDelTutor? contexto,
  }) async* {
    final bytes = await _client.postStream(
      ApiEndpoints.tutorChat,
      data: {
        'sesionId': ?sesionId,
        'mensaje': mensaje,
        'tipo': tipo.codigo,
        if (contexto != null)
          'contexto': {
            'preguntaId': ?contexto.preguntaId,
            'origen': contexto.origen.codigo,
          },
      },
    );
    yield* leerEventosDelTutor(bytes);
  }

  @override
  Future<void> valorar(String mensajeId, {required bool? util}) async {
    await _client.raw.post<void>(
      ApiEndpoints.tutorValoracion(mensajeId),
      data: {'util': util},
    );
  }

  @override
  Future<Question> pregunta(String id) async {
    final json = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.tutorPregunta(id),
    );
    return Question.fromJson(json);
  }
}

/// Traduce `GET /tutor/estado`. Sin `disponible: true` no hay tutor.
EstadoDelServicio estadoDesdeJson(Map<String, dynamic> json) {
  final cupo = _cupo(json['cupo']);
  final sugerencias = json['sugerencias'];
  return EstadoDelServicio(
    disponible: json['disponible'] == true,
    nombre: json['nombre'] as String?,
    premium: cupo.tipo == 'dia' || json['plan'] == 'premium',
    restantesHoy: cupo.tipo == 'dia' ? cupo.restantes : null,
    restantesPrueba: cupo.tipo == 'prueba' ? cupo.restantes : null,
    sugerencias: {
      if (sugerencias is Map)
        for (final c in CategoriaDeSugerencia.values)
          if (sugerencias[c.name] case final List<dynamic> l)
            c: [
              for (final s in l)
                if (s is String && s.trim().isNotEmpty) s.trim(),
            ],
    },
  );
}

({String? tipo, int? restantes}) _cupo(Object? json) => switch (json) {
  {'tipo': final String tipo, 'restantes': final int restantes} => (
    tipo: tipo,
    restantes: restantes,
  ),
  {'tipo': final String tipo} => (tipo: tipo, restantes: null),
  _ => (tipo: null, restantes: null),
};

/// Lee el SSE de `POST /tutor/chat` y lo convierte en eventos.
///
/// Cada evento es un bloque `event:` + `data:` terminado en línea vacía. Las
/// líneas que empiezan con `:` son el `ping` de cada 15 s y se ignoran, igual
/// que un evento que la app no conoce: el servidor puede sumar tipos nuevos
/// sin romper versiones viejas.
Stream<EventoDelTutor> leerEventosDelTutor(Stream<List<int>> bytes) async* {
  String? evento;
  final datos = StringBuffer();

  EventoDelTutor? cerrar() {
    final e = evento;
    final d = datos.toString();
    evento = null;
    datos.clear();
    if (e == null || d.isEmpty) return null;
    final Object? json;
    try {
      json = jsonDecode(d);
    } on FormatException {
      return null;
    }
    if (json is! Map<String, dynamic>) return null;
    return eventoDesdeJson(e, json);
  }

  final lineas = bytes
      .cast<List<int>>()
      .transform(utf8.decoder)
      .transform(const LineSplitter());
  await for (final linea in lineas) {
    if (linea.isEmpty) {
      if (cerrar() case final e?) yield e;
    } else if (linea.startsWith(':')) {
      continue;
    } else if (linea.startsWith('event:')) {
      evento = linea.substring(6).trim();
    } else if (linea.startsWith('data:')) {
      if (datos.isNotEmpty) datos.write('\n');
      datos.write(linea.substring(5).trimLeft());
    }
  }
  if (cerrar() case final e?) yield e;
}

/// Un evento del stream, o `null` si no es uno que la app conozca.
EventoDelTutor? eventoDesdeJson(String evento, Map<String, dynamic> d) {
  return switch (evento) {
    'inicio' => InicioDeRespuesta(
      sesionId: d['sesionId'] as String? ?? '',
      mensajeId: d['mensajeId'] as String? ?? '',
    ),
    'estado' => FaseDeRespuesta(d['fase'] as String? ?? ''),
    'delta' => TrozoDeRespuesta(d['texto'] as String? ?? ''),
    'fin' => () {
      final cupo = _cupo(d['cupo']);
      return FinDeRespuesta(
        mensajeId: d['mensajeId'] as String?,
        restantesHoy: cupo.tipo == 'dia' ? cupo.restantes : null,
        restantesPrueba: cupo.tipo == 'prueba' ? cupo.restantes : null,
      );
    }(),
    'error' => FalloDeRespuesta(
      d['mensaje'] as String? ?? 'El tutor se interrumpió. Inténtalo de nuevo.',
    ),
    _ => null,
  };
}

// ==================== DOBLE ====================

/// Un tutor de mentira, para construir y probar la pantalla sin servidor.
///
/// Responde por trozos y con pausas, como el de verdad, y sus respuestas
/// llevan todos los marcadores: citas de pregunta y de clase, una tarjeta de
/// práctica y opciones rápidas. Lleva la cuenta de la prueba gratis y, al
/// gastarla, responde el mismo 403 que el servidor.
class FakeTutorRepository implements TutorRepository {
  FakeTutorRepository({
    this.premium = false,
    int restantesPrueba = 15,
    this.pausa = const Duration(milliseconds: 45),
    this.pensar = const Duration(milliseconds: 700),
    this.fallarAMitad = false,
    this.nombre,
  }) : _restantes = restantesPrueba;

  final bool premium;
  final Duration pausa;
  final Duration pensar;
  final String? nombre;

  /// Corta la siguiente respuesta a la mitad con un `error`, para probar
  /// «Reintentar». Se apaga sola después de usarse.
  bool fallarAMitad;

  int _restantes;
  var _n = 0;

  /// Lo que se valoró, para las pruebas.
  final valoraciones = <String, bool?>{};

  /// Los mensajes que se mandaron, para las pruebas.
  final enviados =
      <({String mensaje, TipoDeMensaje tipo, String? preguntaId})>[];

  static const _sugerencias = {
    CategoriaDeSugerencia.entender: [
      '¿Por qué la metformina es primera línea en DM2?',
      'Explícame la preeclampsia con signos de severidad',
    ],
    CategoriaDeSugerencia.practicar: ['Hazme preguntas de mi área más débil'],
    CategoriaDeSugerencia.plan: ['¿Qué repaso esta semana?'],
  };

  @override
  Future<EstadoDelServicio> estado() async => EstadoDelServicio(
    nombre: nombre,
    premium: premium,
    restantesHoy: premium ? 50 - _n : null,
    restantesPrueba: premium ? null : _restantes,
    sugerencias: _sugerencias,
  );

  @override
  Stream<EventoDelTutor> enviar({
    required String mensaje,
    String? sesionId,
    TipoDeMensaje tipo = TipoDeMensaje.normal,
    ContextoDelTutor? contexto,
  }) async* {
    enviados.add((
      mensaje: mensaje,
      tipo: tipo,
      preguntaId: contexto?.preguntaId,
    ));
    if (!premium && _restantes <= 0) {
      throw const ForbiddenFailure(
        'Usaste tus mensajes de prueba con el tutor.',
        'FUNCION_PREMIUM',
        {'funcion': 'tutor', 'pruebaTotal': '15'},
      );
    }

    _n++;
    yield InicioDeRespuesta(sesionId: 'tses-falsa', mensajeId: 'tmsg-$_n');
    await Future<void>.delayed(pensar);

    final respuesta = _respuestaPara(mensaje, tipo, contexto);
    if (respuesta.contains('[comp:practica')) {
      yield const FaseDeRespuesta('revisando_estadisticas');
      await Future<void>.delayed(pensar);
    }

    if (!premium) _restantes--;
    final trozos = RegExp(r'\S+\s*').allMatches(respuesta).map((m) => m[0]!);
    final mitad = trozos.length ~/ 2;
    var i = 0;
    for (final t in trozos) {
      if (fallarAMitad && i == mitad) {
        fallarAMitad = false;
        yield const FalloDeRespuesta(
          'Se cortó la respuesta del tutor. Inténtalo de nuevo.',
        );
        return;
      }
      yield TrozoDeRespuesta(t);
      i++;
      if (pausa > Duration.zero) await Future<void>.delayed(pausa);
    }
    yield FinDeRespuesta(
      mensajeId: 'tmsg-$_n',
      restantesHoy: premium ? 50 - _n : null,
      restantesPrueba: premium ? null : _restantes,
    );
  }

  @override
  Future<void> valorar(String mensajeId, {required bool? util}) async {
    valoraciones[mensajeId] = util;
  }

  @override
  Future<Question> pregunta(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final preguntas = MockData.questions(cantidad: 5, conRespuestas: true);
    final n = int.tryParse(id.replaceFirst('q-', '')) ?? 1;
    return preguntas[(n - 1) % preguntas.length].copyWith(id: id);
  }

  String _respuestaPara(
    String mensaje,
    TipoDeMensaje tipo,
    ContextoDelTutor? contexto,
  ) {
    if (tipo == TipoDeMensaje.noEntiendo) return respuestaSimple;
    final m = mensaje.toLowerCase();
    if (m.contains('practic') ||
        m.contains('pregunt') ||
        m.contains('pregúnt')) {
      return respuestaPractica;
    }
    if (m.contains('plan') || m.contains('repaso')) return respuestaPlan;
    if (contexto?.preguntaId case final id?) return respuestaSobrePregunta(id);
    return respuestaEntender;
  }

  static const respuestaEntender = '''
## Metformina en la DM2

La metformina es la **primera línea** porque baja la glucosa sin causar hipoglucemia y no aumenta el peso.

- Reduce la producción hepática de glucosa.
- Mejora la sensibilidad a la insulina.
- Es barata y tiene décadas de seguridad.

Ojo con la *acidosis láctica*: se evita con una TFG menor de `30 ml/min`. Mira cómo lo preguntaron [pregunta:q-2] y repásalo en la clase [clase:pediatria/pediatria.01-02].

¿Quieres que te haga unas preguntas sobre esto? 💊
[opciones:["Sí, pregúntame","Explícamelo más simple","Ahora no"]]''';

  static String respuestaSobrePregunta(String id) =>
      '''
Vamos con esta pregunta [pregunta:$id].

La clave es reconocer el **cuadro típico** antes de mirar las alternativas:

1. Identifica el dato que define el diagnóstico.
2. Descarta las que no lo explican.
3. Elige la conducta, no solo el diagnóstico.

¿Te explico por qué falla cada distractor?
[opciones:["Sí, uno por uno","Dame un truco para recordarlo"]]''';

  static const respuestaPractica = '''
Tu área más floja ahora es **Ginecología y Obstetricia**. Te armé una práctica corta para cerrar esa brecha:

[comp:practica:{"area":"gineco-obstetricia","tema":null,"n":10}]

Cuando termines, cuéntame cuáles fallaste y las repasamos. 💪''';

  static const respuestaPlan = '''
### Esta semana

- **Lunes y martes:** Ginecología y Obstetricia, tu área más débil.
- **Miércoles:** Pediatría.
- **Jueves:** repaso de las que fallaste.
- **Viernes:** un simulacro corto.

¿Empezamos por la práctica de hoy?
[opciones:["Sí, empecemos","Cámbiame el orden"]]''';

  static const respuestaSimple = '''
Te lo digo más simple: la metformina es como **cerrar la llave** del hígado, que suelta azúcar de más. Por eso baja la glucosa sin provocar bajones. ✅''';
}
