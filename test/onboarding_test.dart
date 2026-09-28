import 'package:enam_app/core/providers.dart';
import 'package:enam_app/core/router/routes.dart';
import 'package:enam_app/core/storage/app_prefs.dart';
import 'package:enam_app/core/theme/app_theme.dart';
import 'package:enam_app/features/auth/presentation/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// La presentación es una pantalla, no un carrusel (plan §6): crear la cuenta
/// o entrar está a un toque, sin pasar por pasos.
void main() {
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
