/// Endpoints de la API, según SSD-ENAM-001 §6.
///
/// Rutas relativas a [AppConfig.apiUrl]. Todo endpoint nuevo se agrega aquí, no
/// escrito a mano en un repositorio.
abstract final class ApiEndpoints {
  // ---------- Autenticación (Módulo 1) ----------
  static const String register = '/auth/register';
  static const String login = '/auth/login';

  /// Canje del `idToken` de Google por una sesión propia.
  static const String google = '/auth/google';

  /// Canje del `identityToken` de Apple por una sesión propia.
  static const String apple = '/auth/apple';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String forgotPassword = '/auth/forgot';
  static const String resetPassword = '/auth/reset';

  /// Reenvía el enlace de verificación de correo. **No** es `forgotPassword`:
  /// ese manda un correo de recuperación de contraseña.
  static const String resendVerification = '/auth/resend-verification';

  // ---------- Perfil ----------
  //
  // El mismo camino sirve para leer (GET), editar (PATCH) y eliminar (DELETE,
  // RNF-06) la cuenta.
  static const String me = '/me';

  // ---------- Catálogo ----------
  /// Taxonomía completa con el progreso del usuario.
  static const String catalogAreas = '/catalog/areas';

  // ---------- Sesiones (Módulos 3 y 4) ----------
  static const String practiceSession = '/sessions/practice';
  static const String simulacroSession = '/sessions/simulacro';

  /// Sesiones a medias. Alimenta el "retomar donde quedaste" del inicio (RF-15).
  static const String openSessions = '/sessions/open';

  /// Preguntas marcadas de todas las sesiones (RF-14).
  ///
  /// **Todavía no existe en el backend.** La pantalla 4.5 sale del mock hasta
  /// que se implemente.
  static const String markedQuestions = '/me/marked';

  static String session(String id) => '/sessions/$id';
  static String sessionAnswers(String id) => '/sessions/$id/answers';
  static String sessionSubmit(String id) => '/sessions/$id/submit';

  // ---------- Estadísticas y ranking (Módulo 5) ----------
  static const String statsDashboard = '/stats/dashboard';
  static const String rankingGeneral = '/rankings/general';

  static String rankingByMock(String mockId) => '/rankings/$mockId';

  // ---------- Modo offline (Módulo 7) ----------
  static String offlinePackage(String areaId) => '/offline/packages/$areaId';
  static const String offlineSync = '/offline/sync';

  // ---------- Suscripciones (Módulo 6) ----------
  //
  // No hay `/plans` ni `/checkout`: la app no lista precios ni cobra. Las
  // tiendas no lo permiten sin su comisión, así que el pago ocurre en la web
  // (modelo Netflix). Los dos existen en el backend y los usa el cliente web.
  static const String subscription = '/subscription';
  static const String cancelSubscription = '/subscription/cancel';

  /// Manda al correo el enlace para completar la suscripción en la web.
  ///
  /// Es el camino de **Android**. El enlace abre sesión sin contraseña, vive 15
  /// minutos y sirve una sola vez. Público: lo comparte con la web, donde quien
  /// lo usa todavía no tiene sesión, y por eso el correo va en el cuerpo.
  static const String activationLink = '/billing/activation-link';

  // ---------- Simulacros nacionales (RF-19) ----------
  static const String mockExams = '/mock-exams';

  static String joinMockExam(String mockId) => '/mock-exams/$mockId/join';
}
