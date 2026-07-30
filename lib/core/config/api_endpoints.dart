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
  static const String refresh = '/auth/refresh';
  static const String forgotPassword = '/auth/forgot';
  static const String resetPassword = '/auth/reset';

  // ---------- Perfil ----------
  static const String me = '/me';

  // ---------- Catálogo ----------
  /// Taxonomía completa con el progreso del usuario.
  static const String catalogAreas = '/catalog/areas';

  // ---------- Sesiones (Módulos 3 y 4) ----------
  static const String practiceSession = '/sessions/practice';
  static const String simulacroSession = '/sessions/simulacro';

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

  // ---------- Suscripciones y pagos (Módulo 6) ----------
  static const String plans = '/plans';
  static const String checkout = '/checkout';
  static const String subscription = '/subscription';
}
