/// Taxonomía oficial del ENAM.
///
/// Fuente: **Tabla de Especificaciones de ASPEFAM** (12 de octubre de 2025) y su
/// anexo de análisis del temario.
///
/// ## Por qué es un árbol recursivo y no tres clases fijas
///
/// El árbol tiene tres niveles nominales — área (10) → sub área (58) → tema (343)
/// — pero **no es homogéneo**:
///
/// - Cuatro áreas se quedan en el nivel 2: Emergencias, Ética, Investigación y
///   Gestión. Son 22 preguntas (12 % del examen). No es información faltante: el
///   documento oficial no las desarrolla.
/// - Ginecología Obstetricia tiene un **nivel intermedio propio**: sus sub áreas
///   se agrupan primero en bloques (Ginecología, Obstetricia) y recién dentro
///   aparecen las sub áreas. Es la única área con esa capa.
///
/// Un nodo recursivo cubre los tres casos con un solo modelo, y la UI que lo
/// recorre se escribe una vez.
///
/// ## Alcance de esta copia local
///
/// Aquí viven **áreas y sub áreas con sus pesos**, porque la UI debe poder pintar
/// el árbol y comparar desempeño sin esperar al backend. Los **343 temas NO están
/// aquí**: son demasiados, cambian más seguido y los entrega el servidor.
///
/// La fuente de verdad sigue siendo el backend (RN-02 exige que los pesos sean
/// configurables en base de datos, porque ASPEFAM puede cambiarlos).
library;

/// Grupo mayor del blueprint. Determina la organización de primer nivel.
enum AreaGroup {
  clinicoMedicas('Clínico Médicas', 90, 0.50),
  clinicoQuirurgicas('Clínico Quirúrgicas', 60, 0.33),
  transversales('Transversales', 30, 0.17);

  const AreaGroup(this.label, this.preguntas, this.porcentaje);

  final String label;

  /// Preguntas que aporta el grupo a un examen de 180.
  final int preguntas;

  /// Porcentaje del examen, según la Tabla de Especificaciones.
  final double porcentaje;
}

/// Nivel de un nodo dentro del árbol.
enum TaxonomyLevel {
  area,

  /// Capa intermedia que solo existe en Ginecología Obstetricia.
  bloque,
  subArea,
  tema,
}

/// Un nodo del árbol del temario.
class TaxonomyNode {
  const TaxonomyNode({
    required this.id,
    required this.nombre,
    required this.nivel,
    this.peso,
    this.grupo,
    this.hijos = const [],
  });

  /// Slug estable. Debe coincidir con el del backend.
  final String id;

  final String nombre;
  final TaxonomyLevel nivel;

  /// Preguntas que aporta al examen de 180. `null` en temas: el documento
  /// oficial no asigna peso a ese nivel.
  final int? peso;

  /// Solo en nodos de nivel área.
  final AreaGroup? grupo;

  final List<TaxonomyNode> hijos;

  bool get esHoja => hijos.isEmpty;

  /// Si este nodo desarrolla un nivel más de detalle.
  ///
  /// Cuatro áreas devuelven `false` aunque tengan sub áreas: es esperado, no un
  /// error de datos. La UI debe decir "sin temas detallados", no quedarse vacía.
  bool get tieneDetalle => hijos.isNotEmpty;

  /// Todos los descendientes en profundidad, sin incluirse a sí mismo.
  Iterable<TaxonomyNode> get descendientes sync* {
    for (final hijo in hijos) {
      yield hijo;
      yield* hijo.descendientes;
    }
  }

  /// Hojas del subárbol: los nodos más específicos que existen bajo este.
  Iterable<TaxonomyNode> get hojas sync* {
    if (esHoja) {
      yield this;
    } else {
      for (final hijo in hijos) {
        yield* hijo.hojas;
      }
    }
  }

  /// Suma de los pesos de los hijos directos. Sirve para validar consistencia.
  int get pesoDeHijos =>
      hijos.fold(0, (sum, h) => sum + (h.peso ?? 0));
}

abstract final class Taxonomy {
  /// Las 10 áreas oficiales con sus 58 sub áreas.
  static final List<TaxonomyNode> areas = [
    _medicina,
    _pediatria,
    _emergencias,
    _ginecoObstetricia,
    _cirugia,
    _saludPublica,
    _cienciasBasicas,
    _etica,
    _investigacion,
    _gestion,
  ];

  static List<TaxonomyNode> byGroup(AreaGroup grupo) =>
      areas.where((a) => a.grupo == grupo).toList();

  /// Busca un nodo por id en todo el árbol. `null` si no existe.
  static TaxonomyNode? byId(String id) {
    for (final area in areas) {
      if (area.id == id) return area;
      for (final nodo in area.descendientes) {
        if (nodo.id == id) return nodo;
      }
    }
    return null;
  }

  /// Todas las sub áreas del árbol. Deben ser 58.
  static Iterable<TaxonomyNode> get subAreas sync* {
    for (final area in areas) {
      for (final nodo in area.descendientes) {
        if (nodo.nivel == TaxonomyLevel.subArea) yield nodo;
      }
    }
  }

  /// Ruta desde el área hasta el nodo, para migas de pan.
  static List<TaxonomyNode> pathTo(String id) {
    for (final area in areas) {
      final path = _findPath(area, id);
      if (path != null) return path;
    }
    return const [];
  }

  static List<TaxonomyNode>? _findPath(TaxonomyNode nodo, String id) {
    if (nodo.id == id) return [nodo];
    for (final hijo in nodo.hijos) {
      final sub = _findPath(hijo, id);
      if (sub != null) return [nodo, ...sub];
    }
    return null;
  }
}

// ============================================================
// A. ÁREAS CLÍNICO MÉDICAS — 90 preguntas
// ============================================================

final _medicina = TaxonomyNode(
  id: 'medicina',
  nombre: 'Medicina',
  nivel: TaxonomyLevel.area,
  grupo: AreaGroup.clinicoMedicas,
  peso: 40,
  hijos: [
    _sub('medicina-infecciosos', 'Problemas infecciosos', 6),
    _sub('medicina-respiratorio', 'Problemas del aparato respiratorio', 4),
    _sub('medicina-cardiovascular', 'Problemas del aparato cardiovascular', 4),
    _sub('medicina-digestivo', 'Problemas de las vías digestivas', 4),
    _sub('medicina-nervioso', 'Problemas del sistema nervioso', 4),
    _sub('medicina-hormonal', 'Problemas hormonales y metabólicos', 3),
    _sub('medicina-articulares', 'Problemas articulares', 3),
    _sub('medicina-psiquiatria', 'Problemas de la salud mental y psiquiatría', 4),
    _sub('medicina-renal', 'Problemas renales', 4),
    _sub('medicina-piel', 'Problemas de la piel', 2),
    _sub('medicina-sangre', 'Problemas de la sangre y coagulación', 2),
  ],
);

final _pediatria = TaxonomyNode(
  id: 'pediatria',
  nombre: 'Pediatría',
  nivel: TaxonomyLevel.area,
  grupo: AreaGroup.clinicoMedicas,
  peso: 34,
  hijos: [
    _sub('pediatria-recien-nacido', 'Problemas en el recién nacido', 8),
    _sub(
      'pediatria-nino-adolescente',
      'Problemas de salud del niño y del adolescente',
      20,
    ),
    _sub('pediatria-urgencias', 'Urgencias y emergencias pediátricas', 5),
    _sub('pediatria-etica', 'Ética y deontología en pediatría', 1),
  ],
);

/// Única área organizada **por falla orgánica** y no por enfermedad.
final _emergencias = TaxonomyNode(
  id: 'emergencias',
  nombre: 'Emergencias y Cuidados Críticos Adultos',
  nivel: TaxonomyLevel.area,
  grupo: AreaGroup.clinicoMedicas,
  peso: 16,
  hijos: [
    _sub('emergencias-paro', 'Paro cardio respiratorio', 2),
    _sub('emergencias-circulatoria', 'Insuficiencia o falla circulatoria. Shock', 2),
    _sub(
      'emergencias-respiratoria',
      'Insuficiencia o falla respiratoria aguda y crónica',
      2,
    ),
    _sub('emergencias-renal', 'Insuficiencia o falla renal aguda y crónica', 2),
    _sub('emergencias-hepatica', 'Insuficiencia o falla hepática aguda y crónica', 2),
    _sub(
      'emergencias-endocrina',
      'Insuficiencia o falla endocrina aguda y crónica',
      1,
    ),
    _sub(
      'emergencias-neurologica',
      'Insuficiencia o falla neurológica aguda y crónica',
      1,
    ),
    _sub('emergencias-traumatica', 'Insuficiencia o falla traumática aguda', 1),
    _sub('emergencias-medio-interno', 'Insuficiencia o falla medio interno', 1),
    _sub('emergencias-intoxicaciones', 'Intoxicaciones, envenenamientos agudos', 2),
  ],
);

// ============================================================
// B. ÁREAS CLÍNICO QUIRÚRGICAS — 60 preguntas
// ============================================================

/// Ojo: oftalmología, otorrinolaringología y cirugía pediátrica viven **aquí**,
/// no como áreas propias ni dentro de Pediatría. Son 9 preguntas que un
/// estudiante buscaría en otro lado.
final _cirugia = TaxonomyNode(
  id: 'cirugia',
  nombre: 'Cirugía',
  nivel: TaxonomyLevel.area,
  grupo: AreaGroup.clinicoQuirurgicas,
  peso: 30,
  hijos: [
    _sub('cirugia-general', 'Cirugía general', 6),
    _sub('cirugia-traumatologia', 'Traumatología', 4),
    _sub('cirugia-urologia', 'Problemas de urología', 3),
    _sub('cirugia-oftalmologia', 'Problemas en oftalmología', 3),
    _sub('cirugia-otorrino', 'Problemas en otorrinolaringología', 3),
    _sub('cirugia-torax', 'Cirugía de tórax y cardiovascular', 3),
    _sub('cirugia-neurocirugia', 'Neurocirugía', 3),
    _sub('cirugia-pediatrica', 'Cirugía pediátrica', 3),
    _sub('cirugia-quemados', 'Quemados', 2),
  ],
);

/// Única área con **nivel intermedio** (bloques) entre el área y sus sub áreas.
///
/// Descuadre del documento oficial: el encabezado de Obstetricia dice 24
/// preguntas, pero sus partes suman 23. Con 23 el área cierra en los 30
/// oficiales, así que se toma 23. Pendiente de confirmar con ASPEFAM.
final _ginecoObstetricia = TaxonomyNode(
  id: 'gineco-obstetricia',
  nombre: 'Ginecología Obstetricia',
  nivel: TaxonomyLevel.area,
  grupo: AreaGroup.clinicoQuirurgicas,
  peso: 30,
  hijos: [
    TaxonomyNode(
      id: 'go-ginecologia',
      nombre: 'Problemas en ginecología',
      nivel: TaxonomyLevel.bloque,
      peso: 6,
      hijos: [
        _sub('go-tumores-pelvicos', 'Tumores pélvicos', 1),
        _sub('go-piso-pelvico', 'Alteraciones del piso pélvico', 1),
        _sub('go-infecciones-gine', 'Infecciones ginecológicas', 1),
        _sub('go-reproduccion', 'Reproducción humana', 1),
        _sub('go-ciclo-menstrual', 'Trastornos del ciclo menstrual', 1),
        _sub('go-cancer-gine', 'Cáncer ginecológico', 1),
      ],
    ),
    TaxonomyNode(
      id: 'go-obstetricia',
      nombre: 'Problemas en obstetricia',
      nivel: TaxonomyLevel.bloque,
      peso: 23,
      hijos: [
        _sub('go-control-prenatal', 'Control prenatal', 4),
        _sub('go-complicaciones', 'Complicaciones del embarazo', 4),
        _sub('go-parto', 'Parto', 4),
        _sub(
          'go-intercurrentes',
          'Enfermedades intercurrentes del embarazo',
          4,
        ),
        _sub('go-infecciones-obs', 'Infecciones en obstetricia', 3),
        _sub('go-hemorragia', 'Hemorragia obstétrica', 4),
      ],
    ),
    _sub('go-etica', 'Ética en gineco-obstetricia', 1),
  ],
);

// ============================================================
// C. ÁREAS TRANSVERSALES — 30 preguntas
// ============================================================

final _saludPublica = TaxonomyNode(
  id: 'salud-publica',
  nombre: 'Salud Pública y Prevención',
  nivel: TaxonomyLevel.area,
  grupo: AreaGroup.transversales,
  peso: 14,
  hijos: [
    _sub('sp-comunitaria', 'Salud comunitaria', 6),
    _sub('sp-promocion', 'Promoción y prevención', 6),
    _sub('sp-bioestadistica', 'Bioestadística – Epidemiología', 2),
  ],
);

final _cienciasBasicas = TaxonomyNode(
  id: 'ciencias-basicas',
  nombre: 'Ciencias Básicas',
  nivel: TaxonomyLevel.area,
  grupo: AreaGroup.transversales,
  peso: 10,
  hijos: [
    _sub('cb-morfologicas', 'Morfológicas', 4),
    _sub('cb-dinamicas', 'Dinámicas', 6),
  ],
);

final _etica = TaxonomyNode(
  id: 'etica',
  nombre: 'Ética',
  nivel: TaxonomyLevel.area,
  grupo: AreaGroup.transversales,
  peso: 2,
  hijos: [
    _sub('etica-marco', 'Marco conceptual de ética y deontología', 1),
    _sub('etica-conflictos', 'Conflictos éticos', 1),
  ],
);

final _investigacion = TaxonomyNode(
  id: 'investigacion',
  nombre: 'Investigación',
  nivel: TaxonomyLevel.area,
  grupo: AreaGroup.transversales,
  peso: 2,
  hijos: [
    _sub('inv-marco', 'Marco conceptual de investigación', 1),
    _sub('inv-proyectos', 'Proyectos y diseño de investigación', 1),
  ],
);

/// Contiene el nombre de sub área más largo del temario (75 caracteres).
/// Sirve como caso de prueba para cualquier etiqueta de la UI.
final _gestion = TaxonomyNode(
  id: 'gestion',
  nombre: 'Gestión',
  nivel: TaxonomyLevel.area,
  grupo: AreaGroup.transversales,
  peso: 2,
  hijos: [
    _sub(
      'gestion-establecimientos',
      'Gestión-Administración-Gerencia de establecimientos del I Nivel de Atención',
      1,
    ),
    _sub(
      'gestion-liderazgo',
      'Liderazgo, Comunicación, Motivación y Trabajo en Equipo',
      1,
    ),
  ],
);

/// Atajo para declarar una sub área hoja.
TaxonomyNode _sub(String id, String nombre, int peso) => TaxonomyNode(
  id: id,
  nombre: nombre,
  nivel: TaxonomyLevel.subArea,
  peso: peso,
);
