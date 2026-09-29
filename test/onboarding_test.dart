import 'package:enam_app/core/providers.dart';
import 'package:enam_app/core/router/routes.dart';
import 'package:enam_app/core/storage/app_prefs.dart';
import 'package:enam_app/core/theme/app_theme.dart';
import 'package:enam_app/features/auth/presentation/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'golden/_comun.dart';

/// La presentación es una pantalla, no un carrusel (plan §6): crear la cuenta
/// o entrar está a un toque, sin pasar por pasos.
void main() {
  // La fuente real: con la de pruebas los textos miden otra cosa y la
  // comprobación de que el ejemplo cabe no diría nada del teléfono.
  setUpAll(cargarFuentes);

  Future<_Prefs> montar(WidgetTester tester) async {
    final prefs = _Prefs();
    final router = GoRouter(
      initialLocation: Routes.onboarding,
      routes: [
        GoRoute(
          path: Routes.onboarding,
          builder: (_, _) => const OnboardingScreen(),
        ),
        GoRoute(
          path: Routes.register,
          builder: (_, _) => const Text('pantalla de registro'),
        ),
        GoRoute(
          path: Routes.login,
          builder: (_, _) => const Text('pantalla de acceso'),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appPrefsProvider.overrideWithValue(prefs)],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return prefs;
  }

  testWidgets('sin carrusel: no hay pasos que recorrer', (tester) async {
    await montar(tester);
    expect(find.byType(PageView), findsNothing);
    expect(find.text('Siguiente'), findsNothing);
    expect(find.text('EJEMPLO'), findsOneWidget);
  });

  testWidgets('crear la cuenta está a un toque y no vuelve a salir', (
    tester,
  ) async {
    final prefs = await montar(tester);
    await tester.tap(find.text('Crear cuenta gratis'));
    await tester.pumpAndSettle();

    expect(find.text('pantalla de registro'), findsOneWidget);
    expect(prefs.visto, isTrue);
  });

  testWidgets('quien ya tiene cuenta entra directo', (tester) async {
    final prefs = await montar(tester);
    await tester.tap(find.text('Ya tengo cuenta'));
    await tester.pumpAndSettle();

    expect(find.text('pantalla de acceso'), findsOneWidget);
    expect(prefs.visto, isTrue);
  });

  for (final (nombre, tamano) in const [
    ('13 mini', Size(375, 812)),
    ('14 Pro', Size(393, 852)),
    ('17 Pro Max', Size(440, 956)),
  ]) {
    testWidgets('en el $nombre, el ejemplo cabe entero sobre los botones', (
      tester,
    ) async {
      tester.view
        ..physicalSize = tamano * 3
        ..devicePixelRatio = 3
        // La muesca y el indicador de inicio, como en el teléfono.
        ..padding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [appPrefsProvider.overrideWithValue(_Prefs())],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const OnboardingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final tarjeta = tester.getRect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              (w.properties.label ?? '').startsWith('Ejemplo de pregunta'),
        ),
      );
      final boton = tester.getRect(
        find.widgetWithText(FilledButton, 'Crear cuenta gratis'),
      );
      // Antes, en el 14 Pro, el borde inferior de la tarjeta quedaba debajo
      // de la zona de botones fijos.
      expect(tarjeta.bottom, lessThan(boton.top));
    });
  }
}

class _Prefs implements AppPrefs {
  bool visto = false;

  @override
  Future<bool> onboardingVisto() async => visto;

  @override
  Future<void> marcarOnboardingVisto() async => visto = true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
