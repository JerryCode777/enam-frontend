import 'package:enam_app/core/providers.dart';
import 'package:enam_app/core/theme/app_theme.dart';
import 'package:enam_app/features/auth/data/auth_repository.dart';
import 'package:enam_app/features/auth/data/google_signin_service.dart';
import 'package:enam_app/features/auth/data/mock_auth_repository.dart';
import 'package:enam_app/features/auth/domain/auth_models.dart';
import 'package:enam_app/shared/widgets/social_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// El login con Google tiene un camino que es fácil de romper: cancelar.
///
/// Si cancelar se tratara como error, el usuario que cierra el selector de
/// cuentas vería un mensaje rojo sin haber hecho nada mal; y si el estado se
/// pusiera en cargando antes de abrir el diálogo, cancelar dejaría un spinner
/// colgado. Estos tests fijan las dos cosas.
void main() {
  /// Servicio de dispositivo controlable desde el test.
  late _FakeGoogle google;

  setUp(() => google = _FakeGoogle());

  ProviderContainer contenedor({AuthRepository? repo}) {
    final c = ProviderContainer(
      overrides: [
        googleSignInServiceProvider.overrideWithValue(google),
        if (repo != null) authRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  group('Controlador', () {
    test('un login correcto deja la sesión iniciada', () async {
      final c = contenedor();
      await c.read(authControllerProvider.future);

      // Con consentimiento: el mock rechaza sin él igual que el servidor, que
      // solo lo exige cuando la cuenta es nueva (RNF-06, Ley 29733). El
      // reintento tras enseñar los términos lo hace la pantalla de login.
      final ok = await c
          .read(authControllerProvider.notifier)
          .signInWithGoogle(aceptaTerminos: true);

      expect(ok, isTrue);
      expect(c.read(authControllerProvider).value, isA<AuthSignedIn>());
      expect(google.tokensPedidos, 1);
    });

    test('cancelar no es error y no deja la sesión iniciada', () async {
      google.idToken = null; // El usuario cerró el selector de cuentas.
      final c = contenedor();
      await c.read(authControllerProvider.future);

      final ok = await c
          .read(authControllerProvider.notifier)
          .signInWithGoogle();

      expect(ok, isFalse);
      // Ni error ni cargando: la pantalla tiene que quedar exactamente igual
      // que antes de tocar el botón.
      expect(c.read(authControllerProvider).hasError, isFalse);
      expect(c.read(authControllerProvider).isLoading, isFalse);
      expect(c.read(authControllerProvider).value, isA<AuthSignedOut>());
    });

    test('si el canje falla, lanza y deja la sesión sin iniciar', () async {
      // El fallo se lanza en vez de quedarse en el estado: así la pantalla lo
      // puede enseñar. Y el estado vuelve a "sin sesión", que es la verdad —
      // dejarlo en `AsyncError` hacía que el router lo leyera como "todavía no
      // sé si hay sesión" y mandara al splash, desmontando el login antes de
      // que el usuario viera ningún error.
      final c = contenedor(repo: _RepoQueFalla());
      await c.read(authControllerProvider.future);

      await expectLater(
        c.read(authControllerProvider.notifier).signInWithGoogle(),
        throwsA(isA<Exception>()),
      );

      expect(c.read(authControllerProvider).hasError, isFalse);
      expect(c.read(authControllerProvider).value, isA<AuthSignedOut>());
    });

    test('cerrar sesión también olvida la cuenta de Google', () async {
      // Sin esto, quien comparte el teléfono entraría con la cuenta del
      // anterior de un solo toque.
      final c = contenedor();
      await c.read(authControllerProvider.future);
      await c
          .read(authControllerProvider.notifier)
          .signInWithGoogle(aceptaTerminos: true);

      await c.read(authControllerProvider.notifier).signOut();

      expect(google.sesionesCerradas, 1);
    });
  });

  group('Botón', () {
    Widget wrap(Widget child) => MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: child),
    );

    testWidgets('muestra el logo a color, no un icono teñido', (tester) async {
      // Las condiciones de marca de Google no permiten recolorear la G. Si
      // alguien la cambia por un Icon, esto lo detecta.
      await tester.pumpWidget(wrap(GoogleButton(onPressed: () {})));
      await tester.pumpAndSettle();

      expect(find.byType(Icon), findsNothing);
      expect(find.text('Google'), findsOneWidget);
    });

    testWidgets('cargando no responde al toque', (tester) async {
      var toques = 0;
      await tester.pumpWidget(
        wrap(GoogleButton(loading: true, onPressed: () => toques++)),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byType(OutlinedButton));
      await tester.pump();
      expect(toques, 0);
    });

    testWidgets('llega al alto mínimo táctil', (tester) async {
      await tester.pumpWidget(wrap(GoogleButton(onPressed: () {})));
      await tester.pumpAndSettle();

      expect(
        tester.getSize(find.byType(OutlinedButton)).height,
        greaterThanOrEqualTo(48),
      );
    });
  });
}

class _FakeGoogle implements GoogleSignInService {
  String? idToken = 'token-de-prueba';
  int tokensPedidos = 0;
  int sesionesCerradas = 0;

  @override
  Future<String?> obtenerIdToken() async {
    tokensPedidos++;
    return idToken;
  }

  @override
  Future<void> cerrarSesion() async => sesionesCerradas++;
}

/// Todo igual que el mock salvo el canje, que revienta.
class _RepoQueFalla extends MockAuthRepository {
  @override
  Future<User> loginConGoogle(String idToken, {bool aceptaTerminos = false}) async =>
      throw Exception('backend caído');
}
