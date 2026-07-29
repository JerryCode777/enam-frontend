import 'dart:math';

import '../../features/catalog/domain/catalog_models.dart';
import '../../features/session/domain/session_models.dart';
import '../domain/blueprint.dart';

/// Datos falsos para desarrollar sin backend.
///
/// El contenido médico es **de relleno y no es clínicamente correcto**. Solo
/// existe para que las pantallas tengan texto realista en longitud y forma: los
/// enunciados son largos a propósito porque el 90 % del ENAM son casos clínicos
/// y una UI que se ve bien con "Lorem ipsum" corto miente sobre cómo se verá.
abstract final class MockData {
  static final _random = Random(42); // Semilla fija: datos reproducibles.

  /// Subtemas por área, tomados de RF-06.
  static const Map<String, List<String>> _subtemas = {
    'medicina': [
      'Infecciosos',
      'Respiratorio',
      'Cardiovascular',
      'Digestivo',
      'Nervioso',
      'Psiquiatría',
      'Renal',
      'Endocrino-metabólico',
      'Articulares',
      'Piel',
      'Sangre y coagulación',
    ],
    'pediatria': [
      'Neonatología',
      'Crecimiento y desarrollo',
      'Infecciones pediátricas',
      'Respiratorio pediátrico',
      'Nutrición',
    ],
    'emergencias': [
      'Trauma',
      'Shock',
      'Paro cardiorrespiratorio',
      'Intoxicaciones',
    ],
    'gineco-obstetricia': [
      'Embarazo normal',
      'Patología obstétrica',
      'Ginecología',
      'Planificación familiar',
    ],
    'cirugia': [
      'Abdomen agudo',
      'Cirugía general',
      'Urología',
      'Traumatología',
    ],
    'salud-publica': [
      'Epidemiología',
      'Programas nacionales',
      'Bioestadística',
      'Atención primaria',
    ],
    'ciencias-basicas': ['Anatomía', 'Fisiología', 'Farmacología', 'Patología'],
    'etica': ['Bioética', 'Consentimiento informado'],
    'investigacion': ['Diseño de estudios', 'Lectura crítica'],
    'gestion': ['Gestión de servicios', 'Calidad en salud'],
  };

  /// Catálogo completo con progreso simulado del usuario.
  static List<Area> areas() {
    return Blueprint.areas.map((blueprintArea) {
      final subtemasNombres = _subtemas[blueprintArea.id] ?? const [];
      final totalBanco = blueprintArea.questionCount * 12;
      final vistas = _random.nextInt(totalBanco);
      final respondidas = vistas;
      final correctas = (respondidas * (0.45 + _random.nextDouble() * 0.4))
          .round();

      return Area(
        id: blueprintArea.id,
        nombre: blueprintArea.name,
        grupo: blueprintArea.group.label,
        preguntasBlueprint: blueprintArea.questionCount,
        preguntasVistas: vistas,
        preguntasTotales: totalBanco,
        respuestasCorrectas: correctas,
        respuestasTotales: respondidas,
        subtemas: [
          for (var i = 0; i < subtemasNombres.length; i++)
            _subtopic(blueprintArea.id, subtemasNombres[i], i, totalBanco ~/
                (subtemasNombres.isEmpty ? 1 : subtemasNombres.length)),
        ],
      );
    }).toList();
  }

  static Subtopic _subtopic(
    String areaId,
    String nombre,
    int index,
    int totalBanco,
  ) {
    final vistas = _random.nextInt(totalBanco + 1);
    final correctas = (vistas * (0.4 + _random.nextDouble() * 0.45)).round();
    return Subtopic(
      id: '$areaId-${index + 1}',
      areaId: areaId,
      nombre: nombre,
      preguntasBlueprint: max(1, totalBanco ~/ 12),
      preguntasVistas: vistas,
      preguntasTotales: totalBanco,
      respuestasCorrectas: correctas,
      respuestasTotales: vistas,
    );
  }

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
    'En un distrito de la sierra sur del Perú se reporta un incremento '
        'sostenido de casos de enfermedad diarreica aguda en menores de 5 años '
        'durante las últimas 6 semanas, superando el canal endémico esperado '
        'para el período. El establecimiento de salud del primer nivel debe '
        'definir la intervención prioritaria. ¿Cuál es la medida de salud '
        'pública más apropiada como primera acción?',
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
        ? Blueprint.areas.map((a) => a.id).toList()
        : areaIds;

    return List.generate(cantidad, (i) {
      final areaId = areas[i % areas.length];
      final idx = i % _enunciados.length;
      final correctaIdx = _random.nextInt(4);
      final subtemasArea = _subtemas[areaId] ?? const ['General'];

      return Question(
        id: 'q-${i + 1}',
        enunciado: _enunciados[idx],
        areaId: areaId,
        subtemaId: '$areaId-1',
        tipo: idx == 4 ? QuestionType.directa : QuestionType.casoClinico,
        dificultad: 1 + _random.nextInt(3),
        origenAnio: _random.nextBool() ? 2020 + _random.nextInt(6) : null,
        porcentajeAciertoGlobal: 0.25 + _random.nextDouble() * 0.6,
        explicacion: conRespuestas
            ? 'Explicación de la clave para ${subtemasArea.first}. Este texto '
                  'es de relleno y no constituye información clínica válida.'
            : null,
        opciones: [
          for (var j = 0; j < 4; j++)
            QuestionOption(
              id: 'q-${i + 1}-o${j + 1}',
              texto: _alternativas[idx][j],
              esCorrecta: conRespuestas ? j == correctaIdx : null,
              explicacion: conRespuestas && j != correctaIdx
                  ? 'Este distractor es incorrecto porque no corresponde al '
                        'cuadro descrito.'
                  : null,
            ),
        ],
      );
    });
  }
}
