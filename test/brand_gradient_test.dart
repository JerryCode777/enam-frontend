import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enam_app/shared/widgets/brand_gradient.dart';

void main() {
  // El splash salía corrido a la izquierda en iPhone: el hijo del Stack se
  // encogía a su contenido. Tiene que ocupar todo el ancho y centrarse.
  testWidgets('el contenido ocupa todo el ancho y queda centrado', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: BrandGradient(child: Column(children: [Text('ENAM Prep')]))),
    ));
    expect(tester.getSize(find.byType(Column)).width, 390);
    expect(tester.getCenter(find.text('ENAM Prep')).dx, closeTo(195, 0.5));
  });
}
