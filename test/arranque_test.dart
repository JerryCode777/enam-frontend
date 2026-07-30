import 'package:enam_app/core/providers.dart';
import 'package:enam_app/core/router/app_router.dart';
import 'package:enam_app/core/router/routes.dart';
import 'package:enam_app/core/storage/app_prefs.dart';
import 'package:enam_app/features/auth/data/auth_repository.dart';
import 'package:enam_app/features/auth/data/mock_auth_repository.dart';
import 'package:enam_app/features/auth/domain/auth_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// El onboarding existía como archivo y **ninguna ruta llegaba a él**: el
/// router mandaba siempre al login. Y el splash duraba lo que tardaba leer el
/// storage (~200 ms), así que su animación no se veía nunca.
///
/// Estos tests fijan el recorrido que pide el diseño: sin sesión, onboarding la
/// primera vez y login a partir de ahí; y el splash con un tiempo mínimo.
void main() {
  late _PrefsFalsas prefs;

  setUp(() => prefs = _PrefsFalsas());

  ProviderContainer contenedor({AuthRepository? repo}) {
    final c = ProviderContainer(
      overrides: [
        appPrefsProvider.overrideWithValue(prefs),
        authRepositoryProvider.overrideWithValue(repo ?? MockAuthRepository()),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  group('Arranque', () {
    test('el splash espera un mínimo aunque el storage responda al instante',
        () async {
      // Sin esto la pantalla aparecía y desaparecía como un parpadeo.
      final c = contenedor();
      final reloj = Stopwatch()..start();

      await c.read(startupProvider.future);
      reloj.stop();

      expect(
        reloj.elapsed,
        greaterThanOrEqualTo(
          StartupNotifier.minimoEnSplash - const Duration(milliseconds: 60),
        ),
      );
    });

    test('la espera mínima y la lectura corren en paralelo, no en serie',
        () async {
      prefs.latencia = const Duration(milliseconds: 300);
      final c = contenedor();
      final reloj = Stopwatch()..start();

      await c.read(startupProvider.future);
      reloj.stop();

      // Si fueran en serie tardaría mínimo + 300 ms.
      expect(
        reloj.elapsed,
        lessThan(StartupNotifier.minimoEnSplash + const Duration(milliseconds: 250)),
      );
    });

    test('marcar el onboarding como visto se persiste', () async {
      final c = contenedor();
      await c.read(startupProvider.future);

      await c.read(startupProvider.notifier).marcarOnboardingVisto();

      expect(c.read(startupProvider).requireValue.onboardingVisto, isTrue);
      expect(await prefs.onboardingVisto(), isTrue);
    });
  });

  group('Recorrido de arranque, sin sesión', () {
    test('la primera vez va al onboarding', () async {
      final c = contenedor();
      await c.read(startupProvider.future);
      await c.read(authControllerProvider.future);

      expect(destino(c, desde: Routes.splash), Routes.onboarding);
    });

    test('la segunda vez va al login', () async {
      prefs.visto = true;
      final c = contenedor();
      await c.read(startupProvider.future);
      await c.read(authControllerProvider.future);

      expect(destino(c, desde: Routes.splash), Routes.login);
    });

    test('con el onboarding ya visto, entrar a esa ruta rebota al login',
        () async {
      prefs.visto = true;
      final c = contenedor();
      await c.read(startupProvider.future);
      await c.read(authControllerProvider.future);

      expect(destino(c, desde: Routes.onboarding), Routes.login);
    });

    test('el registro y el login siguen siendo alcanzables', () async {
      final c = contenedor();
      await c.read(startupProvider.future);
      await c.read(authControllerProvider.future);

      expect(destino(c, desde: Routes.register), isNull);
      expect(destino(c, desde: Routes.login), isNull);
    });

    test('una ruta privada manda al login', () async {
      final c = contenedor();
      await c.read(startupProvider.future);
      await c.read(authControllerProvider.future);

      expect(destino(c, desde: Routes.home), Routes.login);
    });
  });

  group('Recorrido de arranque, con sesión', () {
    test('con perfil completo va al home, sin pasar por el onboarding',
        () async {
      final c = contenedor(repo: _RepoConSesion());
      await c.read(startupProvider.future);
      await c.read(authControllerProvider.future);

      expect(destino(c, desde: Routes.splash), Routes.home);
      // Aunque nunca se haya visto el onboarding: quien ya tiene cuenta no
      // necesita que le presenten la app.
      expect(prefs.visto, isFalse);
      expect(destino(c, desde: Routes.onboarding), Routes.home);
    });

    test('mientras el arranque no resuelve, todo se queda en el splash',
        () async {
      final c = contenedor();
      // Sin await: el arranque sigue pendiente.
      c.read(startupProvider);
      await c.read(authControllerProvider.future);

      expect(destino(c, desde: Routes.home), Routes.splash);
      expect(destino(c, desde: Routes.splash), isNull);
    });
  });
}

/// Ejecuta la guarda del router para una ruta dada.
String? destino(ProviderContainer c, {required String desde}) => decidirDestino(
  auth: c.read(authControllerProvider),
  startup: c.read(startupProvider),
  here: desde,
);

class _PrefsFalsas implements AppPrefs {
  bool visto = false;
  Duration latencia = Duration.zero;

  @override
  Future<bool> onboardingVisto() async {
    if (latencia > Duration.zero) await Future<void>.delayed(latencia);
    return visto;
  }

  @override
  Future<void> marcarOnboardingVisto() async => visto = true;
}

/// Usuario con sesión válida y perfil completo.
class _RepoConSesion extends MockAuthRepository {
  @override
  Future<User?> currentUser() async => User(
    id: 'u1',
    email: 'a@b.pe',
    nombre: 'Ana',
    emailVerificado: true,
    universidad: 'UNSA',
    condicion: StudentCondition.interno,
    fechaObjetivo: DateTime(2026, 12, 1),
  );
}
