import 'package:freezed_annotation/freezed_annotation.dart';

import '../../session/domain/session_models.dart';

part 'offline_models.freezed.dart';
part 'offline_models.g.dart';

/// El paquete de un área tal como lo manda el servidor (`GET /offline/packages/:areaId`).
///
/// Las preguntas vienen **reveladas**: con la clave correcta y la explicación.
/// Es lo que hace posible corregir sin conexión, y la razón de que el servidor
/// solo lo entregue a quien tiene plan y de que aquí se guarde cifrado.
@freezed
abstract class PaqueteOffline with _$PaqueteOffline {
  const factory PaqueteOffline({
    required String areaId,
    required DateTime generadoEn,
    @Default([]) List<Question> preguntas,
    @Default(0) int total,
  }) = _PaqueteOffline;

  factory PaqueteOffline.fromJson(Map<String, dynamic> json) =>
      _$PaqueteOfflineFromJson(json);
}

/// Lo que respondió `POST /offline/sync`.
@freezed
abstract class ResultadoDeSync with _$ResultadoDeSync {
  const factory ResultadoDeSync({
    @Default(0) int aceptadas,

    /// Prácticas hechas sin señal que quedaron registradas en el servidor.
    ///
    /// **Nulo significa que el servidor ni sabe de qué le hablan**, no cero. Un
    /// backend anterior a las prácticas creadas en el teléfono no manda este
    /// campo, y la diferencia decide si lo que se estudió en el bus se puede
    /// dar por entregado o hay que volver a intentarlo: darlo por bueno contra
    /// un servidor que ignoró las sesiones borraría de la bandeja respuestas
    /// que nunca llegaron a ninguna parte.
    int? sesionesCreadas,
    @Default([]) List<ConflictoDeSync> conflictos,
  }) = _ResultadoDeSync;

  const ResultadoDeSync._();

  factory ResultadoDeSync.fromJson(Map<String, dynamic> json) =>
      _$ResultadoDeSyncFromJson(json);

  bool get todoEntro => conflictos.isEmpty;
}

/// Una respuesta que el servidor no pudo aplicar, con el motivo en español.
@freezed
abstract class ConflictoDeSync with _$ConflictoDeSync {
  const factory ConflictoDeSync({
    required String questionId,
    @Default('') String motivo,
  }) = _ConflictoDeSync;

  factory ConflictoDeSync.fromJson(Map<String, dynamic> json) =>
      _$ConflictoDeSyncFromJson(json);
}

/// En qué situación está el área respecto de la descarga.
enum EstadoDescarga {
  /// Nunca se descargó, o se eliminó.
  noDescargada,

  /// Bajando ahora mismo.
  descargando,

  /// Lista y al día.
  descargada,

  /// Está en el teléfono, pero el catálogo dice que hay preguntas nuevas.
  actualizable,
}

/// Un área en la pantalla de descargas: lo del catálogo cruzado con lo que hay
/// guardado en el teléfono.
typedef PaqueteEnPantalla = ({
  String areaId,
  String nombre,
  EstadoDescarga estado,

  /// Cuántas preguntas hay guardadas. Cero si no está descargada.
  int guardadas,

  /// Cuántas ofrece el catálogo. Es la referencia para saber si falta bajar.
  int disponibles,

  /// Tamaño real en disco, en bytes. Cero si no está descargada.
  int bytes,

  /// Progreso de 0 a 1 mientras baja.
  double progreso,
});

/// El resumen de un paquete guardado, **sin descifrar su contenido**.
///
/// La pantalla de descargas necesita saber cuánto ocupa y cuántas preguntas
/// tiene; descifrar el banco entero de cada área solo para pintar una lista
/// sería caro y sin motivo.
typedef ResumenDePaquete = ({
  String areaId,
  DateTime generadoEn,
  DateTime descargadoEn,
  int total,
  int bytes,
});

/// Una respuesta hecha sin conexión, esperando su turno para viajar.
///
/// [respondidaEn] es el dato que resuelve los conflictos: el servidor descarta
/// la del teléfono si ya tenía una más reciente (contrato §7).
typedef RespuestaPendiente = ({
  String sesionId,
  String preguntaId,
  String? opcionId,
  int tiempoMs,
  bool marcada,
  DateTime respondidaEn,
});

/// Una práctica que armó el teléfono y el servidor todavía no conoce (RF-31).
///
/// Viaja en la misma petición que las respuestas, y antes que ellas: son sus
/// respuestas las que apuntan a esta sesión.
typedef SesionParaRegistrar = ({
  String id,
  List<String> preguntaIds,
  List<String> areaIds,
  DateTime iniciadaEn,
});

/// En qué punto está una sesión guardada en el teléfono.
enum EstadoSesionLocal {
  /// Creada en el servidor con conexión y guardada entera para después. Es lo
  /// que permite practicar sin señal: el servidor ya conoce esa sesión y sus
  /// preguntas, así que las respuestas encajan al sincronizar.
  reservada,

  /// El estudiante ya la empezó.
  enCurso,

  /// Terminada sin conexión. Falta que el servidor la cierre y ponga la nota
  /// oficial.
  terminada;

  bool get esReserva => this == EstadoSesionLocal.reservada;
}

/// Una sesión guardada en el teléfono, con sus preguntas y sus respuestas.
typedef SesionLocal = ({
  String areaId,
  EstadoSesionLocal estado,
  DateTime creadaEn,
  StudySession sesion,
});
