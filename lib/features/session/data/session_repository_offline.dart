import 'dart:async';

import '../../../core/error/failure.dart';
import '../../../core/network/conectividad.dart';
import '../../offline/data/servicio_offline.dart';
import '../domain/session_models.dart';
import 'session_repository.dart';

/// El repositorio de sesiones, con red o sin ella (RF-31).
///
/// Envuelve al que habla con la API y se queda en medio para que **ninguna
/// pantalla tenga que preguntar si hay internet**. La práctica se pide igual,
/// se responde igual y se termina igual; lo que cambia es de dónde salen los
/// datos.
///
/// **Qué decide que se trabaje sin conexión.** No el indicador del sistema, que
/// solo sabe si hay una interfaz de red y da por buena la wifi de un café que
/// pide contraseña en el navegador. Manda **el fallo real de la petición**: si
/// el servidor no contesta, se pasa a lo local. El indicador se usa antes, para
/// ahorrarse la espera cuando es evidente que no hay nada.
///
/// **Qué NO cae aquí.** Los simulacros —nacionales o no— siguen necesitando
/// conexión: RF-33 lo exige para el nacional, y para el resto hacer un examen
/// con reloj a medias entre el teléfono y el servidor es pedir problemas. Solo
/// la práctica libre funciona sin señal, que es justo lo que RF-31 pide.
class SessionRepositoryConRespaldo implements SessionRepository {
  SessionRepositoryConRespaldo({
    required SessionRepository remoto,
    required ServicioOffline offline,
    required Conectividad red,
  }) : _remoto = remoto,
       _offline = offline,
       _red = red;

  final SessionRepository _remoto;
  final ServicioOffline _offline;
  final Conectividad _red;

  /// Si el fallo es «no llegamos al servidor» y no «el servidor dijo que no».
  ///
  /// La diferencia importa: un 403 o un 422 se responden igual sin conexión que
  /// con ella, y tratarlos como falta de red escondería el motivo real.
  static bool esFalloDeRed(Object error) =>
      error is NetworkFailure || error is TimeoutFailure;

  @override
  Future<StudySession> startPractice(PracticeConfig config) async {
    if (!await _red.hayRed()) return _practicarSinSenal(config);

    try {
      return await _remoto.startPractice(config);
    } on Failure catch (e) {
      if (!esFalloDeRed(e)) rethrow;
      return _practicarSinSenal(config);
    }
  }

  /// Practicar sin señal, con lo que hay en el teléfono.
  ///
  /// Primero se gasta una reserva si quedaba alguna: son sesiones que el
  /// servidor ya creó y usarlas no cuesta nada. Cuando no queda ninguna —que
  /// es el caso normal— la práctica se arma en el teléfono con el banco
  /// descargado, sin tope.
  ///
  /// Eso último es el cambio de fondo: antes esta rama solo sabía gastar
  /// reservas, así que se podía practicar exactamente una vez por área
  /// descargada y después la app decía «no tienes prácticas listas» teniendo
  /// las 480 preguntas del área guardadas en el teléfono.
  Future<StudySession> _practicarSinSenal(PracticeConfig config) async {
    try {
      return await _offline.tomarReserva(areasPreferidas: config.areaIds);
    } on SinDescargasFailure {
      return _offline.practicarConLoDescargado(
        areasPreferidas: config.areaIds,
        subtemasPreferidos: config.subtemaIds,
        cantidad: config.cantidadPreguntas,
      );
    }
  }

  @override
  Future<StudySession> session(String id) async {
    // La copia local manda cuando tiene respuestas que el servidor todavía no
    // conoce: pedirla al servidor devolvería la práctica sin lo respondido en
    // el bus, y en pantalla se vería como progreso perdido.
    final local = await _offline.sesionLocal(id);
    if (local != null && await _tienePendientes(id)) return local.sesion;

    if (!await _red.hayRed() && local != null) return local.sesion;

    try {
      return await _remoto.session(id);
    } on Failure catch (e) {
      if (!esFalloDeRed(e) || local == null) rethrow;
      return local.sesion;
    }
  }

  @override
  Future<Answer> answer({
    required String sessionId,
    required String questionId,
    String? optionId,
    required int tiempoMs,
    bool marcada = false,
  }) async {
    final local = await _offline.sesionLocal(sessionId);

    if (local != null && !await _red.hayRed()) {
      return _offline.responderSinConexion(
        local,
        preguntaId: questionId,
        opcionId: optionId,
        tiempoMs: tiempoMs,
        marcada: marcada,
      );
    }

    try {
      return await _remoto.answer(
        sessionId: sessionId,
        questionId: questionId,
        optionId: optionId,
        tiempoMs: tiempoMs,
        marcada: marcada,
      );
    } on Failure catch (e) {
      if (!esFalloDeRed(e) || local == null) rethrow;
      return _offline.responderSinConexion(
        local,
        preguntaId: questionId,
        opcionId: optionId,
        tiempoMs: tiempoMs,
        marcada: marcada,
      );
    }
  }

  @override
  Future<StudySession> submit(String sessionId) async {
    final local = await _offline.sesionLocal(sessionId);

    if (local != null && !await _red.hayRed()) {
      return _offline.terminarSinConexion(local);
    }

    try {
      return await _remoto.submit(sessionId);
    } on Failure catch (e) {
      if (!esFalloDeRed(e) || local == null) rethrow;
      return _offline.terminarSinConexion(local);
    }
  }

  @override
  Future<List<OpenSession>> openSessions() async {
    final reservadas = await _offline.idsDeReservasSinEmpezar();

    try {
      final abiertas = await _remoto.openSessions();
      // Una reserva que nadie abrió no es una sesión a medias: existe en el
      // servidor porque hubo que crearla con antelación, pero para el
      // estudiante todavía no empezó.
      return abiertas.where((s) => !reservadas.contains(s.id)).toList();
    } on Failure catch (e) {
      if (!esFalloDeRed(e)) rethrow;
      return _abiertasLocales();
    }
  }

  /// Lo que quedó a medias en el teléfono, para que el inicio pueda ofrecerlo
  /// aunque no haya señal.
  Future<List<OpenSession>> _abiertasLocales() async {
    final locales = await _offline.sesionesEnCurso();

    return [
      for (final local in locales)
        OpenSession(
          id: local.sesion.id,
          tipo: local.sesion.tipo,
          iniciadaEn: local.sesion.iniciadaEn,
          expiraEn: local.sesion.expiraEn,
          respondidas: local.sesion.respondidas,
          totalPreguntas: local.sesion.totalPreguntas,
        ),
    ];
  }

  Future<bool> _tienePendientes(String sesionId) async {
    final pendientes = await _offline.pendientesDe(sesionId);
    return pendientes > 0;
  }

  // ---- Lo que no funciona sin conexión, y no debe fingir que sí ----

  @override
  Future<StudySession> startSimulacro({bool esMuestra = false}) =>
      _remoto.startSimulacro(esMuestra: esMuestra);

  @override
  Future<List<Question>> markedQuestions() => _remoto.markedQuestions();

  @override
  Future<List<NationalMock>> nationalMocks() => _remoto.nationalMocks();

  @override
  Future<StudySession> joinNationalMock(String mockId) =>
      _remoto.joinNationalMock(mockId);

  @override
  Future<List<PastExam>> pastExams() => _remoto.pastExams();

  @override
  Future<StudySession> startPastExam(
    String examId, {
    required PastExamMode modo,
    int? cantidad,
  }) => _remoto.startPastExam(examId, modo: modo, cantidad: cantidad);
}
