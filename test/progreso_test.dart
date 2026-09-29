import 'package:enam_app/core/providers.dart';
import 'package:enam_app/core/theme/app_theme.dart';
import 'package:enam_app/features/catalog/domain/catalog_models.dart';
import 'package:enam_app/features/stats/domain/stats_models.dart';
import 'package:enam_app/features/stats/presentation/progress_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Progreso (plan §6): la misma sugerencia que el inicio, y la evolución
/// también en tabla.
void main() {
  setUpAll(() => initializeDateFormatting('es'));

  final stats = DashboardStats(
    notaProyectada: 12.4,
    porArea: const [
      AreaPerformance(
        areaId: 'medicina',
        areaNombre: 'Medicina',
        preguntasBlueprint: 40,
        respondidas: 120,
        correctas: 62,
      ),
    ],
    evolucion: [
      GradePoint(fecha: DateTime(2026, 7, 1), nota: 10.5),
      GradePoint(fecha: DateTime(2026, 7, 15), nota: 12.4),
    ],
  );

  Future<void> montar(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(393, 1600) * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardProvider.overrideWith((_) async => stats),
          // El catálogo con el acierto en cero, como lo manda hoy el servidor.
          catalogProvider.overrideWith(
            (_) async => const [
              CatalogNode(
                id: 'medicina',
                nombre: 'Medicina',
                nivel: 'area',
                peso: 40,
              ),
            ],
          ),
        ],
        child: MaterialApp(theme: AppTheme.light, home: const ProgressScreen()),
      ),
    );
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 400));
    }
  }

  testWidgets('la sugerencia usa el acierto real, igual que el inicio', (
    tester,
  ) async {
    await montar(tester);
    expect(
      find.textContaining(
        'Pesa 40 preguntas en el ENAM y vas en 52 % de acierto.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('la evolución también se puede leer como tabla', (tester) async {
    await montar(tester);
    await tester.scrollUntilVisible(find.text('Ver como tabla'), 300);
    await tester.tap(find.text('Ver como tabla'));
    await tester.pumpAndSettle();

    expect(find.text('15 de julio'), findsOneWidget);
    expect(find.text('10.50'), findsOneWidget);
  });
}
