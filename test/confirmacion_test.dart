import 'package:enam_app/core/theme/app_theme.dart';
import 'package:enam_app/shared/widgets/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// El diálogo de confirmación tiene que enseñar SIEMPRE las dos salidas.
///
/// Se quedó sin botones una vez: las acciones vivían en el `OverflowBar` de
/// `AlertDialog`, que las mide de forma intrínseca, y un `LayoutBuilder` ahí
/// dentro lanza al calcular el alto. El diálogo salía con título y texto, y sin
/// forma de salir ni de volver.
void main() {
  Future<void> abrir(
    WidgetTester tester, {
    required String confirmarLabel,
    required String cancelarLabel,
    bool destructivo = false,
    Size tamano = const Size(400, 800),
    double escalaTexto = 1,
  }) async {
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(
          size: tamano,
          textScaler: TextScaler.linear(escalaTexto),
        ),
        child: MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => confirmar(
                    context,
                    titulo: '¿Salir?',
                    mensaje: 'Tu avance queda guardado.',
                    confirmar: confirmarLabel,
                    cancelar: cancelarLabel,
                    destructivo: destructivo,
                  ),
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('enseña confirmar y cancelar', (tester) async {
    await abrir(
      tester,
      confirmarLabel: 'Salir',
      cancelarLabel: 'Seguir practicando',
    );

    expect(find.text('Salir'), findsOneWidget);
    expect(find.text('Seguir practicando'), findsOneWidget);
  });

  testWidgets('también en el caso destructivo', (tester) async {
    await abrir(
      tester,
      confirmarLabel: 'Eliminar',
      cancelarLabel: 'Cancelar',
      destructivo: true,
    );

    expect(find.text('Eliminar'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
  });

  testWidgets('y con la fuente ampliada, apiladas', (tester) async {
    await abrir(
      tester,
      confirmarLabel: 'Salir',
      cancelarLabel: 'Seguir rindiendo',
      escalaTexto: 1.4,
      tamano: const Size(360, 640),
    );

    expect(find.text('Salir'), findsOneWidget);
    expect(find.text('Seguir rindiendo'), findsOneWidget);
  });

  testWidgets('confirmar devuelve true y cancelar false', (tester) async {
    bool? resultado;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  resultado = await confirmar(
                    context,
                    titulo: '¿Salir?',
                    mensaje: 'Da igual.',
                    confirmar: 'Salir',
                    cancelar: 'Volver',
                  );
                },
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salir'));
    await tester.pumpAndSettle();
    expect(resultado, isTrue);

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Volver'));
    await tester.pumpAndSettle();
    expect(resultado, isFalse);
  });
}
