import 'package:enam_app/core/config/configuracion_remota.dart';
import 'package:enam_app/core/error/failure.dart';
import 'package:enam_app/core/network/api_client.dart';
import 'package:enam_app/core/router/app_router.dart';
import 'package:enam_app/core/router/routes.dart';
import 'package:enam_app/features/auth/domain/auth_models.dart';
import 'package:enam_app/core/providers.dart';
import 'package:enam_app/features/system/data/actualizador.dart';
import 'package:enam_app/features/system/domain/actualizacion.dart';
import 'package:enam_app/features/system/presentation/system_screens.dart';
import 'package:enam_app/features/subscription/domain/subscription_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pedir que se actualice la app (octubre de 2026: la mayoría de quienes
/// topaban el límite en Android seguían en versiones sin Play Billing).
void main() {
  group('compararVersiones', () {
    test('por números, no como texto', () {
      expect(compararVersiones('1.1.10', '1.1.9'), 1);
      expect(compararVersiones('1.1.2', '1.1.3'), -1);
      expect(compararVersiones('2.0.0', '1.9.9'), 1);
    });

    test('ignora el build y completa lo que falta', () {
      expect(compararVersiones('1.1.8+12', '1.1.8'), 0);
      expect(compararVersiones('1.1', '1.1.0'), 0);
    });
  });

  group('debajoDeLaMinima', () {
    test('solo con las dos versiones', () {
      expect(debajoDeLaMinima(instalada: '1.1.1', minima: '1.1.3'), isTrue);
      expect(debajoDeLaMinima(instalada: '1.1.3', minima: '1.1.3'), isFalse);
      expect(debajoDeLaMinima(instalada: '1.1.9', minima: '1.1.3'), isFalse);
      // Sin mínima, o sin saber la instalada, nunca se bloquea.
      expect(debajoDeLaMinima(instalada: '1.1.1', minima: null), isFalse);
      expect(debajoDeLaMinima(instalada: '1.1.1', minima: ' '), isFalse);
      expect(debajoDeLaMinima(instalada: null, minima: '1.1.3'), isFalse);
    });
  });

  group('/config', () {
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    Future<String?> leer(Map<String, dynamic> config) async {
      String? leida = 'sin llamar';
      await ConfiguracionRemota(
        _Cliente(config),
        alLeerVersionMinima: (m) => leida = m,
      ).cargar();
      return leida;
    }

    test('Android lee minVersionAndroid', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(
        await leer({'minVersionAndroid': '1.1.3', 'minVersionIos': '1.1.0'}),
        '1.1.3',
      );
    });

    test('iPhone lee minVersionIos', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(
        await leer({'minVersionAndroid': '1.1.3', 'minVersionIos': '1.1.0'}),
        '1.1.0',
      );
    });

    test('null es sin mínima', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(await leer({'minVersionAndroid': null}), isNull);
    });
  });

  test('la mínima del servidor decide el bloqueo', () {
    final c = ProviderContainer(
      overrides: [versionInstaladaProvider.overrideWithValue('1.1.1')],
    );
    addTearDown(c.dispose);

    expect(c.read(actualizacionObligatoriaProvider), isFalse);
    c.read(versionMinimaProvider.notifier).fijar('1.1.3');
    expect(c.read(actualizacionObligatoriaProvider), isTrue);
    c.read(versionMinimaProvider.notifier).fijar(null);
    expect(c.read(actualizacionObligatoriaProvider), isFalse);
  });

  group('el router', () {
    final conSesion = AsyncValue<AuthState>.data(
      AuthSignedIn(
        User(
          id: 'u1',
          email: 'a@b.pe',
          nombre: 'Ana',
          emailVerificado: true,
          universidad: 'UNSA',
          condicion: StudentCondition.values.first,
          fechaObjetivo: DateTime(2027),
        ),
      ),
    );
    const AsyncValue<Startup> listo = AsyncData((onboardingVisto: true));
    const sinSub = AsyncValue<Subscription>.loading();

    test('por debajo de la mínima, todo lleva a «Actualiza»', () {
      for (final auth in [
        conSesion,
        const AsyncValue<AuthState>.data(AuthSignedOut()),
      ]) {
        for (final ruta in [Routes.home, Routes.login, Routes.premium]) {
          expect(
            decidirDestino(
              auth: auth,
              startup: listo,
              suscripcion: sinSub,
              here: ruta,
              actualizar: true,
            ),
            Routes.updateRequired,
          );
        }
      }
      expect(
        decidirDestino(
          auth: conSesion,
          startup: listo,
          suscripcion: sinSub,
          here: Routes.updateRequired,
          actualizar: true,
        ),
        isNull,
      );
    });

    test('sin mínima, nada cambia', () {
      expect(
        decidirDestino(
          auth: conSesion,
          startup: listo,
          suscripcion: sinSub,
          here: Routes.home,
        ),
        isNull,
      );
    });
  });

  testWidgets('«Actualiza» en Android lanza sola la actualización de Play', (
    tester,
  ) async {
    final tienda = _Tienda();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [actualizadorProvider.overrideWithValue(tienda)],
        child: const MaterialApp(home: UpdateRequiredScreen()),
      ),
    );
    await tester.pump();
    expect(tienda.inmediatas, 1);

    await tester.tap(find.text('Actualizar en Google Play'));
    await tester.pump();
    expect(tienda.inmediatas, 2);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('en iPhone espera al botón, que va a App Store', (tester) async {
    final tienda = _Tienda();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [actualizadorProvider.overrideWithValue(tienda)],
        child: const MaterialApp(home: UpdateRequiredScreen()),
      ),
    );
    await tester.pump();
    expect(tienda.inmediatas, 0);
    expect(find.text('Actualizar en App Store'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  test('ACTUALIZA_LA_APP no es el muro ni el pago', () {
    // Lo atiende `atenderFaltaDeAcceso` llevando a «Actualiza»; aquí basta
    // con que el resto de la app no lo confunda con otro 403.
    const e = ForbiddenFailure(
      'Actualiza ENAM Prep en Google Play para seguir practicando y poder '
          'suscribirte.',
      'ACTUALIZA_LA_APP',
    );
    expect(e.requiereSuscripcion, isFalse);
  });
}

class _Cliente implements ApiClient {
  _Cliente(this._config);

  final Map<String, dynamic> _config;

  @override
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Object? cancelToken,
    Object? onReceiveProgress,
  }) async => _config as T;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Tienda implements Actualizador {
  var inmediatas = 0;

  @override
  Future<void> actualizarYa() async => inmediatas++;

  @override
  Future<bool> descargarSiHayNueva() async => false;

  @override
  Future<void> instalarDescargada() async {}
}
