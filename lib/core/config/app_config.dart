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

import 'package:flutter/foundation.dart' show kReleaseMode;

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
  static const bool _mocksPedidos = bool.fromEnvironment(
    'USE_MOCKS',
    defaultValue: true,
  );

  /// Datos falsos en vez del backend. **Nunca en una build de release.**
  ///
  /// El flag por sí solo no basta: una build para la tienda mal parametrizada
  /// saldría con preguntas inventadas, y nadie lo notaría hasta que un usuario
  /// estudiara con ellas. `kReleaseMode` lo hace imposible por construcción, no
  /// por disciplina.
  ///
  /// La app hermana tiene la bandera equivalente en `false` en los dos
  /// entornos, pero su servicio de suscripción **cae a datos falsos cuando la
  /// red falla** si alguien la enciende: un fallo de red se convertiría en
  /// acceso premium regalado. Aquí eso no puede pasar ni queriendo.
  static const bool useMocks = _mocksPedidos && !kReleaseMode;

  /// ID de cliente **web** de OAuth del proyecto de Google Cloud.
  ///
  /// En Android no se usa el client ID de Android: se manda el de tipo web como
  /// `serverClientId`, y así el `idToken` que devuelve Google trae ese `aud`,
  /// que es el que el backend puede verificar. Con el de Android el token no
  /// serviría para nada del lado servidor.
  ///
  /// **Viene con el valor del proyecto puesto, y no es un descuido.** Estuvo
  /// vacío, y el síntoma no se parecía en nada a la causa: al apagar los mocks
  /// para probar contra el servidor, el botón de Google **desaparecía**. Nadie
  /// relaciona «quité los datos falsos» con «se fue un botón», así que se
  /// perdían tardes en algo que era un parámetro de compilación que solo tenía
  /// quien hizo la última build.
  ///
  /// Un client ID de OAuth **no es un secreto**: viaja dentro de cada copia de
  /// la app y se saca de un `.apk` en dos minutos. Lo que protege el acceso es
  /// la huella SHA-1 más el nombre del paquete en Android, y el bundle ID en
  /// iOS, y eso vive del lado de Google. Lo que sí sería secreto —el *client
  /// secret*, una clave de cuenta de servicio— no aparece por aquí.
  ///
  /// Se puede sobreescribir con `--dart-define=GOOGLE_SERVER_CLIENT_ID=…` para
  /// apuntar a otro proyecto de Google Cloud.
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '776242647673-ftoserm7trib6ab6c47dn2ogholhavfj.apps.googleusercontent.com',
  );

  /// Si el botón de Google tiene sentido en esta build.
  ///
  /// Con el client ID por defecto esto es cierto siempre, y ese es el objetivo:
  /// que `flutter run` a secas enseñe el botón.
  ///
  /// Lo que se cede a cambio: antes el botón se escondía cuando no podía
  /// funcionar. Ahora, si alguien compila Android con un keystore cuya huella
  /// SHA-1 no esté registrada en Google Cloud, verá el botón y fallará al
  /// tocarlo en vez de no verlo. Es el precio de que no tropiece todo el que
  /// clone el repositorio, y el fallo al tocar al menos dice qué pasa; un botón
  /// que no está no dice nada.
  static bool get googleSignInHabilitado =>
      useMocks || googleServerClientId.isNotEmpty;

  /// Dónde se paga: la web de ENAM Prep.
  ///
  /// Apunta a la web desplegada, no al servidor local: es una dirección que
  /// el usuario abre en su navegador, así que un `localhost` por defecto
  /// significa un enlace roto en cuanto la app sale del equipo de quien
  /// programa. Para desarrollar contra la web local:
  /// `--dart-define=WEB_URL=http://localhost:5173`.
  static const String webUrl = String.fromEnvironment(
    'WEB_URL',
    defaultValue: 'https://enamprep.com',
  );

  /// La pantalla de activación de la web.
  ///
  /// Es la única dirección de la web que la app enlaza, y **no es `/planes` a
  /// propósito**. La guía 3.1.1 de App Store prohíbe enlazar a un mecanismo de
  /// compra externo; lo que sí tolera —y lo que el *External Link Account
  /// Entitlement* contempla— es llevar a **gestionar la cuenta**. Una lista de
  /// precios es inequívocamente lo primero; una pantalla que pregunta a qué
  /// vienes, no. Google Play tiene una política equivalente, más tolerante en
  /// la práctica pero igual de explícita en el papel.
  ///
  /// Por eso tampoco lleva al inicio: quien viene de la app llega **sin
  /// sesión** y acabaría en el splash y de ahí en el login, escribiendo una
  /// contraseña en el teclado del móvil sin ninguna pista de a qué había ido.
  /// `/activar` es la única que sabe recibir a alguien en frío.
  ///
  /// El `origen` no lo usa el servidor: viaja para poder medir por separado los
  /// dos caminos de compra.
  static String get urlActivar => '$webUrl/activar?origen=ios';

  /// Fuerza la variante de tienda de la pantalla de bloqueo, para poder ver
  /// las dos sin cambiar de dispositivo:
  /// `--dart-define=TIENDA=apple` o `--dart-define=TIENDA=android`.
  ///
  /// Vacío = la real del dispositivo.
  static const String tiendaForzada = String.fromEnvironment('TIENDA');

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
