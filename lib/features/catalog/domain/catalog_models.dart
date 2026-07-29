import 'package:freezed_annotation/freezed_annotation.dart';

part 'catalog_models.freezed.dart';
part 'catalog_models.g.dart';

/// Un nodo del temario tal como lo devuelve el backend (`GET /catalog/areas`),
/// con el progreso del usuario.
///
/// Es **recursivo** porque el árbol oficial no es homogéneo: la mayoría de las
/// áreas tienen dos niveles bajo ellas, cuatro tienen uno solo, y Ginecología
/// Obstetricia tiene una capa intermedia de bloques. Un único modelo cubre los
/// tres casos.
///
/// Los pesos vienen del servidor y no de la copia local en `Taxonomy`: RN-02 y
/// el registro de riesgos del SSD exigen que sean configurables en base de
/// datos, porque ASPEFAM puede cambiarlos.
@freezed
abstract class CatalogNode with _$CatalogNode {
  const factory CatalogNode({
    required String id,
    required String nombre,

    /// `area`, `bloque`, `sub_area` o `tema`.
    required String nivel,

    /// Preguntas que aporta al examen de 180. `null` en temas.
    int? peso,

    /// Solo en nodos de nivel área.
    String? grupo,
    @Default([]) List<CatalogNode> hijos,

    /// Preguntas del banco disponibles en este nodo.
    ///
    /// Puede ser 0: el banco se carga de forma progresiva, así que durante un
    /// tiempo habrá partes del temario sin preguntas todavía. La UI debe decir
    /// "aún no disponible", no mostrar una lista vacía sin explicación.
    @Default(0) int preguntasDisponibles,

    /// Preguntas de este nodo que el usuario ya vio.
    @Default(0) int preguntasVistas,

    /// Respuestas del usuario en este nodo.
    @Default(0) int respuestasTotales,
    @Default(0) int respuestasCorrectas,
  }) = _CatalogNode;

  const CatalogNode._();

  factory CatalogNode.fromJson(Map<String, dynamic> json) =>
      _$CatalogNodeFromJson(json);

  bool get esArea => nivel == 'area';
  bool get esTema => nivel == 'tema';
  bool get tieneHijos => hijos.isNotEmpty;

  /// Si todavía no hay preguntas cargadas para este nodo.
  bool get sinContenido => preguntasDisponibles == 0;

  /// Porcentaje de acierto (0.0 a 1.0).
  ///
  /// `null` cuando no hay respuestas, para que la UI muestre "sin datos" en vez
  /// de un 0 % que se lee como un mal resultado.
  double? get porcentajeAcierto =>
      respuestasTotales == 0 ? null : respuestasCorrectas / respuestasTotales;

  /// Avance de cobertura del banco en este nodo (0.0 a 1.0).
  double get cobertura => preguntasDisponibles == 0
      ? 0
      : (preguntasVistas / preguntasDisponibles).clamp(0.0, 1.0);

  /// Todos los descendientes en profundidad.
  Iterable<CatalogNode> get descendientes sync* {
    for (final hijo in hijos) {
      yield hijo;
      yield* hijo.descendientes;
    }
  }

  /// Hojas del subárbol: los nodos más específicos disponibles.
  Iterable<CatalogNode> get hojas sync* {
    if (hijos.isEmpty) {
      yield this;
    } else {
      for (final hijo in hijos) {
        yield* hijo.hojas;
      }
    }
  }

  /// Temas contabilizados bajo este nodo. Sirve para la densidad de estudio.
  int get totalTemas => descendientes.where((n) => n.esTema).length;
}
