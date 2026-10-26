@Tags(['golden'])
library;

import 'package:enam_app/core/router/routes.dart';
import 'package:enam_app/core/theme/app_theme.dart';
import 'package:enam_app/features/tutor/data/tutor_repository.dart';
import 'package:enam_app/features/tutor/domain/tutor_models.dart';
import 'package:enam_app/features/tutor/presentation/tutor_controller.dart';
import 'package:enam_app/features/tutor/presentation/tutor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '_comun.dart';

/// Capturas del tutor con IA (fase 1) en el Android de referencia (412 × 915),
/// contra el doble del repositorio: el estado vacío, una respuesta con citas y
/// opciones, la tarjeta de práctica, la entrada desde una pregunta y la prueba
/// gratis agotada.
///
/// ```sh
/// flutter test --update-goldens test/golden/tutor_test.dart
/// ```
void main() {
  setUpAll(cargarFuentes);

  const tamano = Size(412, 915);

  final capturas =
      <
        ({
          String nombre,
          ContextoDelTutor contexto,
          int restantes,
          List<String> mensajes,
          bool cerrarMuro,
        })
      >[
        (
          nombre: '9.1-tutor-vacio',
          contexto: const ContextoDelTutor(),
          restantes: 15,
          mensajes: const [],
          cerrarMuro: false,
        ),
        (
          nombre: '9.2-tutor-respuesta',
          contexto: const ContextoDelTutor(),
          restantes: 15,
          mensajes: const ['¿Por qué la metformina es primera línea?'],
          cerrarMuro: false,
        ),
        (
          nombre: '9.3-tutor-practica',
          // Con pocos mensajes: el contador discreto sobre la caja.
          contexto: const ContextoDelTutor(),
          restantes: 5,
          mensajes: const ['Quiero practicar mi área más débil'],
          cerrarMuro: false,
        ),
        (
          nombre: '9.4-tutor-desde-pregunta',
          contexto: const ContextoDelTutor.pregunta(
            id: 'q-1',
            enunciado:
                'Paciente varón de 58 años, con antecedente de hipertensión '
                'arterial de 10 años de evolución en tratamiento irregular '
                'con enalapril, acude a emergencia por dolor torácico…',
          ),
          restantes: 15,
          mensajes: const [],
          cerrarMuro: false,
        ),
        (
          nombre: '9.5-tutor-prueba-agotada',
          contexto: const ContextoDelTutor(),
          restantes: 0,
          mensajes: const ['¿Y la insulina?'],
          cerrarMuro: true,
        ),
      ];

  for (final c in capturas) {
    for (final oscuro in [false, true]) {
      final tema = oscuro ? 'oscuro' : 'claro';

      testWidgets('${c.nombre} · $tema', (tester) async {
        tester.view
          ..devicePixelRatio = 2
          ..physicalSize = tamano * 2;
        addTearDown(tester.view.reset);

        final router = GoRouter(
          initialLocation: Routes.tutor,
          routes: [
            GoRoute(
              path: Routes.tutor,
              builder: (_, _) => TutorScreen(contexto: c.contexto),
            ),
            GoRoute(
              path: Routes.premium,
              builder: (_, _) => const Scaffold(body: Text('MURO')),
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              tutorActivoProvider.overrideWithValue(true),
              tutorRepositoryProvider.overrideWithValue(
                FakeTutorRepository(
                  pausa: Duration.zero,
                  pensar: const Duration(milliseconds: 100),
                  restantesPrueba: c.restantes,
                ),
              ),
            ],
            child: MediaQuery(
              data: const MediaQueryData(
                size: tamano,
                padding: EdgeInsets.only(top: 24, bottom: 16),
              ),
              child: MaterialApp.router(
                debugShowCheckedModeBanner: false,
                theme: oscuro ? AppTheme.dark : AppTheme.light,
                routerConfig: router,
              ),
            ),
          ),
        );
        await _esperar(tester);

        for (final m in c.mensajes) {
          await tester.enterText(find.byType(TextField), m);
          await tester.pump();
          await tester.tap(find.byTooltip('Enviar'));
          await _esperar(tester);
        }
        if (c.cerrarMuro) {
          router.pop();
          await _esperar(tester);
        }
        // Sin el cursor parpadeando ni el foco del teclado en la captura.
        FocusManager.instance.primaryFocus?.unfocus();
        await _esperar(tester);

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('_imagenes/android-412/${c.nombre}-$tema.png'),
        );
      });
    }
  }
}

Future<void> _esperar(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
