import 'package:enam_app/core/providers.dart';
import 'package:enam_app/features/auth/domain/auth_models.dart';
import 'package:enam_app/features/stats/presentation/ranking_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Los resultados de una persona no pueden aparecer en la cuenta de otra.
///
/// El dashboard y el ranking se cacheaban mientras la app estuviera abierta y
/// no dependían del usuario: si alguien cerraba sesión y otra persona entraba
/// en el mismo teléfono, el inicio le enseñaba las cifras de la anterior hasta
/// que algo forzara una recarga.
void main() {
  test('cambiar de usuario tira el dashboard y el ranking del anterior', () {
    final c = ProviderContainer(
      overrides: [authControllerProvider.overrideWith(_AuthManual.new)],
    );
    addTearDown(c.dispose);

    // Se escuchan para que el contenedor los mantenga vivos, como la pantalla.
    c.listen(dashboardProvider, (_, _) {});
    c.listen(rankingProvider, (_, _) {});

    final auth = c.read(authControllerProvider.notifier) as _AuthManual;
    auth.entrar('ana');
    final repoDeAna = c.read(statsRepositoryProvider);

    auth.entrar('beto');
    final repoDeBeto = c.read(statsRepositoryProvider);

    expect(identical(repoDeAna, repoDeBeto), isFalse);
    // Recién cambiado, lo que haya es de Beto o no hay nada todavía.
    expect(c.read(dashboardProvider).isLoading, isTrue);
    expect(c.read(rankingProvider).isLoading, isTrue);
  });

  test('editar el perfil no tira las estadísticas', () {
    final c = ProviderContainer(
      overrides: [authControllerProvider.overrideWith(_AuthManual.new)],
    );
    addTearDown(c.dispose);

    final auth = c.read(authControllerProvider.notifier) as _AuthManual;
    auth.entrar('ana');
    final antes = c.read(statsRepositoryProvider);

    auth.entrar('ana', nombre: 'Ana María');
    expect(identical(antes, c.read(statsRepositoryProvider)), isTrue);
  });
}

class _AuthManual extends AuthController {
  @override
  Future<AuthState> build() async => const AuthSignedOut();

  void entrar(String id, {String nombre = 'Alguien'}) => state = AsyncData(
    AuthSignedIn(
      User(id: id, email: '$id@test.pe', nombre: nombre, emailVerificado: true),
    ),
  );
}
