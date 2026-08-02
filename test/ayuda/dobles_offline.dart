import 'package:enam_app/core/error/failure.dart';
import 'package:enam_app/features/offline/data/offline_repository.dart';
import 'package:enam_app/features/offline/domain/offline_models.dart';
import 'package:enam_app/features/session/data/session_repository.dart';
import 'package:enam_app/features/session/domain/session_models.dart';

import 'offline.dart';

/// Un servidor de mentira al que se le puede cortar la luz.
///
/// Los dobles de las pruebas del modo sin conexión tienen que poder fallar
/// **como falla la red de verdad** —`NetworkFailure`, no una excepción
/// cualquiera—, porque justo esa distinción es la que decide si la app tira de
/// lo local o enseña el error.
class ServidorFalso implements SessionRepository, OfflineRepository {
  ServidorFalso({this.hayRed = true});

  bool hayRed;

  /// Sesiones que el servidor conoce.
  final Map<String, StudySession> sesiones = {};

  /// Respuestas que llegaron por `POST /offline/sync`.
  final List<RespuestaPendiente> sincronizadas = [];

  /// Sesiones cerradas con `submit`.
  final List<String> cerradas = [];

  /// Cuántas prácticas se pidieron crear. Delata las reservas de más.
  int practicasCreadas = 0;

  /// Preguntas que devuelve un paquete descargado.
  int preguntasPorPaquete = 40;

  /// Qué contestar en el próximo `sincronizar`. Por defecto, todo bien.
  ResultadoDeSync? respuestaDeSync;

  void _exigirRed() {
    if (!hayRed) throw const NetworkFailure();
  }

  // ---- Lo que usa el modo sin conexión ----

  @override
  Future<PaqueteOffline> paquete(
    String areaId, {
    void Function(int recibidos, int total)? progreso,
  }) async {
    _exigirRed();
    progreso?.call(500, 1000);
    progreso?.call(1000, 1000);

    return PaqueteOffline(
      areaId: areaId,
      generadoEn: DateTime(2026, 7, 20),
      preguntas: [
        for (var i = 1; i <= preguntasPorPaquete; i++)
          preguntaDePrueba('$areaId-p$i'),
      ],
      total: preguntasPorPaquete,
    );
  }

  @override
  Future<ResultadoDeSync> sincronizar(
    List<RespuestaPendiente> respuestas,
  ) async {
    _exigirRed();
    sincronizadas.addAll(respuestas);

    // Aplicarlas de verdad, como hace `Sincronizar` en el servidor: si el doble
    // se limita a acusar recibo, las pruebas no verían que tras sincronizar la
    // sesión del servidor ya trae lo que se respondió en el bus.
    for (final r in respuestas) {
      final sesion = sesiones[r.sesionId];
      if (sesion == null) continue;
      sesiones[r.sesionId] = sesion.copyWith(
        respuestas: {
          ...sesion.respuestas,
          r.preguntaId: Answer(
            questionId: r.preguntaId,
            optionId: r.opcionId,
            esCorrecta: r.opcionId?.endsWith('-b') ?? false,
            tiempoMs: r.tiempoMs,
            marcada: r.marcada,
            respondidaOffline: true,
          ),
        },
      );
    }

    return respuestaDeSync ?? ResultadoDeSync(aceptadas: respuestas.length);
  }

  @override
  Future<StudySession> startPractice(PracticeConfig config) async {
    _exigirRed();
    practicasCreadas++;

    final area = config.areaIds.isEmpty ? 'medicina' : config.areaIds.first;
    final sesion = StudySession(
      id: 'sesion-$practicasCreadas',
      tipo: SessionType.practica,
      estado: SessionStatus.enCurso,
      iniciadaEn: DateTime(2026, 7, 30, 9),
      preguntas: [
        for (var i = 1; i <= config.cantidadPreguntas; i++)
          // Sin la clave, como las manda el servidor hasta que respondes: la
          // corrección sin conexión tiene que salir del paquete descargado.
          preguntaDePrueba('$area-p$i').copyWith(
            opciones: [
              for (final o in preguntaDePrueba('$area-p$i').opciones)
                o.copyWith(esCorrecta: null),
            ],
          ),
      ],
    );

    sesiones[sesion.id] = sesion;
    return sesion;
  }

  @override
  Future<StudySession> session(String id) async {
    _exigirRed();
    final sesion = sesiones[id];
    if (sesion == null) throw const NotFoundFailure();
    return sesion;
  }

  @override
  Future<Answer> answer({
    required String sessionId,
    required String questionId,
    String? optionId,
    required int tiempoMs,
    bool marcada = false,
  }) async {
    _exigirRed();
    return Answer(
      questionId: questionId,
      optionId: optionId,
      esCorrecta: optionId?.endsWith('-b') ?? false,
      tiempoMs: tiempoMs,
      marcada: marcada,
    );
  }

  @override
  Future<StudySession> submit(String sessionId) async {
    _exigirRed();
    cerradas.add(sessionId);

    final sesion = sesiones[sessionId];
    if (sesion == null) throw const NotFoundFailure();
    return sesion.copyWith(
      estado: SessionStatus.finalizada,
      finalizadaEn: DateTime(2026, 7, 30, 10),
      nota: 14,
    );
  }

  @override
  Future<List<OpenSession>> openSessions() async {
    _exigirRed();
    return [
      for (final s in sesiones.values)
        if (s.estado == SessionStatus.enCurso)
          OpenSession(
            id: s.id,
            tipo: s.tipo,
            iniciadaEn: s.iniciadaEn,
            respondidas: s.respondidas,
            totalPreguntas: s.totalPreguntas,
          ),
    ];
  }

  // ---- Lo que no interviene en el modo sin conexión ----

  @override
  Future<StudySession> startSimulacro({bool esMuestra = false}) async =>
      throw UnimplementedError();

  @override
  Future<List<Question>> markedQuestions() async => throw UnimplementedError();

  @override
  Future<List<NationalMock>> nationalMocks() async => throw UnimplementedError();

  @override
  Future<StudySession> joinNationalMock(String mockId) async =>
      throw UnimplementedError();

  @override
  Future<List<PastExam>> pastExams() async => throw UnimplementedError();

  @override
  Future<StudySession> startPastExam(
    String examId, {
    required PastExamMode modo,
    int? cantidad,
  }) async => throw UnimplementedError();
}
