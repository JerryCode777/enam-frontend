/// El tutor con IA (fase 1): modelos de la conversación.
///
/// El contrato es `TUTOR-CONTRATO.md` del backend (borrador v2, 26/10/2026).
/// Son clases simples y no `freezed`: el texto llega en trozos por un stream,
/// y lo poco que llega como JSON lo traduce el repositorio a mano.
library;

/// Desde dónde se abrió el tutor (`contexto.origen`). Solo es analítica.
enum OrigenDelTutor {
  inicio('inicio'),

  /// Desde la explicación de una pregunta: el contexto es esa pregunta.
  explicacion('explicacion'),

  /// Desde el muro de las preguntas gratis del día: las preguntas se
  /// acabaron, pero la prueba del tutor puede seguir.
  muro('muro');

  const OrigenDelTutor(this.codigo);

  final String codigo;
}

/// El `tipo` de un mensaje del alumno.
enum TipoDeMensaje {
  normal('normal'),

  /// Tocó una sugerencia o una respuesta rápida.
  sugerencia('sugerencia'),

  /// El botón «No entiendo»: el tutor lo explica otra vez, más simple.
  noEntiendo('no_entiendo'),

  /// El servidor ignora el texto y responde otra vez al último mensaje.
  reintento('reintento');

  const TipoDeMensaje(this.codigo);

  final String codigo;
}

/// Con qué se abre el tutor.
class ContextoDelTutor {
  const ContextoDelTutor({
    this.origen = OrigenDelTutor.inicio,
    this.preguntaId,
    this.enunciado,
  });

  const ContextoDelTutor.pregunta({required String id, String? enunciado})
    : this(
        origen: OrigenDelTutor.explicacion,
        preguntaId: id,
        enunciado: enunciado,
      );

  final OrigenDelTutor origen;

  /// La pregunta de la que se quiere hablar. Se manda con el primer mensaje.
  final String? preguntaId;

  /// El enunciado, solo para que la pantalla diga de qué pregunta se habla.
  final String? enunciado;

  bool get sobreUnaPregunta => preguntaId != null;
}

/// Las tres categorías de sugerencias del estado vacío.
enum CategoriaDeSugerencia { entender, practicar, plan }

/// `GET /tutor/estado`.
///
/// Los límites son de Jerry (26/10/2026): en gratis, **15 mensajes de prueba
/// en total**, no por día; después el tutor es de Premium. En Premium, 50 al
/// día. Los números los manda el servidor: aquí no se fija ninguno.
class EstadoDelServicio {
  const EstadoDelServicio({
    this.disponible = true,
    this.nombre,
    this.premium = false,
    this.porDia,
    this.restantesHoy,
    this.restantesPrueba,
    this.sugerencias = const {},
  });

  /// Lo que se usa mientras el servidor no responde, y si no responde.
  static const nombrePorDefecto = 'Tu tutor ENAM';

  /// Si esta cuenta puede usar el tutor. Con `false` no hay puntos de entrada.
  final bool disponible;
  final String? nombre;
  final bool premium;
  final int? porDia;
  final int? restantesHoy;

  /// Los mensajes de prueba que le quedan a una cuenta gratis.
  final int? restantesPrueba;

  final Map<CategoriaDeSugerencia, List<String>> sugerencias;

  String get nombreVisible {
    final n = nombre?.trim();
    return n == null || n.isEmpty ? nombrePorDefecto : n;
  }
}

/// Por qué el tutor ya no responde.
enum BloqueoDelTutor {
  /// La cuenta gratis gastó lo suyo: el tutor sigue con Premium (muro).
  gratisAgotado,

  /// Premium gastó los mensajes de hoy: mañana tiene más. Nada que vender.
  limiteDelDia,
}

/// Lo que va llegando por el stream de una respuesta.
sealed class EventoDelTutor {
  const EventoDelTutor();
}

/// Siempre el primero: el servidor ya le dio id a la sesión y al mensaje.
final class InicioDeRespuesta extends EventoDelTutor {
  const InicioDeRespuesta({required this.sesionId, required this.mensajeId});

  final String sesionId;
  final String mensajeId;
}

/// El tutor está usando una herramienta. Lo borra el siguiente trozo.
final class FaseDeRespuesta extends EventoDelTutor {
  const FaseDeRespuesta(this.fase);

  final String fase;

  /// Lo que se le dice al alumno mientras tanto.
  String get texto => switch (fase) {
    'buscando_preguntas' => 'Buscando en el banco…',
    'leyendo_pregunta' => 'Leyendo la pregunta…',
    'revisando_estadisticas' => 'Revisando tu avance…',
    _ => 'Pensando…',
  };
}

/// Un trozo más del texto, para añadir al final.
final class TrozoDeRespuesta extends EventoDelTutor {
  const TrozoDeRespuesta(this.texto);

  final String texto;
}

/// La respuesta terminó bien.
final class FinDeRespuesta extends EventoDelTutor {
  const FinDeRespuesta({
    this.mensajeId,
    this.restantesHoy,
    this.restantesPrueba,
  });

  final String? mensajeId;
  final int? restantesHoy;
  final int? restantesPrueba;
}

/// El servidor cortó la respuesta a mitad. El mensaje ya es mostrable.
final class FalloDeRespuesta extends EventoDelTutor {
  const FalloDeRespuesta(this.mensaje);

  final String mensaje;
}

enum AutorDelMensaje { alumno, tutor }

enum EstadoDelMensaje {
  /// El tutor todavía no escribió nada: «Pensando…».
  pensando,

  /// Van llegando trozos.
  escribiendo,
  listo,

  /// Se cortó; el mensaje lleva [MensajeDelTutor.error] y se puede reintentar.
  fallo,
}

class MensajeDelTutor {
  const MensajeDelTutor({
    required this.id,
    required this.autor,
    required this.texto,
    this.estado = EstadoDelMensaje.listo,
    this.fase,
    this.error,
    this.util,
  });

  /// Local (`local-…`) hasta que el servidor le da el suyo.
  final String id;
  final AutorDelMensaje autor;
  final String texto;
  final EstadoDelMensaje estado;

  /// Lo que se muestra mientras el tutor usa una herramienta.
  final String? fase;
  final String? error;

  /// 👍 (`true`) o 👎 (`false`). `null` sin valorar.
  final bool? util;

  bool get esDelTutor => autor == AutorDelMensaje.tutor;

  bool get enCurso =>
      estado == EstadoDelMensaje.pensando ||
      estado == EstadoDelMensaje.escribiendo;

  MensajeDelTutor copyWith({
    String? id,
    String? texto,
    EstadoDelMensaje? estado,
    String? Function()? fase,
    String? error,
    bool? Function()? util,
  }) => MensajeDelTutor(
    id: id ?? this.id,
    autor: autor,
    texto: texto ?? this.texto,
    estado: estado ?? this.estado,
    fase: fase == null ? this.fase : fase(),
    error: error ?? this.error,
    util: util == null ? this.util : util(),
  );
}

class EstadoDelTutor {
  const EstadoDelTutor({
    this.mensajes = const [],
    this.sesionId,
    this.bloqueo,
    this.restantesPrueba,
  });

  /// Desde cuántos mensajes gratis restantes se enseña el contador. Antes
  /// sería ruido: con 15 por delante nadie necesita contarlos.
  static const avisarDesde = 5;

  final List<MensajeDelTutor> mensajes;
  final String? sesionId;

  /// Si no es `null`, la caja de texto deja paso al aviso o al muro.
  final BloqueoDelTutor? bloqueo;

  /// Mensajes gratis que quedan; `null` en Premium o si no se sabe.
  final int? restantesPrueba;

  bool get vacio => mensajes.isEmpty;

  /// El contador discreto, solo cuando quedan pocos.
  int? get contadorVisible => switch (restantesPrueba) {
    final n? when n > 0 && n <= avisarDesde => n,
    _ => null,
  };

  /// Si hay una respuesta en curso. Mientras tanto no se envía otra.
  bool get respondiendo => mensajes.any((m) => m.enCurso);

  EstadoDelTutor copyWith({
    List<MensajeDelTutor>? mensajes,
    String? sesionId,
    BloqueoDelTutor? bloqueo,
    int? restantesPrueba,
  }) => EstadoDelTutor(
    mensajes: mensajes ?? this.mensajes,
    sesionId: sesionId ?? this.sesionId,
    bloqueo: bloqueo ?? this.bloqueo,
    restantesPrueba: restantesPrueba ?? this.restantesPrueba,
  );
}
