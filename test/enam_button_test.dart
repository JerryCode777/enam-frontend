import 'package:enam_app/core/theme/app_theme.dart';
import 'package:enam_app/core/theme/design_tokens.dart';
import 'package:enam_app/shared/widgets/enam_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayuda/contraste.dart';

/// El botón principal es un relleno plano del color de acción.
///
/// Antes llevaba un degradado que terminaba en el azul de marca, donde el
/// texto blanco bajaba a 3,1:1. Estas pruebas fijan que el relleno sea el de
/// acción y que la etiqueta se lea en los dos temas.
void main() {
  Widget wrap(Widget child, {ThemeData? theme}) => MaterialApp(
    theme: theme ?? AppTheme.light,
    home: Scaffold(body: child),
  );

  Color? relleno(WidgetTester tester, {Set<WidgetState> estados = const {}}) {
    final boton = tester.widget<FilledButton>(find.byType(FilledButton));
    return boton.style?.backgroundColor?.resolve(estados);
  }

  group('Relleno de acción', () {
    for (final (nombre, tema, fondo, texto) in [
      (
        'claro',
        AppTheme.light,
        DesignTokens.actionLight,
        DesignTokens.onActionLight,
      ),
      (
        'oscuro',
        AppTheme.dark,
        DesignTokens.actionDark,
        DesignTokens.onActionDark,
      ),
    ]) {
      testWidgets('en $nombre usa el color de acción y la etiqueta cumple AA', (
        tester,
      ) async {
        await tester.pumpWidget(
          wrap(EnamButton(label: 'Ingresar', onPressed: () {}), theme: tema),
        );

        expect(relleno(tester), fondo);
        expect(tema.colorScheme.onPrimary, texto);
        expect(contraste(fondo, texto), greaterThanOrEqualTo(4.5));
      });
    }

    testWidgets('presionado se oscurece sin perder contraste', (tester) async {
      await tester.pumpWidget(
        wrap(EnamButton(label: 'Ingresar', onPressed: () {})),
      );

      final presionado = relleno(tester, estados: {WidgetState.pressed});
      expect(presionado, DesignTokens.actionPressedLight);
      expect(
        contraste(presionado!, DesignTokens.onActionLight),
        greaterThanOrEqualTo(4.5),
      );
    });

    testWidgets('no lleva degradado en ningún estado', (tester) async {
      await tester.pumpWidget(
        wrap(EnamButton(label: 'Ingresar', onPressed: () {})),
      );
      final conDegradado = find.byWidgetPredicate(
        (w) =>
            (w is Ink &&
                w.decoration is BoxDecoration &&
                (w.decoration! as BoxDecoration).gradient != null) ||
            (w is DecoratedBox &&
                w.decoration is BoxDecoration &&
                (w.decoration as BoxDecoration).gradient != null),
      );
      expect(conDegradado, findsNothing);
    });

    testWidgets('deshabilitado no se pinta como activo', (tester) async {
      // Con el color de acción puesto, un botón deshabilitado se vería activo.
      await tester.pumpWidget(
        wrap(const EnamButton(label: 'Guardar', onPressed: null)),
      );
      expect(
        relleno(tester, estados: {WidgetState.disabled}),
        isNot(DesignTokens.actionLight),
      );
    });

    testWidgets('cargando muestra el spinner y no responde', (tester) async {
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
