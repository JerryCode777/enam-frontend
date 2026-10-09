import 'package:enam_app/core/config/contacto.dart';
import 'package:enam_app/core/error/failure.dart';
import 'package:enam_app/core/providers.dart';
import 'package:enam_app/core/theme/app_theme.dart';
import 'package:enam_app/core/theme/design_tokens.dart';
import 'package:enam_app/features/session/data/reportes_repository.dart';
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

  Future<void> montar(
    WidgetTester tester, {
    ReportesRepository? reportes,
  }) async {
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
        overrides: [
          sessionRepositoryProvider.overrideWithValue(repo),
          reportesRepositoryProvider.overrideWithValue(
            reportes ?? MockReportesRepository(),
          ),
        ],
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
    late _ReportesFalsos reportes;

    setUp(() {
      abiertos = [];
      puedeAbrir = true;
      reportes = _ReportesFalsos();
      Contacto.lanzador = (uri) async {
        abiertos.add(uri);
        return puedeAbrir;
      };
    });

    tearDown(() => Contacto.lanzador = (_) async => false);

    Future<void> reportar(WidgetTester tester) async {
      await montar(tester, reportes: reportes);
      await responder(tester);

      await tester.tap(find.text('Reportar'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Lo enviamos a soporte'), findsOneWidget);

      await tester.tap(find.text('La clave me parece equivocada'));
      await tester.pumpAndSettle();
    }

    testWidgets('va al servidor con el motivo y lo confirma', (tester) async {
      await reportar(tester);

      expect(reportes.recibidos, hasLength(1));
      final r = reportes.recibidos.single;
      expect(r.motivo, 'clave');
      expect(r.sessionId, sesionId);
      expect(find.text('Reporte enviado. Gracias por avisar.'), findsOneWidget);
      // Llegó por la app: no hace falta abrir WhatsApp.
      expect(abiertos, isEmpty);
    });

    testWidgets('con un backend sin el endpoint, cae al WhatsApp', (
      tester,
    ) async {
      reportes.fallo = const NotFoundFailure();
      await reportar(tester);

      expect(abiertos, hasLength(1));
      final mensaje = abiertos.single.queryParameters['text']!;
      expect(mensaje, contains(reportes.intentos.single));
      expect(mensaje, contains('La clave me parece equivocada'));
      expect(find.textContaining('Reporte enviado'), findsNothing);
    });

    testWidgets('sin red, también cae al WhatsApp', (tester) async {
      reportes.fallo = const NetworkFailure();
      await reportar(tester);
      expect(abiertos, hasLength(1));
    });

    testWidgets('si el servidor pide esperar, no lo salta por WhatsApp', (
      tester,
    ) async {
      reportes.fallo = const RateLimitFailure('Espera un momento.');
      await reportar(tester);

      expect(abiertos, isEmpty);
      expect(find.text('Espera un momento.'), findsOneWidget);
    });

    testWidgets('sin endpoint y sin WhatsApp, lo dice y deja el código', (
      tester,
    ) async {
      reportes.fallo = const NetworkFailure();
      puedeAbrir = false;
      await reportar(tester);

      expect(
        find.textContaining('No pudimos enviar el reporte'),
        findsOneWidget,
      );
      expect(find.textContaining('Un editor va a revisarla'), findsNothing);
    });
  });
}

class _ReportesFalsos implements ReportesRepository {
  Failure? fallo;
  final recibidos = <({String motivo, String? sessionId})>[];

  /// Ids de pregunta de todos los intentos, hayan llegado o no.
  final intentos = <String>[];

  @override
  Future<ReporteRecibido> reportar({
    required String preguntaId,
    required String motivo,
    String? comentario,
    String? sessionId,
  }) async {
    intentos.add(preguntaId);
    if (fallo case final f?) throw f;
    recibidos.add((motivo: motivo, sessionId: sessionId));
    return (id: 'r1', estado: 'recibido');
  }
}
