import 'package:enam_app/core/analitica/analitica.dart';
import 'package:enam_app/core/providers.dart';
import 'package:enam_app/core/router/routes.dart';
import 'package:enam_app/core/theme/app_theme.dart';
import 'package:enam_app/features/auth/data/mock_auth_repository.dart';
import 'package:enam_app/features/auth/presentation/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Los eventos de la app según el contrato (enam-business/contrato/).
void main() {
  group('Lista cerrada', () {
    test('solo los de cliente de la app; los de servidor, no', () {
      final nombres = Evento.values.map((e) => e.nombre).toSet();
      expect(nombres, {'signup_started', 'plans_viewed', 'checkout_started'});
      // Pasaron a ser de servidor: si la app los mandara, se rechazarían.
      for (final deServidor in const [
        'signup_verified',
        'profile_completed',
        'account_created',
        'first_practice_completed',
        'payment_confirmed',
        'access_granted',
      ]) {
        expect(nombres, isNot(contains(deServidor)));
      }
    });

    test('nada fuera de la lista sale del teléfono', () {
      final limpias = propiedadesValidas(Evento.signupStarted, {
        'metodo': 'correo',
        'email': 'valeria@unmsm.edu.pe',
        'nombre': 'Valeria',
        'token': 'abc',
        'origen': 'correo',
      }, plataforma: 'android');
      expect(limpias, {'metodo': 'correo'});
    });

    test('un valor fuera del enum se descarta', () {
      expect(
        propiedadesValidas(Evento.signupStarted, {
          'metodo': 'facebook',
        }, plataforma: 'ios'),
        isEmpty,
      );
    });

    test('sin una obligatoria, el evento no se encola', () {
      expect(
        propiedadesValidas(Evento.plansViewed, {}, plataforma: 'ios'),
        isNull,
      );
      expect(
        propiedadesValidas(Evento.plansViewed, {
          'pantalla': 'acceso_terminado',
        }, plataforma: 'ios'),
        {'pantalla': 'acceso_terminado'},
      );
    });

    test('checkout_started es solo de iOS', () {
      const props = {'plan_id': 'intensivo', 'medio': 'apple'};
      expect(
        propiedadesValidas(Evento.checkoutStarted, props, plataforma: 'ios'),
        props,
      );
      expect(
        propiedadesValidas(
          Evento.checkoutStarted,
          props,
          plataforma: 'android',
        ),
        isNull,
      );
    });
  });

  group('version_app', () {
    test('la de tienda, tal cual', () {
      expect(
        versionApp(version: '1.0.0', build: '7', release: true),
        '1.0.0+7',
      );
    });

    test('fuera de la tienda, con -dev: el servidor la cuenta como prueba', () {
      expect(
        versionApp(version: '1.0.0', build: '7', release: false),
        '1.0.0+7-dev',
      );
      expect(versionApp(version: '', build: '', release: false), '0.0.0-dev');
    });

    test('cumple el patrón del contrato', () {
      final patron = RegExp(r'^[A-Za-z0-9._+-]{1,32}$');
      expect(
        patron.hasMatch(
          versionApp(version: '1.0.0', build: '7', release: false),
        ),
        isTrue,
      );
    });
  });

  testWidgets('enviar el registro emite signup_started con metodo correo', (
    tester,
  ) async {
    final registrados = <(Evento, Map<String, String>)>[];
    tester.view
      ..physicalSize = const Size(393, 1200) * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          analiticaProvider.overrideWithValue(_Capturadora(registrados)),
          authRepositoryProvider.overrideWithValue(MockAuthRepository()),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: GoRouter(
            initialLocation: Routes.register,
            routes: [
              GoRoute(
                path: Routes.register,
                builder: (_, _) => const RegisterScreen(),
              ),
              GoRoute(
                path: Routes.verifyEmail,
                builder: (_, _) => const Text('verificar'),
              ),
            ],
          ),
        ),
      ),
    );

    final campos = find.byType(TextField);
    await tester.enterText(campos.at(0), 'Valeria Rojas');
    await tester.enterText(campos.at(1), 'valeria@unmsm.edu.pe');
    await tester.enterText(campos.at(2), 'una-clave-larga');
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.text('Crear cuenta'));
    await tester.pump();

    expect(registrados.single.$1, Evento.signupStarted);
    expect(registrados.single.$2, {'metodo': 'correo'});
    await tester.pump(const Duration(seconds: 2));
  });
}

class _Capturadora implements Analitica {
  _Capturadora(this.eventos);

  final List<(Evento, Map<String, String>)> eventos;

  @override
  void registrar(Evento evento, {Map<String, String> propiedades = const {}}) =>
      eventos.add((evento, propiedades));

  @override
  Future<void> enviarPendientes() async {}
}
