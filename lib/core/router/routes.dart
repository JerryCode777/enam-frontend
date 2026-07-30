/// Rutas de la app, en un solo sitio.
///
/// Se usan las constantes, nunca strings sueltos: un typo en una ruta escrita a
/// mano no lo detecta el compilador.
abstract final class Routes {
  // ---------- Arranque y onboarding ----------
  static const splash = '/';
  static const onboarding = '/onboarding';

  // ---------- Autenticación (Módulo 1) ----------
  static const login = '/login';
  static const register = '/registro';
  static const verifyEmail = '/verificar-correo';
  static const forgotPassword = '/recuperar-contrasena';
  static const resetPassword = '/nueva-contrasena';
  static const completeProfile = '/completar-perfil';

  // ---------- Núcleo (los 4 destinos de la barra inferior) ----------
  static const home = '/inicio';
  static const temario = '/temario';
  static const stats = '/progreso';

  // ---------- Temario (RF-06) ----------
  /// Sub áreas de un área. Recibe el id del nodo.
  static const temarioArea = '/temario/:id';
  static String temarioAreaOf(String id) => '/temario/$id';

  /// Temas de una sub área.
  static const temarioSubArea = '/temario/:id/temas';
  static String temarioSubAreaOf(String id) => '/temario/$id/temas';

  static const temarioSearch = '/temario/buscar';

  /// Dónde invertir el tiempo, según la densidad del temario.
  static const studyPriority = '/progreso/prioridades';

  // ---------- Práctica (Módulo 3) ----------
  static const practiceConfig = '/practica/configurar';
  static const practiceAreas = '/practica/areas';
  static const markedQuestions = '/practica/marcadas';

  /// Sesión de práctica en curso. Recibe el id de sesión.
  static const practiceSession = '/practica/sesion/:id';
  static String practiceSessionOf(String id) => '/practica/sesion/$id';

  static const practiceResults = '/practica/resultados/:id';
  static String practiceResultsOf(String id) => '/practica/resultados/$id';

  // ---------- Simulacros (Módulo 4) ----------
  static const simulacroSelection = '/simulacro';
  static const simulacroInstructions = '/simulacro/instrucciones';
  static const simulacroHistory = '/simulacro/historial';

  static const simulacroSession = '/simulacro/sesion/:id';
  static String simulacroSessionOf(String id) => '/simulacro/sesion/$id';

  static const simulacroNavigation = '/simulacro/sesion/:id/navegacion';
  static String simulacroNavigationOf(String id) =>
      '/simulacro/sesion/$id/navegacion';

  static const simulacroResults = '/simulacro/resultados/:id';
  static String simulacroResultsOf(String id) => '/simulacro/resultados/$id';

  static const simulacroReview = '/simulacro/revision/:id';
  static String simulacroReviewOf(String id) => '/simulacro/revision/$id';

  static const nationalMock = '/simulacro/nacional';

  // ---------- Ranking (Módulo 5) ----------
  static const ranking = '/ranking';

  // ---------- Suscripción (Módulo 6) ----------
  static const plans = '/planes';
  static const paywall = '/premium';
  static const checkout = '/pago';
  static const paymentResult = '/pago/resultado';
  static const mySubscription = '/mi-suscripcion';

  // ---------- Offline (Módulo 7) ----------
  static const downloads = '/descargas';
  static const syncStatus = '/sincronizacion';

  // ---------- Perfil y ajustes ----------
  static const profile = '/perfil';
  static const editProfile = '/perfil/editar';
  static const changePassword = '/perfil/contrasena';
  static const settings = '/ajustes';
  static const reminders = '/ajustes/recordatorios';
  static const deleteAccount = '/ajustes/eliminar-cuenta';
  static const help = '/ayuda';
  static const terms = '/terminos';

  // ---------- Sistema ----------
  static const maintenance = '/mantenimiento';
  static const updateRequired = '/actualizar';
  static const offline = '/sin-conexion';
}
