import 'package:enam_app/core/providers.dart';
import 'package:enam_app/core/router/routes.dart';
import 'package:enam_app/features/session/data/session_repository.dart';
import 'package:enam_app/features/session/domain/session_models.dart';
import 'package:enam_app/features/session/presentation/simulacro_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// La salida del examen, ejecutada de verdad: se toca «Salir», se confirma y se
/// mira dónde acabó el router.
///
/// La prueba de tipos de al lado dice qué sesión se crea; esta dice qué hace la
/// pantalla con ese dato, que es lo que el estudiante nota.
void main() {
  late MockSessionRepository repo;
  late StudySession examenPasado;
  late StudySession simulacro;

  // Las sesiones se crean aquí y no dentro del test: el mock simula latencia
  // con `Future.delayed`, y dentro de `testWidgets` el reloj es falso —esperar
  // ahí a un futuro con retardo cuelga el test para siempre en vez de fallar—.
  setUp(() async {
    repo = MockSessionRepository();
    final examen = (await repo.pastExams()).first;
    examenPasado = await repo.startPastExam(examen.id, modo: PastExamMode.corto);
    simulacro = await repo.startSimulacro();
  });

  /// Monta la pantalla con un router mínimo y devuelve dónde queda al salir.
  Future<String> salirDe(WidgetTester tester, StudySession sesion) async {
    final router = GoRouter(
      initialLocation: '/rindiendo/${sesion.id}',
      routes: [
        GoRoute(
          path: '/rindiendo/:id',
          builder: (_, estado) =>
              SimulacroScreen(sessionId: estado.pathParameters['id']!),
        ),
        GoRoute(path: Routes.home, builder: (_, _) => const Placeholder()),
        GoRoute(
          path: Routes.simulacroSelection,
          builder: (_, _) => const Placeholder(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sessionRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    // `pump` a mano y no `pumpAndSettle`: la pantalla lleva el cronómetro, que
    // es un `Timer.periodic`, y con él nunca hay un fotograma en reposo.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byTooltip('Salir'));
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.widgetWithText(FilledButton, 'Salir'));
    await tester.pump(const Duration(milliseconds: 400));

    return router.state.uri.path;
  }

  testWidgets('salir de un examen pasado devuelve al inicio', (tester) async {
    expect(await salirDe(tester, examenPasado), Routes.home);
  });

  testWidgets('salir de un simulacro sigue devolviendo a simulacros', (
    tester,
  ) async {
    expect(await salirDe(tester, simulacro), Routes.simulacroSelection);
  });
}
