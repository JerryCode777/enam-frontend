import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/data/auth_repository.dart';
import '../features/auth/data/mock_auth_repository.dart';
import '../features/auth/domain/auth_models.dart';
import '../features/catalog/data/catalog_repository.dart';
import '../features/catalog/domain/catalog_models.dart';
import '../features/session/data/session_repository.dart';
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

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  if (AppConfig.useMocks) return MockCatalogRepository();
  return ApiCatalogRepository(ref.watch(apiClientProvider));
});

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  if (AppConfig.useMocks) return MockSessionRepository();
  return ApiSessionRepository(ref.watch(apiClientProvider));
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

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).logout();
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

/// Áreas con el progreso del usuario. Se cachea mientras alguien la escuche.
final areasProvider = FutureProvider<List<Area>>((ref) {
  return ref.watch(catalogRepositoryProvider).areas();
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
