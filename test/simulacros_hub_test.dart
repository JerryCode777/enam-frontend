import 'package:enam_app/core/providers.dart';
import 'package:enam_app/core/theme/app_theme.dart';
import 'package:enam_app/features/session/domain/session_models.dart';
import 'package:enam_app/features/session/presentation/national_mock_screen.dart';
import 'package:enam_app/features/session/presentation/simulacro_hub_screen.dart';
import 'package:enam_app/features/stats/domain/stats_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// El centro de simulacros dice lo que hay de verdad (plan §6).
void main() {
  setUpAll(() => initializeDateFormatting('es'));

  Future<void> montar(
    WidgetTester tester, {
    List<NationalMock> nacionales = const [],
    List<OpenSession> abiertas = const [],
  }) async {
    tester.view
      ..physicalSize = const Size(393, 1400) * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          nacionalesProvider.overrideWith((_) async => nacionales),
          sesionesAbiertasProvider.overrideWith((_) async => abiertas),
          dashboardProvider.overrideWith(
            (_) async => const DashboardStats(notaProyectada: 0),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const SimulacroHubScreen(),
        ),
      ),
    );
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  testWidgets('sin convocatoria nacional no inventa fecha ni inscritos', (
    tester,
  ) async {
    await montar(tester);

    expect(
      find.text('No hay una convocatoria programada por ahora.'),
      findsOneWidget,
    );
    // Lo que llevaba escrito a mano antes.
    expect(find.textContaining('1,847'), findsNothing);
    expect(find.textContaining('participantes'), findsNothing);
  });

  testWidgets('con convocatoria, sus datos y lo que se puede hacer', (
    tester,
  ) async {
    await montar(
      tester,
      nacionales: [
        NationalMock(
          id: 'n1',
          nombre: 'Nacional',
          inicio: DateTime(2026, 8, 2, 9),
          fin: DateTime(2026, 8, 2, 12),
          participantes: 312,
        ),
      ],
    );

    expect(find.textContaining('312 inscritos'), findsOneWidget);
    expect(find.text('Inscribirme'), findsOneWidget);
  });

  testWidgets('un simulacro a medias se ofrece para continuar', (
    tester,
  ) async {
    await montar(
      tester,
      abiertas: [
        OpenSession(
          id: 's1',
          tipo: SessionType.simulacro,
          iniciadaEn: DateTime(2026, 7, 30, 9),
          respondidas: 41,
          totalPreguntas: 180,
        ),
      ],
    );

    expect(find.textContaining('A medias'), findsOneWidget);
    expect(find.textContaining('pregunta 42 de 180'), findsOneWidget);
  });
}
