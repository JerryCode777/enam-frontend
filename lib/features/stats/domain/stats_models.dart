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
///
/// Solo entran simulacros: mezclar una práctica de 20 preguntas con uno de 180
/// hace que la línea suba y baje por el tamaño de la sesión y no por lo que el
/// estudiante sabe.
@freezed
abstract class GradePoint with _$GradePoint {
  const factory GradePoint({
    required DateTime fecha,
    required double nota,
    String? sessionId,

    /// `simulacro` o `simulacro_nacional`, y cuántas preguntas tenía.
    ///
    /// Sin esto el gráfico compara notas sacadas sobre bases distintas: un 14
    /// en la muestra de 40 y un 14 en el completo de 180 no valen lo mismo, y
    /// dibujarlos en la misma línea sin distinguirlos engaña.
    ///
    /// Con `totalPreguntas` bastaría; `tipo` evita que el cliente lo deduzca de
    /// un número, que es una regla escondida esperando a romperse.
    String? tipo,
    int? totalPreguntas,
  }) = _GradePoint;

  const GradePoint._();

  factory GradePoint.fromJson(Map<String, dynamic> json) =>
      _$GradePointFromJson(json);

  /// Si el punto viene de un simulacro completo de 180 (RN-05).
  ///
  /// `null` cuando el servidor no mandó el dato, que es distinto de `false`: no
  /// se sabe, así que la interfaz no debe afirmar ninguna de las dos cosas.
  bool? get esCompleto =>
      totalPreguntas == null ? null : totalPreguntas! >= 180;
}

/// Días seguidos practicando (RF-49).
///
/// Se cuenta por **día de calendario** y no por bloques de 24 horas: quien
/// responde a las once de la noche y otra vez a las nueve de la mañana lleva
/// dos días, aunque hayan pasado diez horas.
@freezed
abstract class Racha with _$Racha {
  const factory Racha({
    @Default(0) int dias,

    /// Los últimos siete días; el último es hoy.
    @Default([]) List<bool> diasDeLaSemana,
  }) = _Racha;

  factory Racha.fromJson(Map<String, dynamic> json) => _$RachaFromJson(json);
}

/// Respuesta de `GET /stats/dashboard`.
///
/// Ya **no** trae `preguntasRestantesHoy`: era el contador del límite diario
/// del plan gratuito, y ese plan se eliminó (SSD-ENAM-002 §1). El acceso sale
/// de `GET /subscription`, no de aquí.
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

    /// La racha de días seguidos.
    ///
    /// Nula si el servidor no la manda, y entonces la tarjeta **no se pinta**.
    /// Estuvo escrita a mano en la pantalla —18 días, siempre— y un número que
    /// no se corresponde con lo que la persona hizo es peor que no tener
    /// racha: premia por algo que no pasó.
    Racha? racha,
  }) = _DashboardStats;

  const DashboardStats._();

  factory DashboardStats.fromJson(Map<String, dynamic> json) =>
      _$DashboardStatsFromJson(json);

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
