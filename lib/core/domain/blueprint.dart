/// Blueprint oficial del ENAM (tabla de especificaciones de ASPEFAM).
///
/// Fuente: SSD-ENAM-001 §1.3 y RN-02.
///
/// IMPORTANTE — estos pesos son la copia **local** del blueprint, y existen solo
/// para renderizar la UI sin esperar al backend (barras de progreso, comparación
/// de desempeño por área). La fuente de verdad es el servidor: RN-02 exige que el
/// generador de simulacros use los pesos de base de datos, y el registro de
/// riesgos del SSD advierte que ASPEFAM puede cambiarlos.
///
/// No uses estos valores para calcular notas ni para generar simulacros.
library;

/// Grupo al que pertenece un área dentro del blueprint.
enum AreaGroup {
  clinicoMedicas('Clínico Médicas'),
  clinicoQuirurgicas('Clínico Quirúrgicas'),
  transversales('Transversales');

  const AreaGroup(this.label);
  final String label;
}

/// Un área del examen con su peso oficial.
class BlueprintArea {
  const BlueprintArea({
    required this.id,
    required this.name,
    required this.group,
    required this.questionCount,
  });

  /// Identificador estable. Debe coincidir con el `slug` del backend.
  final String id;
  final String name;
  final AreaGroup group;

  /// Preguntas que aporta esta área a un simulacro de 180.
  final int questionCount;

  /// Peso relativo dentro del examen (0.0 a 1.0).
  double get weight => questionCount / Blueprint.totalQuestions;
}

/// El blueprint completo.
abstract final class Blueprint {
  /// Total de preguntas de un simulacro completo (RF-16).
  static const int totalQuestions = 180;

  /// Duración de un simulacro completo (RF-16).
  static const Duration examDuration = Duration(hours: 3);

  /// Nota mínima aprobatoria en escala vigesimal (RN-01).
  static const double passingGrade = 11.0;

  /// Nota máxima (escala vigesimal).
  static const double maxGrade = 20.0;

  /// Preguntas del simulacro de muestra para usuarios free (RN-03).
  static const int sampleExamQuestions = 40;

  /// Límite diario de práctica para usuarios free (RN-03).
  ///
  /// Se muestra en la UI, pero la validación real es del servidor.
  static const int freeDailyQuestionLimit = 20;

  /// Rango de preguntas configurable en una sesión de práctica (RF-12).
  static const int practiceMinQuestions = 10;
  static const int practiceMaxQuestions = 50;

  /// Las áreas oficiales, en el orden en que se presentan.
  static const List<BlueprintArea> areas = [
    // ---------- Clínico Médicas: 90 ----------
    BlueprintArea(
      id: 'medicina',
      name: 'Medicina',
      group: AreaGroup.clinicoMedicas,
      questionCount: 40,
    ),
    BlueprintArea(
      id: 'pediatria',
      name: 'Pediatría',
      group: AreaGroup.clinicoMedicas,
      questionCount: 34,
    ),
    BlueprintArea(
      id: 'emergencias',
      name: 'Emergencias',
      group: AreaGroup.clinicoMedicas,
      questionCount: 16,
    ),

    // ---------- Clínico Quirúrgicas: 60 ----------
    BlueprintArea(
      id: 'gineco-obstetricia',
      name: 'Gineco-Obstetricia',
      group: AreaGroup.clinicoQuirurgicas,
      questionCount: 30,
    ),
    BlueprintArea(
      id: 'cirugia',
      name: 'Cirugía',
      group: AreaGroup.clinicoQuirurgicas,
      questionCount: 30,
    ),

    // ---------- Transversales: 30 ----------
    BlueprintArea(
      id: 'salud-publica',
      name: 'Salud Pública',
      group: AreaGroup.transversales,
      questionCount: 14,
    ),
    BlueprintArea(
      id: 'ciencias-basicas',
      name: 'Ciencias Básicas',
      group: AreaGroup.transversales,
      questionCount: 10,
    ),
    BlueprintArea(
      id: 'etica',
      name: 'Ética',
      group: AreaGroup.transversales,
      questionCount: 2,
    ),
    BlueprintArea(
      id: 'investigacion',
      name: 'Investigación',
      group: AreaGroup.transversales,
      questionCount: 2,
    ),
    BlueprintArea(
      id: 'gestion',
      name: 'Gestión',
      group: AreaGroup.transversales,
      questionCount: 2,
    ),
  ];

  /// Áreas de un grupo.
  static List<BlueprintArea> byGroup(AreaGroup group) =>
      areas.where((a) => a.group == group).toList();

  /// Busca un área por su id. Devuelve `null` si el backend manda un área que
  /// esta versión de la app no conoce.
  static BlueprintArea? byId(String id) {
    for (final area in areas) {
      if (area.id == id) return area;
    }
    return null;
  }

  /// Preguntas que aporta un grupo completo.
  static int questionsInGroup(AreaGroup group) =>
      byGroup(group).fold(0, (sum, a) => sum + a.questionCount);

  /// Convierte respuestas correctas a nota vigesimal (RN-01).
  ///
  /// Sin puntaje en contra: en blanco e incorrecta valen igual, 0.
  /// Redondeado a 2 decimales, como el examen real.
  static double toVigesimal(int correct, {int total = totalQuestions}) {
    if (total <= 0) return 0;
    final grade = (correct / total) * maxGrade;
    return double.parse(grade.toStringAsFixed(2));
  }

  /// Si una nota vigesimal aprueba (RN-01).
  static bool isPassing(double grade) => grade >= passingGrade;
}
