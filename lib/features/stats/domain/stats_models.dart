import 'package:freezed_annotation/freezed_annotation.dart';

part 'stats_models.freezed.dart';
part 'stats_models.g.dart';

/// Desempeño del usuario en un área, contra el peso del blueprint (RF-21).
///
/// La comparación importa: acertar 90 % en Ética (2 preguntas del examen) no
/// mueve la nota; acertar 60 % en Medicina (40 preguntas) sí. La UI debe hacer
/// evidente dónde conviene invertir tiempo.
@freezed
abstract class AreaPerformance with _$AreaPerformance {
  const factory AreaPerformance({
    required String areaId,
    required String areaNombre,
    required int preguntasBlueprint,
    @Default(0) int respondidas,
    @Default(0) int correctas,
  }) = _AreaPerformance;

  const AreaPerformance._();

  factory AreaPerformance.fromJson(Map<String, dynamic> json) =>
      _$AreaPerformanceFromJson(json);

  /// `null` si no hay datos, para no mostrar 0 % como si fuera un mal resultado.
  double? get porcentajeAcierto =>
      respondidas == 0 ? null : correctas / respondidas;

  /// Cuánto aporta esta área a la nota final.
  double get pesoEnExamen => preguntasBlueprint / 180;
}

/// Punto de la evolución temporal de la nota (RF-21, RF-20).
@freezed
abstract class GradePoint with _$GradePoint {
  const factory GradePoint({
    required DateTime fecha,
    required double nota,
    String? sessionId,
  }) = _GradePoint;

  factory GradePoint.fromJson(Map<String, dynamic> json) =>
      _$GradePointFromJson(json);
}

/// Respuesta de `GET /stats/dashboard`.
@freezed
abstract class DashboardStats with _$DashboardStats {
  const factory DashboardStats({
    /// Nota proyectada (RN-04): promedio ponderado del % de acierto por área
    /// usando los pesos del blueprint, en escala vigesimal.
    ///
    /// SIEMPRE se muestra junto a la advertencia de que es una estimación.
    required double notaProyectada,
    @Default([]) List<AreaPerformance> porArea,
    @Default([]) List<GradePoint> evolucion,
    @Default(0) int preguntasVistas,
    @Default(0) int preguntasTotalesBanco,
    @Default(0) int simulacrosCompletados,

    /// Preguntas que le quedan hoy a un usuario free (RN-03). `null` si es
    /// premium (ilimitado).
    int? preguntasRestantesHoy,
  }) = _DashboardStats;

  const DashboardStats._();

  factory DashboardStats.fromJson(Map<String, dynamic> json) =>
      _$DashboardStatsFromJson(json);

  bool get esFree => preguntasRestantesHoy != null;

  bool get alcanzoLimiteDiario => (preguntasRestantesHoy ?? 1) <= 0;

  double get coberturaBanco =>
      preguntasTotalesBanco == 0 ? 0 : preguntasVistas / preguntasTotalesBanco;
}

/// Fila del ranking (RF-22).
@freezed
abstract class RankingEntry with _$RankingEntry {
  const factory RankingEntry({
    required int posicion,
    required String usuarioNombre,
    required double promedio,
    String? universidad,

    /// Si esta fila es la del usuario que está mirando.
    @Default(false) bool esUsuarioActual,

    /// Tiempo total, para el desempate de simulacros nacionales (RN-05).
    int? tiempoTotalMs,
  }) = _RankingEntry;

  factory RankingEntry.fromJson(Map<String, dynamic> json) =>
      _$RankingEntryFromJson(json);
}
