import 'taxonomy.dart';

/// Reglas del examen: cuánto vale, cuánto dura y cómo se califica.
///
/// La **estructura** del temario (áreas, sub áreas, pesos) vive en
/// [Taxonomy]. Aquí solo están las constantes y el cálculo de la nota.
///
/// Fuente: SSD-ENAM-001 §1.3 y RN-01 a RN-03, con el modelo de cobro de
/// SSD-ENAM-002 §1.
abstract final class Blueprint {
  /// Preguntas de un simulacro completo (RF-16).
  static const int totalQuestions = 180;

  /// Duración de un simulacro completo (RF-16).
  static const Duration examDuration = Duration(hours: 3);

  /// Nota mínima aprobatoria, escala vigesimal (RN-01).
  static const double passingGrade = 11.0;

  static const double maxGrade = 20.0;

  /// Alternativas por pregunta. Una sola correcta, sin puntaje en contra.
  static const int optionsPerQuestion = 4;

  /// Proporción de casos clínicos, medida sobre 14 exámenes reales.
  ///
  /// El resto son preguntas teóricas directas. Condiciona la tipografía: la
  /// mayoría de enunciados son de varios párrafos.
  static const double clinicalCaseRatio = 0.81;

  /// Preguntas de la versión corta del simulacro.
  ///
  /// Era "el simulacro de cortesía del plan free". Ese plan ya no existe
  /// (SSD-ENAM-002 §1): ahora es solo una opción para medirse en poco tiempo,
  /// disponible para cualquiera con acceso.
  static const int sampleExamQuestions = 40;

  // La duración de la prueba (24 h, RN-03 v2) no está aquí a propósito: la
  // fija el servidor al arrancar el reloj en la primera práctica (D-02), y la
  // app la lee de `Subscription.expira`. Una constante local sería una segunda
  // fuente que se contradice en silencio el día que el negocio la cambie.

  /// Rango configurable en una sesión de práctica (RF-12).
  static const int practiceMinQuestions = 10;
  static const int practiceMaxQuestions = 50;

  /// Las 10 áreas oficiales. Atajo a [Taxonomy.areas].
  static List<TaxonomyNode> get areas => Taxonomy.areas;

  /// Preguntas que aporta un grupo completo.
  static int questionsInGroup(AreaGroup grupo) => grupo.preguntas;

  /// Peso de un área dentro del examen (0.0 a 1.0).
  static double weightOf(TaxonomyNode area) =>
      (area.peso ?? 0) / totalQuestions;

  /// Convierte respuestas correctas a nota vigesimal (RN-01).
  ///
  /// Sin puntaje en contra: dejar en blanco e incorrecta valen igual, 0.
  /// Redondeado a 2 decimales, como el examen real.
  static double toVigesimal(int correct, {int total = totalQuestions}) {
    if (total <= 0) return 0;
    final grade = (correct / total) * maxGrade;
    return double.parse(grade.toStringAsFixed(2));
  }

  static bool isPassing(double grade) => grade >= passingGrade;

  /// Cuántos temas del banco hay que estudiar por cada pregunta que cae.
  ///
  /// Es el dato menos obvio del temario y el más accionable: en Medicina hacen
  /// falta ~3 temas para que caiga una pregunta, mientras que en Ciencias
  /// Básicas 7 temas producen 10 preguntas. **Un tema de Ciencias Básicas rinde
  /// unas cuatro veces más que uno de Medicina.**
  ///
  /// Devuelve `null` si el área no tiene temas contabilizados: cuatro áreas no
  /// desarrollan el tercer nivel en el documento oficial.
  static double? topicsPerQuestion(TaxonomyNode area, {required int temas}) {
    final peso = area.peso;
    if (peso == null || peso == 0 || temas == 0) return null;
    return temas / peso;
  }
}
