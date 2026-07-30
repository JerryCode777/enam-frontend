import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/data/auth_repository.dart';
import '../features/auth/data/google_signin_service.dart';
import '../features/auth/data/mock_auth_repository.dart';
import '../features/auth/domain/auth_models.dart';
import '../features/catalog/data/catalog_repository.dart';
import '../features/catalog/domain/catalog_models.dart';
import '../features/session/data/session_repository.dart';
import '../features/stats/data/stats_repository.dart';
import '../features/stats/domain/stats_models.dart';
import 'config/app_config.dart';
import 'network/api_client.dart';
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

final googleSignInServiceProvider = Provider<GoogleSignInService>((ref) {
  if (AppConfig.useMocks) return MockGoogleSignInService();
  return GoogleSignInServiceImpl();
});

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  if (AppConfig.useMocks) return MockCatalogRepository();
  return ApiCatalogRepository(ref.watch(apiClientProvider));
});

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  if (AppConfig.useMocks) return MockSessionRepository();
  return ApiSessionRepository(ref.watch(apiClientProvider));
});

/// Correo que, con mocks, entra como usuario Premium.
///
/// El plan no viaja en el modelo `User` (lo decide el backend por
/// suscripción), así que para revisar la app en premium sin backend el atajo
/// es el correo con el que se inició sesión. Mismo criterio que los correos
/// especiales de [MockAuthRepository].
const mockPremiumEmail = 'premium@enam.pe';

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  if (AppConfig.useMocks) {
    final email = ref.watch(currentUserProvider)?.email;
    return MockStatsRepository(esFree: email != mockPremiumEmail);
  }
  return ApiStatsRepository(ref.watch(apiClientProvider));
});

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

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = await ref
          .read(authRepositoryProvider)
          .login(email: email, password: password);
      return AuthSignedIn(user);
    });
  }

  /// Login con Google. Devuelve `false` si el usuario canceló el diálogo.
  ///
  /// Cancelar deja el estado como estaba y no propaga error: la pantalla no
  /// debe mostrar nada rojo porque alguien cerró el selector de cuentas.
  Future<bool> signInWithGoogle() async {
    // El diálogo nativo se abre **antes** de pasar a cargando: si se pusiera
    // antes, cancelar dejaría un spinner colgado hasta la siguiente acción.
    final String? idToken;
    try {
      idToken = await ref.read(googleSignInServiceProvider).obtenerIdToken();
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
    if (idToken == null) return false;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = await ref
          .read(authRepositoryProvider)
          .loginConGoogle(idToken!);
      return AuthSignedIn(user);
    });
    return !state.hasError;
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

// ==================== SESIÓN REANUDABLE ====================

/// Resumen de la sesión interrumpida que el usuario puede retomar (RF-15).
typedef ResumableSession = ({String sessionId, String titulo, String detalle});

/// `null` cuando no hay ninguna sesión a medias.
///
/// Hoy siempre devuelve `null`: el endpoint que lista sesiones abiertas no está
/// en el contrato todavía. Cuando exista, esto lo consulta y el Home cambia solo.
final resumableSessionProvider = Provider<ResumableSession?>((ref) => null);

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
