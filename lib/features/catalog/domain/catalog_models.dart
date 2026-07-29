import 'package:freezed_annotation/freezed_annotation.dart';

part 'catalog_models.freezed.dart';
part 'catalog_models.g.dart';

/// Un área del examen tal como la devuelve el backend, con el progreso del
/// usuario (`GET /catalog/areas`).
///
/// Los pesos vienen del servidor y no de la copia local en `Blueprint`: RN-02 y
/// el registro de riesgos del SSD exigen que sean configurables en base de datos
/// porque ASPEFAM puede cambiarlos.
@freezed
abstract class Area with _$Area {
  const factory Area({
    required String id,
    required String nombre,
    required String grupo,

    /// Preguntas que aporta al simulacro de 180 (peso del blueprint).
    required int preguntasBlueprint,
    @Default([]) List<Subtopic> subtemas,

    /// Preguntas del banco que el usuario ya vio en esta área.
    @Default(0) int preguntasVistas,

    /// Total de preguntas del banco en esta área.
    @Default(0) int preguntasTotales,

    /// Aciertos del usuario en esta área.
    @Default(0) int respuestasCorrectas,

    /// Preguntas respondidas por el usuario en esta área.
    @Default(0) int respuestasTotales,
  }) = _Area;

  const Area._();

  factory Area.fromJson(Map<String, dynamic> json) => _$AreaFromJson(json);

  /// Porcentaje de acierto (0.0 a 1.0). `null` si aún no respondió nada, para
  /// que la UI muestre "sin datos" en vez de un 0 % que parece un mal resultado.
  double? get porcentajeAcierto =>
      respuestasTotales == 0 ? null : respuestasCorrectas / respuestasTotales;

  /// Avance de cobertura del banco (0.0 a 1.0).
  double get cobertura =>
      preguntasTotales == 0 ? 0 : preguntasVistas / preguntasTotales;
}

@freezed
abstract class Subtopic with _$Subtopic {
  const factory Subtopic({
    required String id,
    required String areaId,
    required String nombre,
    required int preguntasBlueprint,
    @Default(0) int preguntasVistas,
    @Default(0) int preguntasTotales,
    @Default(0) int respuestasCorrectas,
    @Default(0) int respuestasTotales,
  }) = _Subtopic;

  const Subtopic._();

  factory Subtopic.fromJson(Map<String, dynamic> json) =>
      _$SubtopicFromJson(json);

  double? get porcentajeAcierto =>
      respuestasTotales == 0 ? null : respuestasCorrectas / respuestasTotales;
}
