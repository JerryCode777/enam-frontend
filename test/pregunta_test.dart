import 'package:enam_app/core/config/contacto.dart';
import 'package:enam_app/core/providers.dart';
import 'package:enam_app/core/theme/app_theme.dart';
import 'package:enam_app/core/theme/design_tokens.dart';
import 'package:enam_app/features/session/data/session_repository.dart';
import 'package:enam_app/features/session/domain/session_models.dart';
import 'package:enam_app/features/session/presentation/question_screen.dart';
import 'package:enam_app/features/session/presentation/widgets/option_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// La pantalla donde se pasa la mayor parte del tiempo (plan §6 y §7).
void main() {
  late MockSessionRepository repo;
  late String sesionId;

  Future<void> montar(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(393, 852) * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    repo = MockSessionRepository();
    final sesion = await tester.runAsync(
      () => repo.startPractice(
        const PracticeConfig(areaIds: ['medicina'], cantidadPreguntas: 10),
      ),
    );
    sesionId = sesion!.id;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sessionRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: QuestionScreen(sessionId: sesionId),
        ),
      ),
    );
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 600));
    }
  }

  /// Las alternativas quedan debajo de un caso clínico largo: se baja hasta
  /// ellas como lo haría quien lee.
  Future<void> elegirPrimera(WidgetTester tester) async {
    for (var i = 0; i < 10 && find.byType(OptionCard).evaluate().isEmpty; i++) {
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pump();
    }
    await tester.ensureVisible(find.byType(OptionCard).first);
    await tester.pump();
    await tester.tap(find.byType(OptionCard).first);
  }

  Future<void> responder(WidgetTester tester) async {
    await elegirPrimera(tester);
    await tester.pump();
    await tester.tap(find.text('Responder'));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 600));
    }
  }

  testWidgets('el enunciado se lee a 17 px con interlineado 1,6', (
    tester,
  ) async {
    await montar(tester);
    final pregunta = (await tester.runAsync(
      () => repo.session(sesionId),
    ))!.preguntas.first;
    final texto = tester.widget<Text>(find.text(pregunta.enunciado));

    expect(texto.style?.fontSize, DesignTokens.fontSizeClinical);
    expect(texto.style?.height, DesignTokens.lineHeightClinical);
  });

  testWidgets('seleccionar no responde; hace falta confirmar', (tester) async {
    await montar(tester);
    await elegirPrimera(tester);
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Responder'), findsOneWidget);
    expect(find.textContaining('La correcta es'), findsNothing);
    expect(find.textContaining('Correcto.'), findsNothing);
  });

  testWidgets('al responder, el veredicto queda a la vista', (tester) async {
    await montar(tester);
    await responder(tester);

    final veredicto = find.textContaining(RegExp('Correcto|Incorrecto'));
    expect(veredicto, findsOneWidget);

    // Sin bajar sola, el caso clínico ocupaba la pantalla y el veredicto
    // quedaba debajo del borde.
    final rect = tester.getRect(veredicto);
    expect(rect.top, greaterThanOrEqualTo(0));
    expect(rect.bottom, lessThan(852 - 100));
  });

  group('Reportar', () {
    late List<Uri> abiertos;
    late bool puedeAbrir;

    setUp(() {
      abiertos = [];
      puedeAbrir = true;
      Contacto.lanzador = (uri) async {
        abiertos.add(uri);
        return puedeAbrir;
      };
    });

    tearDown(() => Contacto.lanzador = (_) async => false);

    Future<void> reportar(WidgetTester tester) async {
      await montar(tester);
      await responder(tester);

      await tester.tap(find.text('Reportar'));
      await tester.pumpAndSettle();
      // La hoja dice a dónde va el reporte antes de elegir el motivo.
      expect(find.textContaining('Se abrirá WhatsApp'), findsOneWidget);

      await tester.tap(find.text('La clave me parece equivocada'));
      await tester.pumpAndSettle();
    }

    testWidgets('abre soporte con el código de la pregunta y el motivo', (
      tester,
    ) async {
      await reportar(tester);

      expect(abiertos, hasLength(1));
      final mensaje = abiertos.single.queryParameters['text']!;
      final pregunta = (await tester.runAsync(
        () => repo.session(sesionId),
      ))!.preguntas.first;
      expect(mensaje, contains(pregunta.id));
      expect(mensaje, contains('La clave me parece equivocada'));
      // No agradece un envío que no hizo la app: lo envía la persona.
      expect(find.textContaining('Un editor va a revisarla'), findsNothing);
    });

    testWidgets('sin WhatsApp, lo dice y deja el código para escribir', (
      tester,
    ) async {
      puedeAbrir = false;
      await reportar(tester);

      expect(find.textContaining('No pudimos abrir WhatsApp'), findsOneWidget);
    });
  });
}
