import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/data/auth_repository.dart';
import '../features/auth/data/apple_signin_service.dart';
import '../features/auth/data/google_signin_service.dart';
import '../features/auth/data/mock_auth_repository.dart';
import '../features/auth/domain/auth_models.dart';
import '../features/catalog/data/catalog_repository.dart';
import '../features/catalog/domain/catalog_models.dart';
import '../features/session/data/session_repository.dart';
import '../features/session/domain/session_models.dart';
import '../features/stats/data/stats_repository.dart';
import '../features/stats/domain/stats_models.dart';
import '../features/subscription/data/subscription_repository.dart';
import '../features/subscription/domain/subscription_models.dart';
import 'config/app_config.dart';
import 'network/api_client.dart';
import 'storage/app_prefs.dart';
import 'storage/token_storage.dart';

/// Inyección de dependencias de la app.
///
/// El interruptor está en un solo sitio: [AppConfig.useMocks]. Con mocks
/// activos, ninguna pantalla llama al backend; al apagarlo, las mismas
/// pantallas hablan con la API sin que cambie una línea de UI.

// ==================== INFRAESTRUCTURA ====================

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

/// Contador que se incrementa cuando la sesión expira sin poder renovarse.
///
/// Es un contador y no un booleano para que dos expiraciones seguidas emitan
/// dos veces: con un `bool` la segunda no cambiaría el valor y nadie se
/// enteraría.
class SessionExpiredNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void notifyExpired() => state = state + 1;
}

final sessionExpiredProvider = NotifierProvider<SessionExpiredNotifier, int>(
  SessionExpiredNotifier.new,
);

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    tokenStorage: ref.watch(tokenStorageProvider),
    onSessionExpired: () =>
        ref.read(sessionExpiredProvider.notifier).notifyExpired(),
  );
});

// ==================== REPOSITORIOS ====================

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (AppConfig.useMocks) return MockAuthRepository();
  return ApiAuthRepository(
    client: ref.watch(apiClientProvider),
    tokens: ref.watch(tokenStorageProvider),
  );
});

final appPrefsProvider = Provider<AppPrefs>((ref) => AppPrefs());

final googleSignInServiceProvider = Provider<GoogleSignInService>((ref) {
  if (AppConfig.useMocks) return MockGoogleSignInService();
  return GoogleSignInServiceImpl();
});

final appleSignInServiceProvider = Provider<AppleSignInService>((ref) {
  if (AppConfig.useMocks) return MockAppleSignInService();
  return AppleSignInServiceImpl();
});

/// Si el botón de Apple tiene sentido en este dispositivo.
///
/// Fuera de iOS no se muestra: existe un flujo web, pero nadie con un Android
/// espera entrar con Apple, y es justo en iOS donde App Store lo exige.
final appleDisponibleProvider = FutureProvider<bool>((ref) {
  return ref.watch(appleSignInServiceProvider).disponible();
});

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  if (AppConfig.useMocks) return MockCatalogRepository();
  return ApiCatalogRepository(ref.watch(apiClientProvider));
});

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  if (AppConfig.useMocks) return MockSessionRepository();
  return ApiSessionRepository(ref.watch(apiClientProvider));
});

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  if (AppConfig.useMocks) return MockStatsRepository();
  return ApiStatsRepository(ref.watch(apiClientProvider));
});

/// Correos que, con mocks, entran con un estado de suscripción distinto.
///
/// El estado no viaja en el modelo `User` (lo decide el backend por
/// suscripción), así que para recorrer la app en cada estado sin backend el
/// atajo es el correo con el que se inició sesión. Mismo criterio que los
/// correos especiales de [MockAuthRepository].
///
/// Cualquier otro correo entra en `prueba_sin_iniciar`, que es como nace todo
/// usuario de verdad (RN-03 v2).
const mockEstadosPorCorreo = {
  'premium@enam.pe': SubscriptionStatus.activa,
  'gracia@enam.pe': SubscriptionStatus.enGracia,
  'probando@enam.pe': SubscriptionStatus.prueba,

  // Los dos que bloquean la app. `vencido@` es el caso corriente —se le acabó
  // el día de prueba— y `cancelado@` el de quien canceló un plan pagado.
  'vencido@enam.pe': SubscriptionStatus.expirada,
  'expirado@enam.pe': SubscriptionStatus.expirada,
  'cancelado@enam.pe': SubscriptionStatus.cancelada,
};

/// Cuánto dura la prueba (RN-03 v2).
const duracionPrueba = Duration(hours: 24);

/// Instante en que arrancó el día de prueba, o `null` si no ha empezado.
///
/// Solo tiene sentido con mocks: contra el backend real la fecha la manda el
/// servidor. Se guarda en disco para que cerrar la app no reinicie el reloj,
/// que es justo lo que haría un usuario para estirar la prueba.
class InicioPruebaNotifier extends AsyncNotifier<DateTime?> {
  @override
  Future<DateTime?> build() => ref.read(appPrefsProvider).inicioPrueba();

  /// Enciende el reloj si no lo estaba. Se llama al crear la primera sesión.
  Future<void> arrancar() async {
    if (state.value != null) return;
    final inicio = await ref.read(appPrefsProvider).marcarInicioPrueba();
    state = AsyncData(inicio);
    // La suscripción cambia de estado con esto, así que hay que releerla.
    ref.invalidate(subscriptionProvider);
  }

  /// Vuelve a dejar la prueba sin empezar. Solo para probar el flujo.
  Future<void> reiniciar() async {
    await ref.read(appPrefsProvider).reiniciarPrueba();
    state = const AsyncData(null);
    ref.invalidate(subscriptionProvider);
  }
}

final inicioPruebaProvider =
    AsyncNotifierProvider<InicioPruebaNotifier, DateTime?>(
      InicioPruebaNotifier.new,
    );

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  if (AppConfig.useMocks) {
    final email = ref.watch(currentUserProvider)?.email;

    // Los correos especiales fuerzan un estado concreto; el resto vive el
    // trial de verdad: sin empezar hasta la primera práctica, 24 h corriendo
    // desde entonces, y bloqueado al pasarse (D-02).
    final forzado = mockEstadosPorCorreo[email];
    if (forzado != null) return MockSubscriptionRepository(estado: forzado);

    return MockSubscriptionRepository(
      inicioPrueba: ref.watch(inicioPruebaProvider).value,
    );
  }
  return ApiSubscriptionRepository(ref.watch(apiClientProvider));
});

// ==================== ARRANQUE ====================

/// Lo que hay que resolver antes de salir del splash.
typedef Startup = ({bool onboardingVisto});

/// Estado de arranque de la app. `null` mientras no está resuelto.
///
/// Dos cosas conviven aquí:
///
/// 1. Si el onboarding ya se vio. El router lo necesita de forma **síncrona**
///    para decidir a dónde mandar al usuario sin sesión, así que no puede ser
///    un `FutureProvider` que se consulte en el momento de redirigir.
///
/// 2. Un tiempo mínimo en el splash. El diseño pide una animación de logo, ECG
///    y barra; leer el storage tarda ~200 ms, así que sin esto la pantalla
///    aparecía y desaparecía como un parpadeo y la animación no se veía nunca.
///    El diseño marca 2.5 s como techo; 1.8 s deja ver la animación sin que
///    se haga lento.
class StartupNotifier extends AsyncNotifier<Startup> {
  static const minimoEnSplash = Duration(milliseconds: 1800);

  @override
  Future<Startup> build() async {
    // Las dos se lanzan antes del primer await, así que corren en paralelo: la
    // espera mínima no se suma a la lectura del storage.
    final visto = ref.read(appPrefsProvider).onboardingVisto();
    final espera = Future<void>.delayed(minimoEnSplash);

    final resultado = await visto;
    await espera;
    return (onboardingVisto: resultado);
  }

  /// Marca el onboarding como visto y actualiza el estado en memoria, para que
  /// el router no vuelva a mandar ahí en la misma sesión.
  Future<void> marcarOnboardingVisto() async {
    await ref.read(appPrefsProvider).marcarOnboardingVisto();
    state = const AsyncData((onboardingVisto: true));
  }
}

final startupProvider = AsyncNotifierProvider<StartupNotifier, Startup>(
  StartupNotifier.new,
);

// ==================== ESTADO DE SESIÓN ====================

/// Estado de autenticación de la app.
sealed class AuthState {
  const AuthState();
}

/// Aún no sabemos si hay sesión: se está leyendo el storage.
final class AuthLoading extends AuthState {
  const AuthLoading();
}

final class AuthSignedOut extends AuthState {
  const AuthSignedOut();
}

final class AuthSignedIn extends AuthState {
  const AuthSignedIn(this.user);
  final User user;
}

class AuthController extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    // Si la sesión expira en cualquier momento, se recalcula el estado.
    ref.watch(sessionExpiredProvider);

    final user = await ref.read(authRepositoryProvider).currentUser();
    return user == null ? const AuthSignedOut() : AuthSignedIn(user);
  }

  /// Inicia sesión con correo y contraseña.
  ///
  /// Lanza la [Failure] del repositorio si falla, y **deja el estado en
  /// [AuthSignedOut]**, que es la verdad: unas credenciales malas no rompen el
  /// estado de sesión, simplemente no la crean.
  ///
  /// Dos cosas que parecen inocentes y rompían esto, las dos con el mismo
  /// síntoma —escribir mal la contraseña devolvía a un login en blanco, sin
  /// ningún error a la vista—:
  ///
  /// 1. `AsyncValue.guard` dejaba el estado en `AsyncError`.
  /// 2. Poner el estado en `AsyncLoading` mientras se intenta entrar.
  ///
  /// En los dos casos el router lo lee como "todavía no sé si hay sesión",
  /// manda al splash y **destruye el formulario**: al volver, la pantalla es
  /// otra instancia y el mensaje de error se fue con la anterior.
  ///
  /// El spinner del botón no se pierde por esto: lo lleva la propia pantalla
  /// con su estado local, que es donde corresponde.
  Future<void> signIn({required String email, required String password}) async {
    try {
      final user = await ref
          .read(authRepositoryProvider)
          .login(email: email, password: password);
      state = AsyncData(AuthSignedIn(user));
    } catch (_) {
      state = const AsyncData(AuthSignedOut());
      rethrow;
    }
  }

  /// Login con Google. Devuelve `false` si el usuario canceló el diálogo.
  ///
  /// Cancelar deja el estado como estaba y no propaga error: la pantalla no
  /// debe mostrar nada rojo porque alguien cerró el selector de cuentas.
  ///
  /// [aceptaTerminos] va en falso la primera vez, siempre. Si la cuenta es
  /// nueva el servidor responde `CONSENT_REQUIRED`, la pantalla enseña los
  /// términos y vuelve a llamar con `true` (RNF-06, Ley 29733). Mandarlo en
  /// `true` de entrada sería sellar un consentimiento que nadie dio, y el
  /// botón de Google vive en el login, que no tiene casilla que marcar.
  Future<bool> signInWithGoogle({bool aceptaTerminos = false}) async {
    // El diálogo nativo se abre **antes** de pasar a cargando: si se pusiera
    // antes, cancelar dejaría un spinner colgado hasta la siguiente acción.
    final String? idToken;
    try {
      idToken = await ref.read(googleSignInServiceProvider).obtenerIdToken();
    } catch (_) {
      state = const AsyncData(AuthSignedOut());
      rethrow;
    }
    if (idToken == null) return false;

    try {
      final user = await ref
          .read(authRepositoryProvider)
          .loginConGoogle(idToken, aceptaTerminos: aceptaTerminos);
      state = AsyncData(AuthSignedIn(user));
      return true;
    } catch (_) {
      // Igual que en el login por correo: el fallo se lanza para que la
      // pantalla lo muestre, y el estado vuelve a "sin sesión" para que el
      // router no la mande al splash.
      state = const AsyncData(AuthSignedOut());
      rethrow;
    }
  }

  /// Login con Apple. Devuelve `false` si el usuario canceló.
  ///
  /// [aceptaTerminos] funciona igual que en Google: falso la primera vez, y la
  /// pantalla reintenta con `true` tras enseñar los términos.
  Future<bool> signInWithApple({bool aceptaTerminos = false}) async {
    // Igual que con Google: el diálogo nativo se abre **antes** de pasar a
    // cargando, para que cancelar no deje un spinner colgado.
    final AppleCredential? credencial;
    try {
      credencial = await ref
          .read(appleSignInServiceProvider)
          .obtenerCredencial();
    } catch (_) {
      state = const AsyncData(AuthSignedOut());
      rethrow;
    }
    if (credencial == null) return false;

    try {
      final user = await ref
          .read(authRepositoryProvider)
          .loginConApple(
            identityToken: credencial.identityToken,
            nombre: credencial.nombre,
            aceptaTerminos: aceptaTerminos,
          );
      state = AsyncData(AuthSignedIn(user));
      return true;
    } catch (_) {
      state = const AsyncData(AuthSignedOut());
      rethrow;
    }
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).logout();
    // Sin esto, el selector de cuentas no vuelve a preguntar y quien comparte
    // el teléfono entraría con la cuenta del anterior de un solo toque.
    await ref.read(googleSignInServiceProvider).cerrarSesion();
    state = const AsyncData(AuthSignedOut());
  }

  /// Refresca el usuario tras editar el perfil.
  void setUser(User user) => state = AsyncData(AuthSignedIn(user));
}

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

/// El usuario actual, o `null` si no hay sesión.
final currentUserProvider = Provider<User?>((ref) {
  final auth = ref.watch(authControllerProvider).value;
  return auth is AuthSignedIn ? auth.user : null;
});

// ==================== CATÁLOGO ====================

/// Árbol del temario con el progreso del usuario: 10 áreas como raíces, cada
/// una con su subárbol. Se cachea mientras alguien lo escuche.
final catalogProvider = FutureProvider<List<CatalogNode>>((ref) {
  return ref.watch(catalogRepositoryProvider).tree();
});

// ==================== ESTADÍSTICAS ====================

final dashboardProvider = FutureProvider<DashboardStats>((ref) {
  return ref.watch(statsRepositoryProvider).dashboard();
});

// ==================== SUSCRIPCIÓN Y ACCESO ====================

/// La suscripción del usuario. Es de dónde sale **todo** el control de acceso
/// de la UI (RN-03 v2).
///
/// Se recarga sola cuando cambia el usuario, y hay que invalidarla tras pagar
/// y al volver de segundo plano: el día de prueba puede haber vencido mientras
/// la app estaba cerrada.
final subscriptionProvider = FutureProvider<Subscription>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) throw StateError('Sin sesión: no hay suscripción');
  return ref.watch(subscriptionRepositoryProvider).current();
});

// No hay `plansProvider` ni `planProvider`, y no es un olvido: la app no lista
// planes ni enseña precios. Las tiendas no dejan cobrar dentro sin su comisión,
// así que el catálogo y el importe viven en la web y en el correo, que además
// es donde pueden cambiar sin publicar una versión nueva.
//
// El plan que el usuario YA tiene llega dentro de `GET /subscription`, y de ahí
// lo saca «Mi suscripción» para poder decir su nombre y hasta cuándo vale.

// No hay un `tieneAccesoProvider` a propósito. Ninguna pantalla decide por su
// cuenta si el usuario puede estar ahí: eso vive en la guarda del router
// (`_rutasSinAcceso`). Un getter suelto invita a repartir la regla por la app y
// a que alguna pantalla se olvide de aplicarla.

// ==================== SESIÓN REANUDABLE ====================

/// Resumen de la sesión interrumpida que el usuario puede retomar (RF-15).
typedef ResumableSession = ({
  String sessionId,
  bool esSimulacro,
  String titulo,
  String detalle,
});

/// Las sesiones a medio hacer, de `GET /sessions/open`.
final sesionesAbiertasProvider = FutureProvider<List<OpenSession>>((ref) {
  // Sin sesión no hay nada que retomar, y preguntarlo daría un 401.
  if (ref.watch(currentUserProvider) == null) return Future.value(const []);
  return ref.watch(sessionRepositoryProvider).openSessions();
});

/// La sesión que el inicio propone retomar, o `null` si no hay ninguna.
///
/// Sale del servidor. Antes era una tupla escrita en el código —"Problemas
/// infecciosos · pregunta 7 de 20"— que aparecía siempre con mocks y nunca sin
/// ellos: una tarjeta que invitaba a continuar algo que no existía.
///
/// El texto lo compone el cliente y no el servidor: es quien sabe de plurales y
/// de cómo se ve en pantalla, y un backend que manda texto de interfaz obliga a
/// desplegarlo para cambiar una palabra.
final resumableSessionProvider = Provider<ResumableSession?>((ref) {
  final abiertas = ref.watch(sesionesAbiertasProvider).value;
  if (abiertas == null || abiertas.isEmpty) return null;

  // La más reciente: es la que la persona recuerda haber dejado a medias.
  final sesion = abiertas.reduce(
    (a, b) => a.iniciadaEn.isAfter(b.iniciadaEn) ? a : b,
  );

  return (
    sessionId: sesion.id,
    esSimulacro: sesion.esSimulacro,
    titulo: sesion.esSimulacro
        ? 'Termina tu simulacro'
        : 'Continuar donde quedaste',
    detalle: 'Pregunta ${sesion.respondidas + 1} de ${sesion.totalPreguntas}',
  );
});

// ==================== TEMA ====================

/// Tema elegido por el usuario. Arranca en `system` y se persiste en
/// `shared_preferences` (no es dato sensible) cuando exista la pantalla de
/// ajustes.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  void set(ThemeMode mode) => state = mode;
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
