import '../../../core/config/api_endpoints.dart';
import '../../../core/domain/blueprint.dart';
import '../../../core/error/failure.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/network/api_client.dart';
import '../domain/session_models.dart';

/// Sesiones de práctica y simulacro (Módulos 3 y 4 del SSD).
abstract interface class SessionRepository {
  /// RF-12. El servidor valida la config contra el plan del usuario (RN-03).
  Future<StudySession> startPractice(PracticeConfig config);

  /// RF-16. El servidor genera las 180 preguntas respetando el blueprint (RN-02).
  Future<StudySession> startSimulacro({bool esMuestra = false});

  /// Estado de una sesión, para reanudarla (RF-15).
  Future<StudySession> session(String id);

  /// Envía una respuesta. En práctica, la respuesta trae el feedback (RF-13).
  Future<Answer> answer({
    required String sessionId,
    required String questionId,
    String? optionId,
    required int tiempoMs,
    bool marcada = false,
  });

  /// RF-18. Cierra la sesión y devuelve la calificación (RN-01).
  Future<StudySession> submit(String sessionId);
}

class ApiSessionRepository implements SessionRepository {
  ApiSessionRepository(this._client);

  final ApiClient _client;

  @override
  Future<StudySession> startPractice(PracticeConfig config) async {
    final data = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.practiceSession,
      data: config.toJson(),
    );
    return StudySession.fromJson(data);
  }

  @override
  Future<StudySession> startSimulacro({bool esMuestra = false}) async {
    final data = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.simulacroSession,
      data: {'muestra': esMuestra},
    );
    return StudySession.fromJson(data);
  }

  @override
  Future<StudySession> session(String id) async {
    final data = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.session(id),
    );
    return StudySession.fromJson(data);
  }

  @override
  Future<Answer> answer({
    required String sessionId,
    required String questionId,
    String? optionId,
    required int tiempoMs,
    bool marcada = false,
  }) async {
    final data = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.sessionAnswers(sessionId),
      data: {
        'questionId': questionId,
        'optionId': optionId,
        'tiempoMs': tiempoMs,
        'marcada': marcada,
      },
    );
    return Answer.fromJson(data);
  }

  @override
  Future<StudySession> submit(String sessionId) async {
    final data = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.sessionSubmit(sessionId),
    );
    return StudySession.fromJson(data);
  }
}

/// Sesiones falsas.
///
/// Calcula la nota con [Blueprint.toVigesimal] igual que el servidor, para que
/// las pantallas de resultados muestren números coherentes.
class MockSessionRepository implements SessionRepository {
  final Map<String, StudySession> _sessions = {};

  /// Claves correctas por sesión: `{sessionId: {questionId: optionId}}`.
  ///
  /// Se guardan aparte porque en un simulacro las preguntas que ve el cliente
  /// NO llevan la clave (sería regalar la respuesta), pero al corregir hay que
  /// saberla. Es el mismo reparto que hace el servidor real.
  final Map<String, Map<String, String>> _claves = {};

  /// Preguntas completas por sesión, con clave y clasificación.
  ///
  /// El cliente recibe una versión recortada durante el simulacro (RF-16 y
  /// RN-09); estas son las de verdad, y se usan para corregir y para revelar
  /// todo al cerrar. Es el mismo reparto que hace el servidor.
  final Map<String, List<Question>> _originales = {};

  int _counter = 0;

  static const _delay = Duration(milliseconds: 500);

  /// Registra las claves y devuelve las preguntas tal como las vería el cliente.
  List<Question> _registrarClaves(
    String sessionId,
    List<Question> preguntas, {
    required bool revelarClaves,
  }) {
    final claves = <String, String>{};

    for (final pregunta in preguntas) {
      final correcta = pregunta.opciones.firstWhere(
        (o) => o.esCorrecta == true,
        orElse: () => pregunta.opciones.first,
      );
      claves[pregunta.id] = correcta.id;
    }
    _claves[sessionId] = claves;
    _originales[sessionId] = preguntas;

    if (revelarClaves) return preguntas;

    // Quitar toda pista antes de entregar al cliente: ni la clave (RF-16) ni la
    // clasificación (RN-09), porque en el examen real tampoco se ve de qué área
    // es la pregunta y saberlo acota las alternativas.
    return preguntas
        .map(
          (q) => q.copyWith(
            explicacion: null,
            areaId: null,
            subtemaId: null,
            opciones: q.opciones
                .map((o) => o.copyWith(esCorrecta: null, explicacion: null))
                .toList(),
          ),
        )
        .toList();
  }

  @override
  Future<StudySession> startPractice(PracticeConfig config) async {
    await Future<void>.delayed(_delay);

    final id = 'practica-${++_counter}';
    final session = StudySession(
      id: id,
      tipo: SessionType.practica,
      estado: SessionStatus.enCurso,
      iniciadaEn: DateTime.now(),
      preguntas: _registrarClaves(
        id,
        MockData.questions(
          cantidad: config.cantidadPreguntas,
          areaIds: config.areaIds,
          conRespuestas: true,
        ),
        // En práctica el feedback es inmediato (RF-13), así que sí van.
        revelarClaves: true,
      ),
    );
    return _sessions[id] = session;
  }

  @override
  Future<StudySession> startSimulacro({bool esMuestra = false}) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));

    final total = esMuestra
        ? Blueprint.sampleExamQuestions
        : Blueprint.totalQuestions;
    final id = 'simulacro-${++_counter}';

    final session = StudySession(
      id: id,
      tipo: SessionType.simulacro,
      estado: SessionStatus.enCurso,
      iniciadaEn: DateTime.now(),
      expiraEn: DateTime.now().add(Blueprint.examDuration),
      preguntas: _registrarClaves(
        id,
        MockData.questions(cantidad: total, conRespuestas: true),
        // En simulacro NO se revelan hasta el final (RF-16).
        revelarClaves: false,
      ),
    );
    return _sessions[id] = session;
  }

  @override
  Future<StudySession> session(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final session = _sessions[id];
    if (session == null) throw const NotFoundFailure('Sesión no encontrada.');
    return session;
  }

  @override
  Future<Answer> answer({
    required String sessionId,
    required String questionId,
    String? optionId,
    required int tiempoMs,
    bool marcada = false,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    final session = _sessions[sessionId];
    if (session == null) throw const NotFoundFailure('Sesión no encontrada.');

    // En práctica el servidor devuelve si acertó; en simulacro, no (RF-16).
    bool? esCorrecta;
    if (session.muestraFeedbackInmediato && optionId != null) {
      esCorrecta = _claves[sessionId]?[questionId] == optionId;
    }

    final answer = Answer(
      questionId: questionId,
      optionId: optionId,
      esCorrecta: esCorrecta,
      tiempoMs: tiempoMs,
      marcada: marcada,
    );

    _sessions[sessionId] = session.copyWith(
      respuestas: {...session.respuestas, questionId: answer},
    );
    return answer;
  }

  @override
  Future<StudySession> submit(String sessionId) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));

    final session = _sessions[sessionId];
    if (session == null) throw const NotFoundFailure('Sesión no encontrada.');

    final claves = _claves[sessionId] ?? const {};
    // Se corrige y se revela sobre las originales, no sobre las recortadas que
    // vio el cliente: ahí la clasificación venía en null (RN-09).
    final originales = _originales[sessionId] ?? session.preguntas;
    final corregidas = <String, Answer>{};
    final reveladas = <Question>[];
    var correctas = 0;

    for (final pregunta in originales) {
      final respuesta = session.respuestas[pregunta.id];
      final optionId = respuesta?.optionId;
      final claveId = claves[pregunta.id];

      // Sin responder e incorrecta valen igual: 0, sin puntaje en contra (RN-01).
      final acerto = optionId != null && optionId == claveId;
      if (acerto) correctas++;

      corregidas[pregunta.id] = (respuesta ?? Answer(questionId: pregunta.id))
          .copyWith(esCorrecta: acerto);

      // Al cerrar sí se revelan las claves, para la revisión (RF-18).
      reveladas.add(
        pregunta.copyWith(
          explicacion:
              'Explicación de la clave. Texto de relleno, no es información '
              'clínica válida.',
          opciones: pregunta.opciones
              .map((o) => o.copyWith(esCorrecta: o.id == claveId))
              .toList(),
        ),
      );
    }

    final finalizada = session.copyWith(
      estado: SessionStatus.finalizada,
      finalizadaEn: DateTime.now(),
      preguntas: reveladas,
      respuestas: corregidas,
      nota: Blueprint.toVigesimal(correctas, total: session.totalPreguntas),
    );
    return _sessions[sessionId] = finalizada;
  }
}
