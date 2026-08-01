import 'package:freezed_annotation/freezed_annotation.dart';

part 'session_models.freezed.dart';
part 'session_models.g.dart';

/// Tipo de sesión (tabla `sessions` del SSD §5).
@JsonEnum(fieldRename: FieldRename.snake)
enum SessionType {
  /// Práctica libre: feedback inmediato, sin límite de tiempo (RF-12/13).
  practica,

  /// Simulacro individual: 180 preguntas, 3 h, sin feedback (RF-16).
  simulacro,

  /// Simulacro nacional: simultáneo, con ranking, requiere conexión (RF-19/33).
  simulacroNacional,
}

@JsonEnum(fieldRename: FieldRename.snake)
enum SessionStatus { enCurso, finalizada, expirada }

/// Origen de las preguntas de una práctica (RF-12).
@JsonEnum(fieldRename: FieldRename.snake)
enum QuestionSource {
  todas('Todas'),
  noVistas('Solo no vistas'),
  falladas('Solo falladas');

  const QuestionSource(this.label);
  final String label;
}

/// Tipo de enunciado. El 90 % del ENAM son casos clínicos.
@JsonEnum(fieldRename: FieldRename.snake)
enum QuestionType { casoClinico, directa }

@freezed
abstract class QuestionOption with _$QuestionOption {
  const factory QuestionOption({
    required String id,
    required String texto,

    /// Solo llega tras responder (práctica) o al finalizar (simulacro).
    /// El servidor NUNCA debe mandarlo antes: sería regalar la respuesta.
    bool? esCorrecta,

    /// Explicación del distractor (RF-07). Opcional.
    String? explicacion,
  }) = _QuestionOption;

  factory QuestionOption.fromJson(Map<String, dynamic> json) =>
      _$QuestionOptionFromJson(json);
}

@freezed
abstract class Question with _$Question {
  const factory Question({
    required String id,
    required String enunciado,
    required List<QuestionOption> opciones,

    /// Clasificación de la pregunta.
    ///
    /// **Van en `null` durante un simulacro en curso (RN-09):** en el examen
    /// real el postulante no ve de qué área es la pregunta, y saberlo daría una
    /// pista. Se revelan recién al cerrar la sesión.
    String? areaId,
    String? subtemaId,
    @Default(QuestionType.casoClinico) QuestionType tipo,

    /// Dificultad de 1 a 3 (RF-07).
    @Default(2) int dificultad,

    /// Año o edición del ENAM de la que proviene. `null` si es de autoría propia.
    int? origenAnio,

    /// Imágenes: radiografías, EKG, tablas (RF-10).
    @Default([]) List<String> imagenes,

    /// Explicación de la clave. Llega tras responder.
    String? explicacion,

    /// % de acierto global de esta pregunta (RF-13). Se muestra al dar feedback.
    double? porcentajeAciertoGlobal,
  }) = _Question;

  factory Question.fromJson(Map<String, dynamic> json) =>
      _$QuestionFromJson(json);
}

/// Respuesta del usuario a una pregunta.
@freezed
abstract class Answer with _$Answer {
  const factory Answer({
    required String questionId,

    /// `null` = dejada en blanco. Sin puntaje en contra, vale igual que fallar
    /// (RN-01), pero se distingue para las estadísticas.
    String? optionId,
    bool? esCorrecta,

    /// Tiempo empleado. Se usa para desempatar en simulacros nacionales (RN-05).
    @Default(0) int tiempoMs,

    /// Marcada para revisar después (RF-14, RF-17).
    @Default(false) bool marcada,

    /// Respondida sin conexión y pendiente de sincronizar (RF-31/32).
    @Default(false) bool respondidaOffline,
  }) = _Answer;

  factory Answer.fromJson(Map<String, dynamic> json) => _$AnswerFromJson(json);
}

/// Configuración de una sesión de práctica (RF-12).
@freezed
abstract class PracticeConfig with _$PracticeConfig {
  const factory PracticeConfig({
    @Default([]) List<String> areaIds,
    @Default([]) List<String> subtemaIds,
    @Default(20) int cantidadPreguntas,
    @Default(QuestionSource.todas) QuestionSource origen,
  }) = _PracticeConfig;

  factory PracticeConfig.fromJson(Map<String, dynamic> json) =>
      _$PracticeConfigFromJson(json);
}

/// Resumen de una sesión a medio hacer, para la tarjeta «Continuar» (RF-15).
///
/// No lleva las preguntas: son hasta 180 y la tarjeta solo necesita saber qué
/// sesión es y por dónde iba. Cargarlas todas para pintar una tarjeta en el
/// arranque sería gastar el peor momento de la conexión del usuario.
@freezed
abstract class OpenSession with _$OpenSession {
  const factory OpenSession({
    required String id,
    required SessionType tipo,
    required DateTime iniciadaEn,
    DateTime? expiraEn,
    @Default(0) int respondidas,
    @Default(0) int totalPreguntas,
  }) = _OpenSession;

  const OpenSession._();

  factory OpenSession.fromJson(Map<String, dynamic> json) =>
      _$OpenSessionFromJson(json);

  bool get esSimulacro =>
      tipo == SessionType.simulacro || tipo == SessionType.simulacroNacional;
}

/// Estado de un simulacro nacional respecto del reloj (RF-19).
@JsonEnum(fieldRename: FieldRename.snake)
enum NationalMockStatus { programado, enCurso, cerrado }

/// Un simulacro nacional programado.
///
/// Todo lo que decide qué se ve viene del **servidor**, incluido [inscrito] y
/// [estado]. Los dos se calculaban en el cliente: la inscripción vivía en
/// SharedPreferences —así que cambiar de teléfono la perdía y se podía
/// "participar" dos veces— y el momento salía del reloj del dispositivo, que
/// si va adelantado enseña "en curso" para algo que el servidor va a rechazar.
@freezed
abstract class NationalMock with _$NationalMock {
  const factory NationalMock({
    required String id,
    required String nombre,
    required DateTime inicio,
    required DateTime fin,
    @Default(0) int duracionMinutos,
    @Default(0) int participantes,
    @Default(false) bool inscrito,
    @Default(NationalMockStatus.programado) NationalMockStatus estado,
    @Default(0) int totalPreguntas,
  }) = _NationalMock;

  const NationalMock._();

  factory NationalMock.fromJson(Map<String, dynamic> json) =>
      _$NationalMockFromJson(json);

  Duration get duracion => Duration(minutes: duracionMinutos);

  /// Cuánto falta para que abra. `null` si ya abrió.
  Duration? get faltaParaEmpezar {
    if (estado != NationalMockStatus.programado) return null;
    final falta = inicio.difference(DateTime.now());
    return falta.isNegative ? Duration.zero : falta;
  }
}

/// Una sesión de estudio en curso o terminada.
@freezed
abstract class StudySession with _$StudySession {
  const factory StudySession({
    required String id,
    required SessionType tipo,
    required SessionStatus estado,
    required DateTime iniciadaEn,
    @Default([]) List<Question> preguntas,
    @Default({}) Map<String, Answer> respuestas,
    DateTime? finalizadaEn,

    /// Cuándo se acaba el tiempo. Solo en simulacros.
    DateTime? expiraEn,

    /// Nota vigesimal. Solo cuando la sesión terminó (RN-01).
    double? nota,
  }) = _StudySession;

  const StudySession._();

  factory StudySession.fromJson(Map<String, dynamic> json) =>
      _$StudySessionFromJson(json);

  bool get esSimulacro =>
      tipo == SessionType.simulacro || tipo == SessionType.simulacroNacional;

  /// En simulacro no se muestra si acertaste hasta el final (RF-16).
  bool get muestraFeedbackInmediato => tipo == SessionType.practica;

  int get totalPreguntas => preguntas.length;

  int get respondidas =>
      respuestas.values.where((r) => r.optionId != null).length;

  int get sinResponder => totalPreguntas - respondidas;

  int get marcadas => respuestas.values.where((r) => r.marcada).length;

  int get correctas => respuestas.values.where((r) => r.esCorrecta == true).length;

  /// Tiempo restante en un simulacro. `null` si no aplica o ya terminó.
  Duration? get tiempoRestante {
    final expira = expiraEn;
    if (expira == null || estado != SessionStatus.enCurso) return null;
    final restante = expira.difference(DateTime.now());
    return restante.isNegative ? Duration.zero : restante;
  }
}

/// Un examen ENAM real de un año anterior (RF-52).
///
/// A diferencia del simulacro, que se **genera** respetando el blueprint, esto
/// es un examen que ya se rindió: las preguntas, el orden y las claves son las
/// oficiales. Por eso todo llega del servidor —hasta el nombre—: el cliente no
/// inventa ni reordena nada.
@freezed
abstract class PastExam with _$PastExam {
  const factory PastExam({
    required String id,
    required String nombre,

    /// Cuándo se rindió. Ordena la lista: lo más reciente primero, que es lo
    /// que más le sirve al estudiante.
    DateTime? fecha,
    @Default(0) int totalPreguntas,

    /// Matiz del examen cuando lo tiene, como "Preinternos". Va aparte del
    /// nombre para poder pintarlo como distintivo.
    String? etiqueta,

    /// Si el usuario ya lo rindió alguna vez. Se marca en la lista para que no
    /// repita sin querer el mismo de la semana pasada.
    @Default(false) bool resuelto,

    /// Su mejor nota, si ya lo rindió.
    double? mejorNota,
  }) = _PastExam;

  const PastExam._();

  factory PastExam.fromJson(Map<String, dynamic> json) =>
      _$PastExamFromJson(json);

  /// El año, para agrupar la lista.
  int? get anio => fecha?.year;
}

/// Cómo se rinde un examen pasado (RF-52).
///
/// Son los dos modos del simulacro, aplicados a un examen real: entero, o una
/// parte para medirse en poco tiempo.
enum PastExamMode {
  /// El examen completo, con su tiempo oficial.
  completo,

  /// Una selección corta del mismo examen.
  corto;

  bool get esCorto => this == PastExamMode.corto;
}
