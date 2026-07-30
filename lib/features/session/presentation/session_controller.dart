import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/providers.dart';
import '../domain/session_models.dart';

/// Estado de una sesión en curso, sea práctica o simulacro.
class SessionState {
  const SessionState({
    required this.session,
    this.indice = 0,
    this.seleccion,
    this.respondida = false,
    this.enviando = false,
    this.error,
  });

  final StudySession session;

  /// Pregunta que se está mostrando.
  final int indice;

  /// Alternativa marcada pero **no** confirmada todavía.
  ///
  /// Seleccionar no responde: hace falta confirmar. Leyendo un caso clínico
  /// largo es fácil tocar de más, y en un examen eso no se puede deshacer.
  final String? seleccion;

  /// Si la pregunta actual ya se envió. En práctica dispara la
  /// retroalimentación; en simulacro solo marca avance.
  final bool respondida;

  final bool enviando;
  final Failure? error;

  Question get pregunta => session.preguntas[indice];

  Answer? get respuesta => session.respuestas[pregunta.id];

  bool get esUltima => indice >= session.preguntas.length - 1;

  bool get marcada => respuesta?.marcada ?? false;

  double get progreso => session.preguntas.isEmpty
      ? 0
      : (indice + 1) / session.preguntas.length;

  SessionState copyWith({
    StudySession? session,
    int? indice,
    String? seleccion,
    bool limpiarSeleccion = false,
    bool? respondida,
    bool? enviando,
    Failure? error,
    bool limpiarError = false,
  }) => SessionState(
    session: session ?? this.session,
    indice: indice ?? this.indice,
    seleccion: limpiarSeleccion ? null : (seleccion ?? this.seleccion),
    respondida: respondida ?? this.respondida,
    enviando: enviando ?? this.enviando,
    error: limpiarError ? null : (error ?? this.error),
  );
}

/// Conduce una sesión: seleccionar, responder, avanzar, marcar y cerrar.
class SessionController extends AsyncNotifier<SessionState> {
  SessionController(this.sessionId);

  final String sessionId;

  /// Momento en que se mostró la pregunta actual, para medir el tiempo por
  /// pregunta. Se usa en el desempate del ranking nacional (RN-05).
  DateTime _mostradaEn = DateTime.now();

  @override
  Future<SessionState> build() async {
    final session = await ref
        .read(sessionRepositoryProvider)
        .session(sessionId);

    // Se reanuda en la primera sin responder (RF-15): retomar desde el inicio
    // obligaría a pasar de nuevo por todo lo ya hecho.
    final indice = _primeraSinResponder(session);
    _mostradaEn = DateTime.now();

    return SessionState(session: session, indice: indice);
  }

  static int _primeraSinResponder(StudySession session) {
    for (var i = 0; i < session.preguntas.length; i++) {
      if (session.respuestas[session.preguntas[i].id]?.optionId == null) {
        return i;
      }
    }
    return session.preguntas.isEmpty ? 0 : session.preguntas.length - 1;
  }

  SessionState? get _actual => state.value;

  void seleccionar(String optionId) {
    final s = _actual;
    if (s == null || s.respondida) return;
    state = AsyncData(s.copyWith(seleccion: optionId, limpiarError: true));
  }

  /// Confirma la respuesta seleccionada.
  Future<void> responder() async {
    final s = _actual;
    if (s == null || s.seleccion == null || s.enviando || s.respondida) return;

    state = AsyncData(s.copyWith(enviando: true, limpiarError: true));

    try {
      final answer = await ref.read(sessionRepositoryProvider).answer(
        sessionId: sessionId,
        questionId: s.pregunta.id,
        optionId: s.seleccion,
        tiempoMs: DateTime.now().difference(_mostradaEn).inMilliseconds,
        marcada: s.marcada,
      );

      final actualizada = s.session.copyWith(
        respuestas: {...s.session.respuestas, s.pregunta.id: answer},
      );

      state = AsyncData(
        s.copyWith(
          session: actualizada,
          enviando: false,
          // En práctica esto abre la retroalimentación; en simulacro solo deja
          // registrada la respuesta y se puede seguir navegando.
          respondida: s.session.muestraFeedbackInmediato,
        ),
      );

      // En simulacro no hay pausa para leer: se avanza solo.
      if (!s.session.muestraFeedbackInmediato && !s.esUltima) siguiente();
    } on Failure catch (e) {
      state = AsyncData(s.copyWith(enviando: false, error: e));
    }
  }

  /// Deja la pregunta en blanco y avanza. Sin puntaje en contra, en blanco e
  /// incorrecta valen igual (RN-01), pero se distinguen en las estadísticas.
  Future<void> dejarEnBlanco() async {
    final s = _actual;
    if (s == null || s.enviando) return;

    try {
      final answer = await ref.read(sessionRepositoryProvider).answer(
        sessionId: sessionId,
        questionId: s.pregunta.id,
        tiempoMs: DateTime.now().difference(_mostradaEn).inMilliseconds,
        marcada: s.marcada,
      );
      final actualizada = s.session.copyWith(
        respuestas: {...s.session.respuestas, s.pregunta.id: answer},
      );
      state = AsyncData(s.copyWith(session: actualizada));
      if (!s.esUltima) siguiente();
    } on Failure catch (e) {
      state = AsyncData(s.copyWith(error: e));
    }
  }

  void siguiente() {
    final s = _actual;
    if (s == null || s.esUltima) return;
    _mostradaEn = DateTime.now();
    state = AsyncData(
      s.copyWith(
        indice: s.indice + 1,
        respondida: false,
        limpiarSeleccion: true,
        limpiarError: true,
      ),
    );
  }

  void anterior() {
    final s = _actual;
    if (s == null || s.indice == 0) return;
    _mostradaEn = DateTime.now();
    state = AsyncData(
      s.copyWith(
        indice: s.indice - 1,
        respondida: false,
        limpiarSeleccion: true,
      ),
    );
  }

  void irA(int indice) {
    final s = _actual;
    if (s == null || indice < 0 || indice >= s.session.preguntas.length) return;
    _mostradaEn = DateTime.now();
    state = AsyncData(
      s.copyWith(
        indice: indice,
        respondida: false,
        limpiarSeleccion: true,
      ),
    );
  }

  /// Marca o desmarca la pregunta para repaso (RF-14, RF-17).
  Future<void> alternarMarca() async {
    final s = _actual;
    if (s == null) return;

    final nueva = !s.marcada;

    // Optimista: marcar debe sentirse instantáneo. Si el servidor falla, se
    // revierte y se avisa.
    final previa = s.respuesta ?? Answer(questionId: s.pregunta.id);
    state = AsyncData(
      s.copyWith(
        session: s.session.copyWith(
          respuestas: {
            ...s.session.respuestas,
            s.pregunta.id: previa.copyWith(marcada: nueva),
          },
        ),
      ),
    );

    try {
      await ref.read(sessionRepositoryProvider).answer(
        sessionId: sessionId,
        questionId: s.pregunta.id,
        optionId: previa.optionId,
        tiempoMs: previa.tiempoMs,
        marcada: nueva,
      );
    } on Failure catch (e) {
      final actual = _actual;
      if (actual == null) return;
      state = AsyncData(
        actual.copyWith(
          session: actual.session.copyWith(
            respuestas: {...actual.session.respuestas, s.pregunta.id: previa},
          ),
          error: e,
        ),
      );
    }
  }

  /// Cierra la sesión y devuelve la corregida (RF-18, RN-01).
  Future<StudySession?> enviar() async {
    final s = _actual;
    if (s == null || s.enviando) return null;

    state = AsyncData(s.copyWith(enviando: true, limpiarError: true));
    try {
      final finalizada = await ref
          .read(sessionRepositoryProvider)
          .submit(sessionId);
      state = AsyncData(s.copyWith(session: finalizada, enviando: false));

      // El progreso del temario y las estadísticas cambiaron.
      ref
        ..invalidate(catalogProvider)
        ..invalidate(dashboardProvider);

      return finalizada;
    } on Failure catch (e) {
      state = AsyncData(s.copyWith(enviando: false, error: e));
      return null;
    }
  }
}

final sessionControllerProvider =
    AsyncNotifierProvider.family<SessionController, SessionState, String>(
      SessionController.new,
    );
