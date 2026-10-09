import 'package:enam_app/features/profile/presentation/legal_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// El titular que la app muestra es AIDA SOFT S.A.C.S.
///
/// Antes era Jaks Tech SAC. Lo que cambió es la empresa que opera la app; los
/// ids de las tiendas (`pe.jakstech.*`) son de la tienda y siguen igual.
void main() {
  testWidgets('la pantalla legal nombra a AIDA SOFT con su RUC y domicilio', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LegalScreen()));
    await tester.pumpAndSettle();

    final textos = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
        .join('\n');

    expect(textos, contains('AIDA SOFT S.A.C.S. (RUC 20616515323)'));
    expect(textos, contains('Cal. Ica 522, Urb. Cercado de Mariano Melgar'));
    expect(textos, isNot(contains('Jaks Tech')));
    expect(textos, isNot(contains('20614811804')));
  });
}
