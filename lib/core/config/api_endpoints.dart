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

  /// Activa la cuenta con el código de 6 dígitos del correo (RF-01).
  static const String verifyCode = '/auth/verify-code';

  /// Cambiar la contraseña estando dentro. Distinto de [resetPassword], que es
  /// para quien NO puede entrar.
  static const String changePassword = '/me/password';

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
  // No hay `/plans` ni `/checkout`: la app no lista precios propios ni cobra
  // con nuestra pasarela. En iPhone se cobra con el sistema de Apple, que pone
  // sus propios precios; en Android el pago sigue ocurriendo en la web, porque
  // Google es más tolerante y así se evita su comisión.
  static const String subscription = '/subscription';
  static const String cancelSubscription = '/subscription/cancel';

  /// Canjea una compra de la App Store por acceso.
  ///
  /// Recibe la transacción firmada de StoreKit 2. Va con sesión: la compra la
  /// hace Apple contra un Apple ID, y esto es lo único que la ata a una cuenta
  /// nuestra.
  static const String verificarCompraApple = '/subscription/apple/verify';

  /// Manda al correo el enlace para completar la suscripción en la web.
  ///
  /// Es el camino de **Android**. El enlace abre sesión sin contraseña, vive 15
  /// minutos y sirve una sola vez. Público: lo comparte con la web, donde quien
  /// lo usa todavía no tiene sesión, y por eso el correo va en el cuerpo.
  static const String activationLink = '/billing/activation-link';

  /// El mismo enlace, pero devuelto a quien ya tiene sesión en vez de enviado
  /// por correo. Es el camino de Android (ver `opciones_de_pago.dart`).
  static const String activationLinkDirect =
      '/billing/activation-link/direct';

  // ---------- Exámenes pasados (RF-52) ----------
  //
  // Exámenes ENAM reales de años anteriores. El servidor manda todo: nombre,
  // año, preguntas, alternativas y explicaciones.
  //
  // `/past-exams`, no `/exams`: esta ruta estaba escrita a mano contra un
  // contrato imaginado y contra el servidor devolvía 404. El cliente web usa
  // la buena desde el principio.
  static const String pastExams = '/past-exams';

  static String startPastExam(String examId) => '/past-exams/$examId/start';

  // ---------- Simulacros nacionales (RF-19) ----------
  static const String mockExams = '/mock-exams';

  static String joinMockExam(String mockId) => '/mock-exams/$mockId/join';
}
