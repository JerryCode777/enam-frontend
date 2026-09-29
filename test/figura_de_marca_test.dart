import 'dart:io';

import 'package:enam_app/core/theme/app_theme.dart';
import 'package:enam_app/features/auth/presentation/onboarding_screen.dart';
import 'package:enam_app/features/home/presentation/home_screen.dart';
import 'package:enam_app/shared/widgets/figura_de_marca.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'ayuda/inicio.dart';

/// La figura de marca (ilustración generada con IA): dónde aparece, que sea
/// decorativa y que no pese de más.
void main() {
  setUpAll(() => initializeDateFormatting('es'));

  Future<void> inicio(
    WidgetTester tester, {
    required double ancho,
    double texto = 1,
  }) async {
    tester.view
      ..physicalSize = Size(ancho, 900) * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesDeInicio(EstadoInicio.areaPrioritaria),
        child: MaterialApp(
          theme: AppTheme.light,
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(ancho, 900),
              textScaler: TextScaler.linear(texto),
            ),
            child: const HomeScreen(),
          ),
        ),
      ),
    );
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 400));
    }
  }

  group('En el inicio, solo si sobra sitio', () {
    testWidgets('un teléfono normal (393 dp): no aparece', (tester) async {
      await inicio(tester, ancho: 393);
      expect(find.byType(FiguraDeMarca), findsNothing);
    });

    testWidgets('un teléfono grande (440 dp): aparece', (tester) async {
      await inicio(tester, ancho: 440);
      expect(find.byType(FiguraDeMarca), findsOneWidget);
    });

    testWidgets('con la letra al 140 % no aprieta ni desborda', (tester) async {
      await inicio(tester, ancho: 440, texto: 1.4);
      expect(tester.takeException(), isNull);
      // El botón conserva todo el ancho del bloque.
      final boton = tester.getSize(
        find.widgetWithText(FilledButton, 'Practicar Medicina'),
      );
      expect(boton.width, greaterThan(300));
    });
  });

  testWidgets('en la presentación, y sin nombre para el lector de pantalla', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light,
          home: const OnboardingScreen(),
        ),
      ),
    );
    expect(find.byType(FiguraDeMarca), findsOneWidget);

    final imagen = tester.widget<Image>(
      find.descendant(
        of: find.byType(FiguraDeMarca),
        matching: find.byType(Image),
      ),
    );
    // Decorativa: no es una persona que presentar ni un testimonio.
    expect(imagen.excludeFromSemantics, isTrue);
    expect(imagen.semanticLabel, isNull);
  });

  test('los dos recursos pesan menos de 200 KB en total', () {
    final bytes = [
      'assets/images/doctora_brazos_cruzados.webp',
      'assets/images/doctora_senala.webp',
    ].map((r) => File(r).lengthSync()).fold(0, (a, b) => a + b);
    expect(bytes, lessThan(200 * 1024));
  });
}
