import '../../../core/config/api_endpoints.dart';
import '../../../core/domain/blueprint.dart';
import '../../../core/error/failure.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/network/api_client.dart';
import '../domain/session_models.dart';

/// Cuánto dura un examen pasado según el modo elegido (RF-52).
/// Cuánto dura un examen pasado según el modo (RF-52).
///
/// En modo estudio no aplica: esa sesión no lleva reloj.
Duration duracionDe(PastExamMode modo) =>
    modo.esCorto ? Blueprint.sampleExamDuration : Blueprint.examDuration;

/// Lo que devuelve apuntarse a un simulacro nacional.
///
/// `sesion` viene en nulo mientras el simulacro no ha empezado: el sitio queda
/// apartado y el examen se abre el domingo, a la hora, igual para todos.
typedef ParticipacionNacional = ({bool inscrito, StudySession? sesion});

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

  /// Sesiones a medio hacer, para la tarjeta «Continuar» del inicio (RF-15).
  ///
  /// Siempre una lista, nunca nula.
  Future<List<OpenSession>> openSessions();

  /// Preguntas marcadas para repasar, de TODAS las sesiones (RF-14).
  ///
  /// Llegan reveladas —con clave y explicación—: repasar es justamente ver la
  /// respuesta, y aquí no hay examen en curso que proteger. La reserva de RN-09
  /// aplica dentro del simulacro.
  Future<List<Question>> markedQuestions();

  /// Simulacros nacionales programados (RF-19).
  Future<List<NationalMock>> nationalMocks();

  /// Entra a un simulacro nacional y devuelve la sesión ya creada.
  ///
  /// Devuelve **dos cosas** porque son dos situaciones distintas: antes de la
  /// hora se aparta sitio —`sesion` en nulo— y a la hora se entra a rendir. El
  /// servidor solo sabía lo segundo, así que el botón fallaba toda la semana
  /// con «el simulacro no está abierto».
  Future<ParticipacionNacional> joinNationalMock(String mockId);

  /// Exámenes ENAM de años anteriores (RF-52).
  ///
  /// Llegan ordenados del más reciente al más antiguo, que es el orden en que
  /// le sirven al estudiante.
  Future<List<PastExam>> pastExams();

  /// Arranca un examen pasado. El servidor devuelve sus preguntas reales, no
  /// una selección generada con el blueprint.
  ///
  /// [cantidad] solo cuenta en modo estudio: en los de examen la fija el
  /// propio examen.
  Future<StudySession> startPastExam(
    String examId, {
    required PastExamMode modo,
    int? cantidad,
  });
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

  @override
  Future<List<OpenSession>> openSessions() async {
    final data = await _client.get<List<dynamic>>(ApiEndpoints.openSessions);
    return data
        .map((e) => OpenSession.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<List<Question>> markedQuestions() async {
    final data = await _client.get<List<dynamic>>(ApiEndpoints.markedQuestions);
    return data
        .map((e) => Question.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<List<NationalMock>> nationalMocks() async {
    final data = await _client.get<List<dynamic>>(ApiEndpoints.mockExams);
    return data
        .map((e) => NationalMock.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<ParticipacionNacional> joinNationalMock(String mockId) async {
    final data = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.joinMockExam(mockId),
    );

    final sesion = data['sesion'];
    return (
      inscrito: data['inscrito'] == true,
      sesion: sesion is Map<String, dynamic>
          ? StudySession.fromJson(sesion)
          : null,
    );
  }

  @override
  Future<List<PastExam>> pastExams() async {
    final data = await _client.get<List<dynamic>>(ApiEndpoints.pastExams);
    return data
        .map((e) => PastExam.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<StudySession> startPastExam(
    String examId, {
    required PastExamMode modo,
    int? cantidad,
  }) async {
    // Van los dos campos, y no sobra ninguno.
    //
    // `modo` es el actual y el único que distingue los tres. `muestra` es el
    // anterior, de cuando solo había dos, y se manda porque un servidor que
    // todavía no conozca `modo` ignoraría esa clave en silencio: pedirías el
    // corto y te devolvería el examen entero sin que nada avisara. Ya pasó una
    // vez, al revés, con `modo` contra un servidor que solo leía `muestra`.
    final data = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.startPastExam(examId),
      data: {'modo': modo.name, 'muestra': modo.esCorto, 'cantidad': ?cantidad},
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
  ///
  /// [ocultarClasificacion] separa los dos modos del servidor: en un simulacro
  /// tampoco se dice de qué área es la pregunta (RN-09), pero en práctica sí,
  /// porque el estudiante eligió el tema. Lo que en práctica se oculta hasta
  /// responder es solo la clave y las explicaciones (RF-13).
  List<Question> _registrarClaves(
    String sessionId,
    List<Question> preguntas, {
    required bool revelarClaves,
    bool ocultarClasificacion = true,
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

    // Quitar la clave y las explicaciones antes de entregar al cliente
    // (RF-16). La clasificación se quita solo en simulacro (RN-09): en el
    // examen real tampoco se ve de qué área es la pregunta y saberlo acota las
    // alternativas.
    return preguntas
        .map(
          (q) => q.copyWith(
            explicacion: null,
            areaId: ocultarClasificacion ? null : q.areaId,
            subtemaId: ocultarClasificacion ? null : q.subtemaId,
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
          // Los subtemas acotan más que el área, así que mandan cuando vienen.
          // El servidor resuelve el subárbol; aquí basta con no ignorarlos.
          areaIds: config.subtemaIds.isNotEmpty
              ? config.subtemaIds
              : config.areaIds,
          conRespuestas: true,
        ),
        // Tampoco en práctica: el servidor revela cada pregunta AL
        // RESPONDERLA, no al crear la sesión (RF-13). Con las claves puestas
        // desde el principio, el mock mentía sobre el contrato y ocultaba que
        // la app no releía la sesión tras responder.
        revelarClaves: false,
        // Pero el área y el tema sí viajan: el estudiante los eligió.
        ocultarClasificacion: false,
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

  /// Id de la sesión a medias que el Home ofrece retomar (RF-15).
  ///
  /// Se genera la primera vez que se pide, no al arrancar: así el Home puede
  /// enseñar la tarjeta "Continuar donde quedaste" y el botón lleva a una
  /// sesión que existe de verdad. Sin esto, "Seguir" abría una sesión
  /// inexistente y la pantalla moría en "no pudimos cargar la sesión".
  static const idSesionPendiente = 'mock-sesion';

  /// Preguntas ya respondidas en la sesión pendiente, para que el detalle del
  /// Home ("pregunta 7 de 20") cuadre con lo que se abre.
  static const _respondidasPendiente = 6;

  @override
  Future<StudySession> session(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));

    final session =
        _sessions[id] ??
        (id == idSesionPendiente ? _crearSesionPendiente() : null);

    if (session == null) throw const NotFoundFailure('Sesión no encontrada.');
    return _conRevelado(session);
  }

  /// Devuelve la sesión revelando las preguntas que ya se respondieron.
  ///
  /// Reproduce lo que hace el servidor: en práctica cada pregunta enseña su
  /// clave y sus cuatro explicaciones AL RESPONDERLA (RF-13); en simulacro, no
  /// hasta cerrar (RF-16). Sin esto el mock revelaba de más y la app parecía
  /// funcionar contra datos falsos mientras fallaba contra el backend real.
  StudySession _conRevelado(StudySession session) {
    final originales = _originales[session.id];
    if (originales == null) return session;

    final cerrada = session.estado != SessionStatus.enCurso;
    if (!session.muestraFeedbackInmediato && !cerrada) return session;

    final porID = {for (final q in originales) q.id: q};

    return session.copyWith(
      preguntas: session.preguntas
          .map((q) {
            final respuesta = session.respuestas[q.id];
            final respondida = respuesta != null && respuesta.optionId != null;
            if (!cerrada && !respondida) return q;
            return porID[q.id] ?? q;
          })
          .toList(growable: false),
    );
  }

  StudySession _crearSesionPendiente() {
    const id = idSesionPendiente;
    final preguntas = _registrarClaves(
      id,
      MockData.questions(cantidad: 20, conRespuestas: true),
      revelarClaves: true,
    );

    // Las respuestas se atan a los ids reales de las preguntas generadas: con
    // ids inventados la sesión abriría en la primera y el "7 de 20" mentiría.
    final claves = _claves[id] ?? const <String, String>{};
    final respuestas = <String, Answer>{
      for (var i = 0; i < _respondidasPendiente; i++)
        preguntas[i].id: Answer(
          questionId: preguntas[i].id,
          optionId: claves[preguntas[i].id],
          esCorrecta: i.isEven,
          tiempoMs: 30000,
        ),
    };

    final session = StudySession(
      id: id,
      tipo: SessionType.practica,
      estado: SessionStatus.enCurso,
      iniciadaEn: DateTime.now().subtract(const Duration(hours: 3)),
      preguntas: preguntas,
      respuestas: respuestas,
    );
    return _sessions[id] = session;
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

  @override
  Future<List<OpenSession>> openSessions() async {
    await Future<void>.delayed(_delay);

    // Salen de las sesiones que este mock creó de verdad, no de una lista
    // inventada: así "continuar" lleva a algo que existe y se puede reanudar.
    return [
      for (final s in _sessions.values)
        if (s.estado == SessionStatus.enCurso)
          OpenSession(
            id: s.id,
            tipo: s.tipo,
            iniciadaEn: s.iniciadaEn,
            expiraEn: s.expiraEn,
            respondidas: s.respondidas,
            totalPreguntas: s.totalPreguntas,
          ),
    ]..sort((a, b) => b.iniciadaEn.compareTo(a.iniciadaEn));
  }

  @override
  Future<List<Question>> markedQuestions() async {
    await Future<void>.delayed(_delay);

    // Vale la marca MÁS RECIENTE: si se marcó en un simulacro y se desmarcó al
    // repasarla, ya no aparece. Es lo que hace el servidor, y hacerlo distinto
    // aquí dejaría la pantalla comportándose de dos maneras según el modo.
    final marcadas = <String, Question>{};

    for (final sesion in _sessions.values) {
      final originales = _originales[sesion.id] ?? sesion.preguntas;
      final claves = _claves[sesion.id] ?? const <String, String>{};

      for (final pregunta in originales) {
        final respuesta = sesion.respuestas[pregunta.id];
        if (respuesta == null) continue;

        if (!respuesta.marcada) {
          marcadas.remove(pregunta.id);
          continue;
        }

        // Reveladas: repasar es ver la respuesta (RF-14). Aquí no hay examen
        // en curso que proteger.
        final claveId = claves[pregunta.id];
        marcadas[pregunta.id] = pregunta.copyWith(
          explicacion:
              'Explicación de la clave. Texto de relleno, no es información '
              'clínica válida.',
          opciones: pregunta.opciones
              .map((o) => o.copyWith(esCorrecta: o.id == claveId))
              .toList(),
        );
      }
    }

    return marcadas.values.toList(growable: false);
  }

  /// A quién apuntó el usuario, en memoria del proceso.
  ///
  /// Contra el backend real esto lo sabe el servidor y llega en `inscrito`. En
  /// el mock hace falta un sitio donde recordarlo, pero **no** SharedPreferences:
  /// guardarlo en disco fue lo que hizo que la inscripción sobreviviera al
  /// cierre de sesión y que cambiar de teléfono la perdiera.
  final Set<String> _inscritos = {};

  @override
  Future<List<NationalMock>> nationalMocks() async {
    await Future<void>.delayed(_delay);

    final ahora = DateTime.now();
    final inicio = ahora.add(const Duration(days: 6, hours: 3));

    return [
      NationalMock(
        id: 'nac-2026-08',
        nombre: 'Simulacro Nacional · Agosto',
        inicio: inicio,
        fin: inicio.add(const Duration(hours: 3)),
        duracionMinutos: 180,
        participantes: 1847,
        inscrito: _inscritos.contains('nac-2026-08'),
        estado: NationalMockStatus.programado,
        totalPreguntas: 180,
      ),
    ];
  }

  @override
  Future<ParticipacionNacional> joinNationalMock(String mockId) async {
    _inscritos.add(mockId);
    // Apartar sitio, que es lo que pasa mientras el simulacro no ha empezado.
    return (inscrito: true, sesion: null);
  }

  /// Los exámenes ENAM que ya se rindieron, del más reciente al más antiguo.
  ///
  /// Es la lista real del banco, con la forma exacta que devuelve
  /// `GET /past-exams`: año y convocatoria, no una fecha completa —el servidor
  /// no guarda el día— e `intentos` en vez de un booleano, porque un examen
  /// pasado se puede rendir las veces que uno quiera.
  static final _examenesPasados = <PastExam>[
    _pasado('examen_enam_05.07.2026', 'ENAM 2026', 2026, 'I'),
    _pasado('examen_enam_26.04.2026', 'ENAM extraordinario 2026', 2026, ''),
    _pasado('examen_enam_07.12.2025', 'ENAM 2025', 2025, 'II'),
    _pasado('examen_enam_12.10.2025', 'ENAM octubre 2025', 2025, ''),
    _pasado(
      'examen_enam_12.10.2025_preinternos',
      'ENAM octubre 2025 Preinternos',
      2025,
      '',
    ),
    _pasado('examen_enam_30.03.2025', 'ENAM 2025', 2025, 'I'),
    _pasado('examen_enam_17112024', 'ENAM 2024', 2024, 'II'),
    _pasado('examen_enam_14.07.2024', 'ENAM julio 2024', 2024, ''),
    _pasado('examen_enam_17.03.2024', 'ENAM 2024', 2024, 'I'),
    _pasado('examen_enam_03122023', 'ENAM 2023', 2023, 'II'),
    _pasado('examen_enam_29082021-2', 'ENAM agosto 2021', 2021, ''),
    _pasado('examen_enam05062021', 'ENAM junio 2021', 2021, ''),
    _pasado('examen_enam25042021', 'ENAM abril 2021', 2021, ''),
    _pasado('examen_enam_e2020', 'ENAM 2020', 2020, ''),
  ];

  /// Un examen del banco, con los 180 y las 3 h del examen real.
  static PastExam _pasado(
    String id,
    String nombre,
    int anio,
    String convocatoria,
  ) => PastExam(
    id: id,
    nombre: nombre,
    anio: anio,
    convocatoria: convocatoria,
    duracionMinutos: Blueprint.examDuration.inMinutes,
    totalPreguntas: Blueprint.totalQuestions,
  );

  @override
  Future<List<PastExam>> pastExams() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return _examenesPasados;
  }

  @override
  Future<StudySession> startPastExam(
    String examId, {
    required PastExamMode modo,
    int? cantidad,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));

    final examen = _examenesPasados.firstWhere(
      (e) => e.id == examId,
      orElse: () => throw const NotFoundFailure('Ese examen no existe.'),
    );

    final total = switch (modo) {
      PastExamMode.corto => Blueprint.sampleExamQuestions,
      // Estudiando manda lo que pidió el estudiante, acotado al examen.
      PastExamMode.practica => (cantidad ?? examen.totalPreguntas).clamp(
        Blueprint.practiceMinQuestions,
        examen.totalPreguntas,
      ),
      PastExamMode.completo => examen.totalPreguntas,
    };
    final id = 'examen-${++_counter}';

    // Estudiar crea una sesión de PRÁCTICA, no de examen: es lo que hace el
    // servidor, y así hereda el feedback inmediato y el no tener reloj sin
    // exceptuar el comportamiento en cada pantalla.
    final esExamen = modo.esExamen;

    final session = StudySession(
      id: id,
      // `examenPasado` y no `simulacro`: es lo que manda el servidor, y de ahí
      // sale a qué pantalla se vuelve al salir —al inicio, que es de donde se
      // entró, y no a la pestaña de simulacros—.
      tipo: esExamen ? SessionType.examenPasado : SessionType.practica,
      estado: SessionStatus.enCurso,
      iniciadaEn: DateTime.now(),
      expiraEn: esExamen ? DateTime.now().add(duracionDe(modo)) : null,
      preguntas: _registrarClaves(
        id,
        MockData.questions(cantidad: total, conRespuestas: true),
        revelarClaves: false,
        // En práctica el área y el tema sí viajan: no hay examen que proteger.
        ocultarClasificacion: esExamen,
      ),
    );
    return _sessions[id] = session;
  }
}
