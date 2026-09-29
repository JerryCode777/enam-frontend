import 'package:enam_app/core/providers.dart';
import 'package:enam_app/core/theme/app_theme.dart';
import 'package:enam_app/features/session/data/session_repository.dart';
import 'package:enam_app/features/session/domain/session_models.dart';
import 'package:enam_app/features/session/presentation/session_summary_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayuda/offline.dart';

/// El resumen de una práctica (plan §6): cifras que cuadran, contexto honesto
/// y una siguiente acción concreta.
void main() {
  /// 10 preguntas: 2 correctas, 5 incorrectas y 3 en blanco, 30 s cada una.
  StudySession sesion({int incorrectas = 5}) {
    final base = sesionDePrueba(cuantas: 10);
    final respuestas = <String, Answer>{};
    for (final (i, p) in base.preguntas.indexed) {
      final enBlanco = i >= 2 + incorrectas;
      respuestas[p.id] = Answer(
        questionId: p.id,
        optionId: enBlanco ? null : p.opciones.first.id,
        esCorrecta: enBlanco ? false : i < 2,
        tiempoMs: 30000,
      );
    }
    return base.copyWith(
      estado: SessionStatus.finalizada,
      respuestas: respuestas,
    );
  }

  Future<void> montar(WidgetTester tester, StudySession s) async {
    tester.view
      ..physicalSize = const Size(393, 852) * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sessionRepositoryProvider.overrideWithValue(_Fija(s))],
        child: MaterialApp(
          theme: AppTheme.light,
          home: SessionSummaryScreen(sessionId: s.id),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  testWidgets('las en blanco no se cuentan como falladas', (tester) async {
    await montar(tester, sesion());

    // Antes: «Fallaste 8» y «Dejaste en blanco 3» con 2 correctas de 10.
    Finder cifra(String etiqueta) => find.byWidgetPredicate(
      (w) => w is Semantics && w.properties.label == etiqueta,
    );
    expect(cifra('2 correctas'), findsOneWidget);
    expect(cifra('5 incorrectas'), findsOneWidget);
    expect(cifra('3 en blanco'), findsOneWidget);
    expect(find.text('Repasar las 5 incorrectas'), findsOneWidget);
  });

  testWidgets('dice qué fue, sin compararlo con la nota del examen', (
    tester,
  ) async {
    await montar(tester, sesion());
    expect(
      find.text('Resultado de tu práctica · 10 preguntas'),
      findsOneWidget,
    );
    expect(find.textContaining('aprob'), findsNothing);
  });

  testWidgets('el tiempo sale de lo que se tardó en responder', (tester) async {
    await montar(tester, sesion());
    // 10 preguntas × 30 s: las dejadas en blanco también se leyeron.
    expect(find.text('5 min en total · 30 s por pregunta'), findsOneWidget);
  });

  testWidgets('sin incorrectas, la siguiente acción es otra práctica', (
    tester,
  ) async {
    await montar(tester, sesion(incorrectas: 0));
    expect(find.text('Otra práctica'), findsOneWidget);
    expect(find.textContaining('Repasar'), findsNothing);
  });
}

class _Fija implements SessionRepository {
  _Fija(this.s);

  final StudySession s;

  @override
  Future<StudySession> session(String id) async => s;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
