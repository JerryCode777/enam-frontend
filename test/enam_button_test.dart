import 'package:enam_app/core/theme/app_theme.dart';
import 'package:enam_app/core/theme/design_tokens.dart';
import 'package:enam_app/shared/widgets/enam_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// El botón principal lleva un degradado que se pinta con `Ink`.
///
/// `Ink` dibuja sobre el Material más cercano hacia arriba. Si el botón vive
/// dentro de un Container con fondo —como las barras de acción de abajo— ese
/// fondo se dibuja encima y el degradado desaparece: el botón queda invisible
/// sobre blanco.
///
/// Pasó de verdad en la pantalla de área del temario, y los tests que solo
/// comprobaban ausencia de excepciones no lo vieron. Estos sí.
void main() {
  Widget wrap(Widget child) => MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: child),
  );

  /// El Ink que lleva el degradado, si es que se está pintando.
  Finder inkDelDegradado() => find.byWidgetPredicate(
    (w) =>
        w is Ink &&
        w.decoration is BoxDecoration &&
        (w.decoration! as BoxDecoration).gradient != null,
  );

  group('Degradado del botón', () {
    testWidgets('se pinta cuando el botón está suelto', (tester) async {
      await tester.pumpWidget(
        wrap(EnamButton(label: 'Ingresar', onPressed: () {})),
      );
      expect(inkDelDegradado(), findsOneWidget);
    });

    testWidgets('lleva su propio Material, para no quedar tapado', (
      tester,
    ) async {
      // Este es el caso que se rompió: el botón dentro de un Container con
      // fondo, que es exactamente cómo están las barras de acción inferiores.
      await tester.pumpWidget(
        wrap(
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(DesignTokens.space4),
            child: EnamButton(label: 'Practicar', onPressed: () {}),
          ),
        ),
      );

      final ink = inkDelDegradado();
      expect(ink, findsOneWidget);

      // Sin un Material entre el Container y el Ink, el degradado se pintaría
      // por debajo del fondo blanco y no se vería.
      final materialesEncima = find.ancestor(
        of: ink,
        matching: find.byType(Material),
      );
      expect(
        materialesEncima,
        findsWidgets,
        reason: 'El Ink necesita un Material propio por encima del Container',
      );

      // El Material inmediato tiene que ser transparente: si pintara color,
      // taparía el degradado que está debajo suyo.
      final material = tester.widget<Material>(materialesEncima.first);
      expect(material.type, MaterialType.transparency);
    });

    testWidgets('deshabilitado no pinta degradado', (tester) async {
      // Con el degradado puesto, un botón deshabilitado se vería activo.
      await tester.pumpWidget(
        wrap(const EnamButton(label: 'Guardar', onPressed: null)),
      );
      expect(inkDelDegradado(), findsNothing);
    });

    testWidgets('cargando no pinta degradado ni responde', (tester) async {
      var toques = 0;
      await tester.pumpWidget(
        wrap(
          EnamButton(
            label: 'Enviar',
            loading: true,
            onPressed: () => toques++,
          ),
        ),
      );

      expect(inkDelDegradado(), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      // Sin esto se podría enviar el mismo formulario dos veces.
      expect(toques, 0);
    });
  });

  group('Comportamiento', () {
    testWidgets('llama a onPressed al tocar', (tester) async {
      var toques = 0;
      await tester.pumpWidget(
        wrap(EnamButton(label: 'Ingresar', onPressed: () => toques++)),
      );

      await tester.tap(find.text('Ingresar'));
      await tester.pump();
      expect(toques, 1);
    });

    testWidgets('llega al alto mínimo táctil', (tester) async {
      await tester.pumpWidget(
        wrap(EnamButton(label: 'Ingresar', onPressed: () {})),
      );

      final alto = tester.getSize(find.byType(FilledButton)).height;
      expect(alto, greaterThanOrEqualTo(DesignTokens.minTouchTarget));
    });

    testWidgets('la etiqueta larga se recorta en vez de desbordar', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          SizedBox(
            width: 160,
            child: EnamButton(
              label: 'Una etiqueta larguísima que no cabe de ninguna manera',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
