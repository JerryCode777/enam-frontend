/// Configuración por entorno.
///
/// El entorno se elige en **tiempo de compilación** con `--dart-define`, no
/// editando este archivo:
///
/// ```sh
/// flutter run --dart-define=ENV=dev
/// flutter build apk --release --dart-define=ENV=prod
/// ```
///
/// Motivo: en la app hermana el entorno era una `const` que había que editar y
/// recompilar, y es fácil publicar apuntando al backend equivocado. Aquí el
/// entorno viaja en el comando de build, así que CI puede garantizarlo.
///
/// El default es `dev`: si alguien olvida el flag, apunta a local y falla
/// ruidosamente, en vez de golpear producción por accidente.
library;

enum Environment {
  dev,
  staging,
  prod;

  static Environment fromName(String name) => switch (name) {
    'prod' || 'production' => Environment.prod,
    'staging' || 'stg' => Environment.staging,
    _ => Environment.dev,
  };
}

abstract final class AppConfig {
  static const String _envName = String.fromEnvironment('ENV', defaultValue: 'dev');

  static final Environment environment = Environment.fromName(_envName);

  /// Permite sobrescribir la URL del backend sin recompilar por entorno.
  /// Útil para apuntar a la máquina de un compañero: `--dart-define=API_URL=...`
  static const String _apiUrlOverride = String.fromEnvironment('API_URL');

  static String get apiBaseUrl {
    if (_apiUrlOverride.isNotEmpty) return _apiUrlOverride;
    return switch (environment) {
      // 10.0.2.2 es como el emulador de Android ve el localhost del host.
      Environment.dev => 'http://10.0.2.2:8080',
      Environment.staging => 'https://staging-api.enamprep.pe',
      Environment.prod => 'https://api.enamprep.pe',
    };
  }

  /// Ruta base de la API versionada (SSD §6).
  static const String apiBasePath = '/api/v1';

  static String get apiUrl => '$apiBaseUrl$apiBasePath';

  static bool get isDev => environment == Environment.dev;
  static bool get isProd => environment == Environment.prod;

  /// Usar repositorios con datos falsos en vez de llamar al backend.
  ///
  /// Mientras el backend no exista, esto arranca en `true` en dev. Se apaga con
  /// `--dart-define=USE_MOCKS=false` para probar contra un backend real.
  static const bool useMocks = bool.fromEnvironment(
    'USE_MOCKS',
    defaultValue: true,
  );

  /// Registrar peticiones HTTP en consola. Nunca en producción: los logs
  /// llevarían tokens y contenido premium.
  static bool get logHttp => !isProd;

  /// Timeouts de red. RNF-01 pide p95 < 300 ms, así que 20 s ya es un fallo.
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);

  /// Cada cuánto se autoguarda el progreso de un simulacro.
  /// El SSD lo pide como mitigación al riesgo de caída durante un nacional.
  static const Duration examAutosaveInterval = Duration(seconds: 30);
}
