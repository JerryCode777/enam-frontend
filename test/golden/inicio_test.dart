@Tags(['golden'])
library;

import 'package:enam_app/core/domain/hora_peru.dart';
import 'package:enam_app/features/home/presentation/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../ayuda/inicio.dart';
import '_comun.dart';

/// El inicio contextual en cada uno de sus estados (plan §5).
///
/// Una captura por estado, en los tres tamaños y los dos temas. Es la prueba
/// visual de que cada estado tiene su propia siguiente acción y de que cabe en
/// el primer vistazo.
///
/// ```sh
/// flutter test --update-goldens test/golden/inicio_test.dart
/// ```
void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
    await cargarFuentes();
    congelarReloj(DateTime.utc(2026, 7, 30, 17));
  });

  tearDownAll(soltarReloj);

  for (final dispositivo in dispositivos) {
    group(dispositivo.nombre, () {
      for (final estado in EstadoInicio.values) {
        for (final oscuro in [false, true]) {
          final tema = oscuro ? 'oscuro' : 'claro';

          testWidgets('2.1-inicio-${estado.name} · $tema', (tester) async {
            tester.view
              ..devicePixelRatio = 2
              ..physicalSize = dispositivo.tamano * 2;
            addTearDown(tester.view.reset);

            await tester.pumpWidget(
              Marco(
                tamano: dispositivo.tamano,
                oscuro: oscuro,
                overrides: overridesDeInicio(estado),
                child: const HomeScreen(),
              ),
            );
            for (var i = 0; i < 3; i++) {
              await tester.pump(const Duration(milliseconds: 600));
            }

            await expectLater(
              find.byType(MaterialApp),
              matchesGoldenFile(
                '_imagenes/${dispositivo.nombre}/'
                '2.1-inicio-${estado.name}-$tema.png',
              ),
            );

            await tester.pumpWidget(const SizedBox());
            await tester.pump(const Duration(seconds: 2));
          });
        }
      }
    });
  }
}
