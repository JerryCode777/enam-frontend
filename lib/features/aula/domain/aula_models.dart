import 'package:freezed_annotation/freezed_annotation.dart';

part 'aula_models.freezed.dart';
part 'aula_models.g.dart';

/// El contrato del aula (`enam-backend/AULA.md` §4).
///
/// Es el gemelo en Dart de `src/types/aula.ts` de la web, con los mismos
/// nombres de campo: si los dos clientes leen distinto el mismo JSON, el fallo
/// sale en uno solo y en producción.
///
/// Las URL de medios (`videoUrl`, `subtitulosUrl`, miniaturas, retratos) llegan
/// **firmadas y caducan**. No se guardan: se piden cada vez.

/// Qué parte de la clase hay que ver para que cuente como vista. Lo decide el
/// servidor; aquí solo sirve para enseñar «Vista» sin esperarlo.
const umbralCompletada = 0.9;

/// Cada cuántos segundos de reproducción se manda el progreso.
const progresoCadaS = 15;

/// Un curso por área de la tabla oficial, más el repaso final.
@JsonEnum(fieldRename: FieldRename.snake)
enum TipoDeCurso {
  area,
  repaso,
  @JsonValue('__desconocido__')
  desconocido,
}

/// El profe virtual del curso: «Profe Nombre», sin título ni colegiatura.
@freezed
abstract class Profe with _$Profe {
  const factory Profe({
    required String id,
    required String nombre,
    String? articulo,
    String? retratoUrl,
    String? retratoMiniUrl,
  }) = _Profe;

  factory Profe.fromJson(Map<String, dynamic> json) => _$ProfeFromJson(json);
}

/// Un curso en el catálogo.
@freezed
abstract class CursoResumen with _$CursoResumen {
  const factory CursoResumen({
    required String id,
    @JsonKey(unknownEnumValue: TipoDeCurso.desconocido)
    @Default(TipoDeCurso.area)
    TipoDeCurso tipo,

    /// Nulo en el repaso final, que no es un área.
    String? areaId,
    required String titulo,
    @Default('') String descripcion,
    @Default('') String lema,
    Profe? profe,
    String? portadaUrl,
    @Default(0) int orden,

    /// Sin ninguna clase disponible no está publicado: «Próximamente».
    @Default(false) bool publicado,

    /// Todas las clases del temario, también las que vienen.
    @Default(0) int clases,
    @Default(0) int disponibles,
    @Default(0) int gratis,

    /// Solo de las disponibles.
    @Default(0) int duracionS,
    @Default(0) int completadas,
  }) = _CursoResumen;

  const CursoResumen._();

  factory CursoResumen.fromJson(Map<String, dynamic> json) =>
      _$CursoResumenFromJson(json);

  bool get esRepaso => tipo == TipoDeCurso.repaso;

  /// Todavía sin clases que ver.
  bool get proximamente => disponibles == 0;
}

@freezed
abstract class ProgresoDeClase with _$ProgresoDeClase {
  const factory ProgresoDeClase({
    @Default(0) int segundosVistos,
    @Default(0) int posicionS,
    @Default(false) bool completada,
  }) = _ProgresoDeClase;

  factory ProgresoDeClase.fromJson(Map<String, dynamic> json) =>
      _$ProgresoDeClaseFromJson(json);
}

@JsonEnum(fieldRename: FieldRename.snake)
enum EstadoDeClase {
  disponible,
  proximamente,
  @JsonValue('__desconocido__')
  desconocido,
}

/// Una clase en el temario del curso.
@freezed
abstract class ClaseResumen with _$ClaseResumen {
  const factory ClaseResumen({
    required String id,
    @Default('') String codigo,
    @Default(0) int orden,
    required String titulo,
    @Default(0) int duracionS,
    @JsonKey(unknownEnumValue: EstadoDeClase.desconocido)
    @Default(EstadoDeClase.proximamente)
    EstadoDeClase estado,

    /// De la muestra gratis del curso.
    @Default(false) bool gratis,

    /// Sin Premium y no es gratis: se ve en el temario, no se abre.
    @Default(false) bool bloqueada,
    String? miniaturaUrl,
    @Default(ProgresoDeClase()) ProgresoDeClase progreso,
  }) = _ClaseResumen;

  const ClaseResumen._();

  factory ClaseResumen.fromJson(Map<String, dynamic> json) =>
      _$ClaseResumenFromJson(json);

  bool get disponible => estado == EstadoDeClase.disponible;

  /// Empezada y sin terminar: lo que pinta la barrita del temario. Con un
  /// mínimo, para que dos segundos por error no la dibujen.
  double? get avance {
    if (progreso.completada || duracionS <= 0) return null;
    final a = progreso.segundosVistos / duracionS;
    return a > 0.02 ? a.clamp(0, 1).toDouble() : null;
  }
}

@freezed
abstract class Modulo with _$Modulo {
  const factory Modulo({
    required String id,
    @Default('') String codigo,
    @Default(0) int orden,
    required String titulo,
    @Default('') String descripcion,
    @Default('') String nodoId,
    @Default([]) List<ClaseResumen> clases,
  }) = _Modulo;

  const Modulo._();

  factory Modulo.fromJson(Map<String, dynamic> json) => _$ModuloFromJson(json);

  Iterable<ClaseResumen> get disponibles => clases.where((c) => c.disponible);
}

/// El curso con su temario.
@freezed
abstract class Curso with _$Curso {
  const factory Curso({
    required String id,
    @JsonKey(unknownEnumValue: TipoDeCurso.desconocido)
    @Default(TipoDeCurso.area)
    TipoDeCurso tipo,
    String? areaId,
    required String titulo,
    @Default('') String descripcion,
    @Default('') String lema,
    Profe? profe,
    String? portadaUrl,
    @Default(0) int clases,
    @Default(0) int disponibles,
    @Default(0) int gratis,
    @Default(0) int duracionS,
    @Default(0) int completadas,

    /// La cuenta ve todo el curso.
    @Default(false) bool premium,
    @Default([]) List<Modulo> modulos,

    /// La próxima clase sin completar que la cuenta puede abrir. La decide el
    /// servidor, como en la web.
    ClaseResumen? continuar,
  }) = _Curso;

  const Curso._();

  factory Curso.fromJson(Map<String, dynamic> json) => _$CursoFromJson(json);
}

@JsonEnum(fieldRename: FieldRename.snake)
enum TipoDeReferencia {
  norma,
  guia,
  libro,
  articulo,
  @JsonValue('__desconocido__')
  desconocido;

  String get etiqueta => switch (this) {
    norma => 'Norma',
    guia => 'Guía',
    libro => 'Libro',
    articulo => 'Artículo',
    desconocido => 'Fuente',
  };
}

@freezed
abstract class Referencia with _$Referencia {
  const factory Referencia({
    required String id,
    @JsonKey(unknownEnumValue: TipoDeReferencia.desconocido)
    @Default(TipoDeReferencia.desconocido)
    TipoDeReferencia tipo,
    required String cita,
    int? anio,
    String? edicion,
    String? capitulo,
    String? paginas,
    String? url,
    String? doi,
  }) = _Referencia;

  const Referencia._();

  factory Referencia.fromJson(Map<String, dynamic> json) =>
      _$ReferenciaFromJson(json);

  /// «21.ª ed. · cap. 482 · 2020», con lo que haya.
  String get detalle => [
    if (edicion case final e?) '$e ed.',
    if (capitulo case final c?) 'cap. $c',
    if (paginas case final p?) 'págs. $p',
    if (anio case final a?) '$a',
  ].join(' · ');

  /// Dónde se abre: la URL, o el DOI si no hay URL.
  String? get enlace => url ?? (doi == null ? null : 'https://doi.org/$doi');
}

/// La clase anterior o la siguiente.
@freezed
abstract class Vecina with _$Vecina {
  const factory Vecina({
    required String id,
    required String titulo,
    @Default(false) bool bloqueada,
  }) = _Vecina;

  factory Vecina.fromJson(Map<String, dynamic> json) => _$VecinaFromJson(json);
}

/// La clase para verla.
@freezed
abstract class Clase with _$Clase {
  const factory Clase({
    required String id,
    @Default('') String codigo,
    required String titulo,
    @Default(0) int duracionS,
    @JsonKey(unknownEnumValue: EstadoDeClase.desconocido)
    @Default(EstadoDeClase.proximamente)
    EstadoDeClase estado,
    @Default(false) bool gratis,
    @Default(false) bool bloqueada,
    String? miniaturaUrl,
    @Default(ProgresoDeClase()) ProgresoDeClase progreso,
    required String cursoId,
    @Default('') String cursoTitulo,
    Profe? profe,
    @Default('') String moduloId,
    @Default([]) List<String> objetivos,
    @Default([]) List<String> temas,
    @Default([]) List<Referencia> referencias,

    /// Firmadas: caducan a las 4 h. Solo si la clase está disponible.
    String? videoUrl,
    String? subtitulosUrl,

    /// El nodo de la clase tiene preguntas publicadas.
    @Default(false) bool practicaDisponible,
    Vecina? anterior,
    Vecina? siguiente,
  }) = _Clase;

  const Clase._();

  factory Clase.fromJson(Map<String, dynamic> json) => _$ClaseFromJson(json);

  bool get disponible => estado == EstadoDeClase.disponible;

  /// Se puede reproducir.
  bool get conVideo => disponible && videoUrl != null;
}

/// `GET /aula/continuar`: lo último a medias. El servidor da 204 si no hay.
@freezed
abstract class SeguirViendo with _$SeguirViendo {
  const factory SeguirViendo({
    required String cursoId,
    @Default('') String cursoTitulo,
    required ClaseResumen clase,
  }) = _SeguirViendo;

  factory SeguirViendo.fromJson(Map<String, dynamic> json) =>
      _$SeguirViendoFromJson(json);
}
