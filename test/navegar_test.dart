import 'package:enam_app/core/router/navegar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// `irA` decide sola entre cambiar de pestaña y apilar.
///
/// Se monta un router con la misma forma que el de la app —un
/// `StatefulShellRoute` con dos ramas y rutas sueltas fuera— porque lo que se
/// prueba es justo eso: que la decisión salga del árbol de rutas y no de una
/// lista escrita a mano.
void main() {
  final shellKey = GlobalKey<NavigatorState>();

  Widget pantalla(String texto) => Scaffold(body: Center(child: Text(texto)));

  GoRouter construirRouter() => GoRouter(
    initialLocation: '/inicio',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => Scaffold(body: shell),
        branches: [
          StatefulShellBranch(
            navigatorKey: shellKey,
            routes: [
              GoRoute(
                path: '/inicio',
                builder: (_, _) => pantalla('inicio'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/temario',
                builder: (_, _) => pantalla('temario'),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (_, s) =>
                        pantalla('area ${s.pathParameters['id']}'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(path: '/ajustes', builder: (_, _) => pantalla('ajustes')),
    ],
  );

  /// Monta la app y devuelve el contexto de la pantalla visible.
  Future<(GoRouter, BuildContext)> montar(WidgetTester tester) async {
    final router = construirRouter();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    return (router, tester.element(find.text('inicio')));
  }

  testWidgets('a una ruta de otra pestaña cambia de rama, no apila', (
    tester,
  ) async {
    final (router, contexto) = await montar(tester);

    contexto.irA('/temario');
    await tester.pumpAndSettle();

    expect(find.text('temario'), findsOneWidget);
    expect(router.state.uri.path, '/temario');
    // Lo que reventaba: un segundo Navigator con la misma GlobalKey.
    expect(tester.takeException(), isNull);
  });

  testWidgets('a una ruta hija dentro de una pestaña tampoco apila', (
    tester,
  ) async {
    final (router, contexto) = await montar(tester);

    contexto.irA('/temario/medicina');
    await tester.pumpAndSettle();

    expect(find.text('area medicina'), findsOneWidget);
    expect(router.state.uri.path, '/temario/medicina');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a una ruta de fuera del contenedor sí apila', (tester) async {
    final (router, contexto) = await montar(tester);

    contexto.irA('/ajustes');
    await tester.pumpAndSettle();

    expect(find.text('ajustes'), findsOneWidget);

    // Apilada de verdad: se puede volver a donde se estaba.
    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('inicio'), findsOneWidget);
  });

  testWidgets('una ruta desconocida no rompe la pantalla actual', (
    tester,
  ) async {
    final (_, contexto) = await montar(tester);

    contexto.irA('/no-existe');
    await tester.pumpAndSettle();

    // Acaba en la pantalla de error del router, con su botón de atrás, y no
    // reemplazando lo que el usuario tenía.
    expect(tester.takeException(), isNull);
    expect(find.text('inicio'), findsNothing);
  });

  testWidgets('nunca deja dos contenedores en la pila', (tester) async {
    final (router, contexto) = await montar(tester);

    contexto.irA('/temario');
    await tester.pumpAndSettle();
    contexto.irA('/temario/medicina');
    await tester.pumpAndSettle();

    // La pantalla roja aparecía justamente aquí: con el contenedor apilado dos
    // veces, sus dos Navigator comparten GlobalKey y Flutter se cae.
    final pila = router.routerDelegate.currentConfiguration.matches;
    expect(pila.whereType<ShellRouteMatch>(), hasLength(1));
  });
}
