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

/// La interfaz de eventos (plan §12). Sin proveedor detrás: esto comprueba
/// que los disparadores existen y que nada personal sale de la app.
void main() {
  group('Filtro de propiedades', () {
    test('descarta todo lo que no esté en la lista permitida', () {
      final limpio = filtrar({
        'email': 'valeria@unmsm.edu.pe',
        'nombre': 'Valeria',
        'token': 'abc',
        'enunciado': 'Paciente de 58 años…',
        'pantalla': 'registro',
      });

      expect(limpio.keys, isNot(contains('email')));
      expect(limpio.keys, isNot(contains('nombre')));
      expect(limpio.keys, isNot(contains('token')));
      expect(limpio.keys, isNot(contains('enunciado')));
      expect(limpio['pantalla'], 'registro');
    });

    test('añade la plataforma y la versión visual', () {
      final limpio = filtrar(const {});
      expect(limpio['version_visual'], versionVisual);
      expect(limpio['plataforma'], isNotEmpty);
    });

    test('los nombres son los del diccionario compartido', () {
      expect(
        Evento.values.map((e) => e.nombre),
        containsAll([
          'signup_started',
          'signup_verified',
          'profile_completed',
          'plans_viewed',
        ]),
      );
    });
  });

  testWidgets('enviar el registro emite signup_started', (tester) async {
    final registrados = <Evento>[];
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

    expect(registrados, [Evento.signupStarted]);
    await tester.pump(const Duration(seconds: 2));
  });
}

class _Capturadora implements Analitica {
  _Capturadora(this.eventos);

  final List<Evento> eventos;

  @override
  void registrar(Evento evento, {Map<String, String> propiedades = const {}}) =>
      eventos.add(evento);
}
