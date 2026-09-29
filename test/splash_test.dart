import 'dart:async';

import 'package:enam_app/core/error/failure.dart';
import 'package:enam_app/core/providers.dart';
import 'package:enam_app/core/storage/app_prefs.dart';
import 'package:enam_app/core/theme/app_theme.dart';
import 'package:enam_app/features/auth/data/mock_auth_repository.dart';
import 'package:enam_app/features/auth/domain/auth_models.dart';
import 'package:enam_app/features/auth/presentation/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lo que ve quien abre la app mientras se decide a dónde ir (plan §5).
///
/// Sin espera mínima, lo normal es que el splash ni se note. Estas pruebas
/// cubren el caso contrario: cuando algo tarda o falla, la pantalla lo dice y
/// deja reintentar, en vez de quedarse con el logo para siempre.
void main() {
  Widget montar(_RepoControlable repo) => ProviderScope(
    overrides: [
      appPrefsProvider.overrideWithValue(_Prefs()),
      authRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp(theme: AppTheme.light, home: const SplashScreen()),
  );

  testWidgets('un arranque rápido no enseña ni indicador ni aviso', (
    tester,
  ) async {
    final repo = _RepoControlable();
    await tester.pumpWidget(montar(repo));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Cargando…'), findsNothing);
    expect(find.text('Reintentar'), findsNothing);
  });

  testWidgets('si tarda, aparece una indicación discreta sin porcentajes', (
    tester,
  ) async {
    final repo = _RepoControlable()..colgado = true;
    await tester.pumpWidget(montar(repo));
    await tester.pump(SplashScreen.esperaAntesDeIndicar);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Cargando…'), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
  });

  testWidgets('a los 8 segundos dice que tarda y deja reintentar', (
    tester,
  ) async {
    final repo = _RepoControlable()..colgado = true;
    await tester.pumpWidget(montar(repo));
    await tester.pump(SplashScreen.esperaAntesDeAvisar);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Está tardando más de lo normal'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('si la sesión no se pudo comprobar, lo dice y reintenta', (
    tester,
  ) async {
    final repo = _RepoControlable()..fallo = const NetworkFailure();
    await tester.pumpWidget(montar(repo));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('No pudimos conectar'), findsOneWidget);
    final antes = repo.llamadas;

    // Vuelve la señal.
    repo.fallo = null;
    await tester.tap(find.text('Reintentar'));
    await tester.pump();
    // El aviso sale con un fundido de 220 ms y se retira en el fotograma
    // siguiente a terminar.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(repo.llamadas, greaterThan(antes));
    expect(find.text('No pudimos conectar'), findsNothing);
  });

  testWidgets('no lanza un segundo intento mientras el primero sigue', (
    tester,
  ) async {
    final repo = _RepoControlable()..colgado = true;
    await tester.pumpWidget(montar(repo));
    await tester.pump(SplashScreen.esperaAntesDeAvisar);
    await tester.pump(const Duration(milliseconds: 300));

    // El primer intento sigue colgado: el botón está, pero desactivado.
    final boton = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(boton.onPressed, isNull);
    expect(repo.llamadas, 1);
  });
}

class _RepoControlable extends MockAuthRepository {
  int llamadas = 0;
  bool colgado = false;
  Failure? fallo;

  @override
  Future<User?> currentUser() {
    llamadas++;
    // Un completer que nunca se completa: cuelga sin dejar temporizadores.
    if (colgado) return Completer<User?>().future;
    if (fallo case final f?) return Future.error(f);
    return Future.value();
  }
}

class _Prefs implements AppPrefs {
  @override
  Future<bool> onboardingVisto() async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
