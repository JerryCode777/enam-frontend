@Tags(['golden'])
library;

import 'package:enam_app/features/system/presentation/galeria_componentes_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_comun.dart';

/// La galería de componentes entera, de un solo largo, en los dos temas.
///
/// Es la captura que se mira cuando cambia un token: todas las piezas del
/// sistema visual en una imagen, sin recorrer la app.
///
/// ```sh
/// flutter test --update-goldens test/golden/galeria_test.dart
/// ```
void main() {
  setUpAll(cargarFuentes);

  // Alto de sobra para que quepa todo sin desplazar.
  const tamano = Size(393, 4600);

  for (final oscuro in [false, true]) {
    final tema = oscuro ? 'oscuro' : 'claro';

    testWidgets('galería · $tema', (tester) async {
      tester.view
        ..devicePixelRatio = 1.5
        ..physicalSize = tamano * 1.5;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        Marco(
          tamano: tamano,
          oscuro: oscuro,
          child: GaleriaComponentesScreen(oscuroInicial: oscuro),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('_imagenes/galeria/galeria-$tema.png'),
      );
    });
  }
}
