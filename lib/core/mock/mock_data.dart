import 'dart:math';

import '../../features/catalog/domain/catalog_models.dart';
import '../../features/session/domain/session_models.dart';
import '../domain/taxonomy.dart';

/// Datos falsos para desarrollar sin backend.
///
/// El contenido médico es **de relleno y no es clínicamente correcto**. Solo
/// existe para que las pantallas tengan texto realista en longitud y forma: los
/// enunciados son largos a propósito porque el 81 % del ENAM son casos clínicos,
/// y una UI que se ve bien con texto corto miente sobre cómo se verá de verdad.
abstract final class MockData {
  static final _random = Random(42); // Semilla fija: datos reproducibles.

  /// El árbol del catálogo con progreso simulado, a partir de la taxonomía real.
  ///
  /// Genera temas falsos bajo las sub áreas que sí desarrollan tercer nivel, y
  /// deja sin hijos las cuatro áreas que el documento oficial no desarrolla, para
  /// que la UI tenga que enfrentar ese caso desde el principio.
  static List<CatalogNode> catalog() =>
      Taxonomy.areas.map(_nodeFrom).toList(growable: false);

  /// Áreas cuyo tercer nivel no existe en el documento oficial.
  static const _sinTemas = {'emergencias', 'etica', 'investigacion', 'gestion'};

  static CatalogNode _nodeFrom(TaxonomyNode node, {String? areaRaiz}) {
    final raiz = areaRaiz ?? node.id;
    final generaTemas =
        node.nivel == TaxonomyLevel.subArea && !_sinTemas.contains(raiz);

    final hijos = <CatalogNode>[
      for (final hijo in node.hijos) _nodeFrom(hijo, areaRaiz: raiz),
      if (generaTemas) ..._temasFalsos(node),
    ];

    // Un nodo con hijos agrega su progreso; una hoja lo genera.
    if (hijos.isNotEmpty) {
      final disponibles = hijos.fold(0, (s, h) => s + h.preguntasDisponibles);
      final vistas = hijos.fold(0, (s, h) => s + h.preguntasVistas);
      final totales = hijos.fold(0, (s, h) => s + h.respuestasTotales);
      final correctas = hijos.fold(0, (s, h) => s + h.respuestasCorrectas);

      return CatalogNode(
        id: node.id,
        nombre: node.nombre,
        nivel: _levelName(node.nivel),
        peso: node.peso,
        grupo: node.grupo?.label,
        hijos: hijos,
        preguntasDisponibles: disponibles,
        preguntasVistas: vistas,
        respuestasTotales: totales,
        respuestasCorrectas: correctas,
      );
    }

    return _hoja(node);
  }

  static CatalogNode _hoja(TaxonomyNode node) {
    final peso = node.peso ?? 1;

    // ~12 preguntas de banco por cada pregunta que cae en el examen. Un 15 % de
    // los nodos queda sin contenido: el banco se carga progresivamente.
    final disponibles = _random.nextDouble() < 0.15 ? 0 : peso * 12;
    final vistas = disponibles == 0 ? 0 : _random.nextInt(disponibles + 1);
    final correctas = (vistas * (0.4 + _random.nextDouble() * 0.45)).round();

    return CatalogNode(
      id: node.id,
      nombre: node.nombre,
      nivel: _levelName(node.nivel),
      peso: node.peso,
      grupo: node.grupo?.label,
      preguntasDisponibles: disponibles,
      preguntasVistas: vistas,
      respuestasTotales: vistas,
      respuestasCorrectas: correctas,
    );
  }

  /// Temas falsos bajo una sub área, para poblar el tercer nivel.
  static List<CatalogNode> _temasFalsos(TaxonomyNode subArea) {
    // La densidad real ronda 3 temas por pregunta en las áreas grandes.
    final cantidad = max(2, ((subArea.peso ?? 1) * 2.5).round());

    return List.generate(cantidad, (i) {
      final disponibles = _random.nextDouble() < 0.15 ? 0 : 4 + _random.nextInt(9);
      final vistas = disponibles == 0 ? 0 : _random.nextInt(disponibles + 1);
      final correctas = (vistas * (0.4 + _random.nextDouble() * 0.45)).round();

      return CatalogNode(
        id: '${subArea.id}-t${i + 1}',
        nombre: _nombreTema(subArea, i),
        nivel: 'tema',
        preguntasDisponibles: disponibles,
        preguntasVistas: vistas,
        respuestasTotales: vistas,
        respuestasCorrectas: correctas,
      );
    });
  }

  /// Nombres de tema con longitudes realistas.
  ///
  /// La mediana real son 20 caracteres, pero hay temas de hasta 107. El primero
  /// de cada sub área usa el caso largo a propósito, para que ninguna pantalla se
  /// diseñe asumiendo etiquetas cortas.
  static String _nombreTema(TaxonomyNode subArea, int i) {
    if (i == 0) {
      return 'Hemorragia de la segunda mitad del embarazo: Desprendimiento '
          'Prematuro de Placenta, Placenta Previa y otros';
    }
    const cortos = [
      'Tuberculosis',
      'Cefalea',
      'Hemorroides',
      'ITU',
      'Asma bronquial',
      'Hipertensión arterial',
      'Diarrea aguda',
      'Sepsis neonatal',
      'Glaucoma',
      'Epistaxis',
    ];
    return cortos[i % cortos.length];
  }

  static String _levelName(TaxonomyLevel nivel) => switch (nivel) {
    TaxonomyLevel.area => 'area',
    TaxonomyLevel.bloque => 'bloque',
    TaxonomyLevel.subArea => 'sub_area',
    TaxonomyLevel.tema => 'tema',
  };

  // ==================== PREGUNTAS ====================

  /// Enunciados de relleno con la longitud típica de un caso clínico del ENAM.
  static const List<String> _enunciados = [
    'Paciente varón de 58 años, con antecedente de hipertensión arterial de 10 '
        'años de evolución en tratamiento irregular con enalapril, acude a '
        'emergencia por cuadro de 3 horas de evolución caracterizado por dolor '
        'torácico opresivo retroesternal de inicio súbito, irradiado a miembro '
        'superior izquierdo, asociado a diaforesis profusa y náuseas. Al examen '
        'físico: PA 160/95 mmHg, FC 98 lpm, FR 22 rpm, SatO2 94 % al aire '
        'ambiente. Ruidos cardíacos rítmicos, sin soplos. Murmullo vesicular '
        'conservado. ¿Cuál es la conducta inicial más apropiada?',
    'Gestante de 32 años, G3P2002, con 34 semanas de gestación por fecha de '
        'última regla confiable, acude a control prenatal refiriendo cefalea '
        'occipital persistente de 2 días de evolución y escotomas centellantes. '
        'Al examen: PA 158/102 mmHg en dos tomas separadas por 4 horas, edema '
        'de miembros inferiores ++/+++. Proteinuria en tira reactiva ++. '
        'Altura uterina 32 cm, latidos cardíacos fetales 140 lpm. ¿Cuál es el '
        'diagnóstico más probable?',
    'Lactante de 8 meses, previamente sano, con esquema de vacunación completo '
        'para la edad, es traído por su madre por cuadro de 4 días de evolución '
        'caracterizado por fiebre de hasta 39 °C, rinorrea hialina y tos seca '
        'que en las últimas 24 horas se tornó productiva, acompañada de '
        'dificultad respiratoria progresiva. Al examen: FR 62 rpm, tiraje '
        'subcostal, sibilancias espiratorias difusas y crepitantes bibasales. '
        '¿Cuál es el manejo inicial indicado?',
    'Varón de 24 años, sin antecedentes patológicos, acude por dolor abdominal '
        'de 18 horas de evolución que inició en región periumbilical y migró a '
        'fosa ilíaca derecha, asociado a náuseas, un episodio de vómito y '
        'anorexia. Al examen: T 37.8 °C, dolor a la palpación en punto de '
        'McBurney con signo de Blumberg positivo. Hemograma: leucocitos '
        '14 500/mm³ con 82 % de neutrófilos. ¿Cuál es la conducta a seguir?',
    // Pregunta directa: el 19 % del examen no son casos clínicos.
    'Según la normativa vigente del Ministerio de Salud del Perú, ¿cuál es la '
        'medida de salud pública prioritaria ante un brote de enfermedad '
        'diarreica aguda que supera el canal endémico en un distrito?',
  ];

  static const List<List<String>> _alternativas = [
    [
      'Iniciar terapia antiagregante y solicitar electrocardiograma de 12 derivaciones',
      'Administrar analgesia opioide y observar por 6 horas',
      'Solicitar radiografía de tórax y diferir el manejo',
      'Indicar prueba de esfuerzo ambulatoria',
    ],
    [
      'Preeclampsia con criterios de severidad',
      'Hipertensión gestacional sin proteinuria',
      'Hipertensión crónica pregestacional',
      'Cefalea tensional en gestante normotensa',
    ],
    [
      'Oxigenoterapia, hidratación y manejo de soporte con monitoreo',
      'Antibioticoterapia endovenosa de amplio espectro de inmediato',
      'Corticoide sistémico en dosis única y alta domiciliaria',
      'Nebulización con adrenalina y alta inmediata',
    ],
    [
      'Evaluación quirúrgica para apendicectomía',
      'Manejo conservador con antibióticos y control en 48 horas',
      'Tomografía abdominal antes de cualquier conducta',
      'Alta con analgesia y control ambulatorio',
    ],
    [
      'Investigación epidemiológica de campo y búsqueda activa de casos',
      'Solicitar presupuesto adicional a la DIRESA',
      'Derivar todos los casos al hospital de referencia',
      'Esperar la confirmación de laboratorio antes de actuar',
    ],
  ];

  /// Genera [cantidad] preguntas falsas para las áreas indicadas.
  ///
  /// Si [areaIds] viene vacío, usa todas las áreas.
  static List<Question> questions({
    required int cantidad,
    List<String> areaIds = const [],
    bool conRespuestas = false,
  }) {
    final areas = areaIds.isEmpty
        ? Taxonomy.areas.map((a) => a.id).toList()
        : areaIds;

    return List.generate(cantidad, (i) {
      final areaId = areas[i % areas.length];
      final idx = i % _enunciados.length;
      final correctaIdx = _random.nextInt(4);

      final area = Taxonomy.byId(areaId);
      final subArea = area?.hijos.isNotEmpty ?? false
          ? area!.hijos[i % area.hijos.length]
          : null;

      return Question(
        id: 'q-${i + 1}',
        enunciado: _enunciados[idx],
        areaId: areaId,
        subtemaId: subArea?.id ?? areaId,
        // El índice 4 es la única pregunta directa del set.
        tipo: idx == 4 ? QuestionType.directa : QuestionType.casoClinico,
        dificultad: 1 + _random.nextInt(3),
        origenAnio: _random.nextBool() ? 2020 + _random.nextInt(6) : null,
        porcentajeAciertoGlobal: 0.25 + _random.nextDouble() * 0.6,
        explicacion: conRespuestas
            ? 'Explicación de la clave. Texto de relleno, no constituye '
                  'información clínica válida.'
            : null,
        opciones: [
          for (var j = 0; j < 4; j++)
            QuestionOption(
              id: 'q-${i + 1}-o${j + 1}',
              texto: _alternativas[idx][j],
              esCorrecta: conRespuestas ? j == correctaIdx : null,
              // Las CUATRO llevan explicación, también la correcta: así viene
              // el banco real y es lo que hace que la pregunta enseñe. Cuando
              // la de la clave faltaba, la pantalla de retroalimentación se
              // probaba con un hueco que en producción no existe.
              explicacion: !conRespuestas
                  ? null
                  : j == correctaIdx
                  ? 'Es la correcta porque corresponde al cuadro descrito. '
                        'Texto de relleno, no es información clínica válida.'
                  : 'Este distractor es incorrecto porque no corresponde al '
                        'cuadro descrito.',
            ),
        ],
      );
    });
  }
}
