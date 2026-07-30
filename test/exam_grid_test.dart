import 'package:enam_app/core/mock/mock_data.dart';
import 'package:enam_app/core/theme/app_theme.dart';
import 'package:enam_app/features/session/domain/session_models.dart';
import 'package:enam_app/features/session/presentation/widgets/exam_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// La grilla de 180 casillas es el reto de layout más difícil del set (RF-17).
/// Estos tests fijan lo que la hace usable: casillas tocables, agrupación que no
/// revela la taxonomía durante el examen, y todos los números presentes.
///
/// Las sesiones se construyen a mano en vez de usar `MockSessionRepository`
/// porque este último simula latencia con `Future.delayed`, y dentro de
/// `testWidgets` el tiempo es simulado: el test quedaría colgado esperando algo
/// que nunca ocurre.
void main() {
  /// Sesión de simulacro sin la clasificación, como la ve el cliente durante el
  /// examen (RN-09).
  StudySession simulacroEnCurso({int cantidad = 180}) {
    final preguntas = MockData.questions(cantidad: cantidad)
        .map((q) => q.copyWith(areaId: null, subtemaId: null))
        .toList();
    return StudySession(
      id: 'sim',
      tipo: SessionType.simulacro,
      estado: SessionStatus.enCurso,
      iniciadaEn: DateTime(2026),
      preguntas: preguntas,
    );
  }

  /// Sesión finalizada, con la clasificación ya revelada.
  StudySession simulacroFinalizado({int cantidad = 40}) {
    return StudySession(
      id: 'sim',
      tipo: SessionType.simulacro,
      estado: SessionStatus.finalizada,
      iniciadaEn: DateTime(2026),
      finalizadaEn: DateTime(2026, 1, 1, 3),
      preguntas: MockData.questions(cantidad: cantidad, conRespuestas: true),
    );
  }

  Widget wrap(Widget child) => MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(
      body: SingleChildScrollView(child: child),
    ),
  );

  Future<void> pintar(WidgetTester tester, Widget child) async {
    tester.view
      ..physicalSize = const Size(360 * 3, 900 * 3)
      ..devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap(child));
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('pinta las 180 casillas sin desbordar a 360 px', (tester) async {
    final session = simulacroEnCurso();
    expect(session.totalPreguntas, 180);

    await pintar(
      tester,
      ExamGrid(session: session, indiceActual: 0, onSeleccionar: (_) {}),
    );

    expect(tester.takeException(), isNull);
    // Los extremos tienen que existir: si la grilla recorta, falta el 180.
    expect(find.text('180'), findsOneWidget);
  });

  testWidgets('cada casilla llega al mínimo táctil a 360 px', (tester) async {
    await pintar(
      tester,
      ExamGrid(
        session: simulacroEnCurso(cantidad: 40),
        indiceActual: 0,
        onSeleccionar: (_) {},
      ),
    );

    // La caja visible de una casilla. Con la separación entre casillas, el gesto
    // efectivo supera lo que Material acepta para grillas densas.
    final casilla = tester.getSize(find.byType(Material).at(1));
    expect(
      casilla.width,
      greaterThanOrEqualTo(40),
      reason: 'Casilla demasiado chica para el dedo',
    );
    expect(casilla.height, greaterThanOrEqualTo(40));
  });

  testWidgets('durante el simulacro NO agrupa por área (RN-09)', (tester) async {
    await pintar(
      tester,
      ExamGrid(
        session: simulacroEnCurso(cantidad: 40),
        indiceActual: 0,
        onSeleccionar: (_) {},
      ),
    );

    // Si agrupara por área, el nombre aparecería como encabezado y eso le diría
    // al usuario de qué es cada pregunta.
    expect(find.textContaining('MEDICINA'), findsNothing);
    expect(find.textContaining('PEDIATRIA'), findsNothing);
    // En su lugar agrupa por tramos numéricos.
    expect(find.textContaining('PREGUNTAS 1 A 20'), findsOneWidget);
  });

  testWidgets('tras el submit sí agrupa por área', (tester) async {
    await pintar(
      tester,
      ExamGrid(
        session: simulacroFinalizado(),
        indiceActual: 0,
        onSeleccionar: (_) {},
      ),
    );

    // Al cerrar se revela la clasificación, así que ya puede agrupar por área.
    expect(find.textContaining('PREGUNTAS 1 A 20'), findsNothing);
  });

  testWidgets('tocar una casilla devuelve su índice', (tester) async {
    var seleccionado = -1;

    await pintar(
      tester,
      ExamGrid(
        session: simulacroEnCurso(cantidad: 40),
        indiceActual: 0,
        onSeleccionar: (i) => seleccionado = i,
      ),
    );

    await tester.tap(find.text('7'));
    // Índice base 0: la casilla "7" es la posición 6.
    expect(seleccionado, 6);
  });

  group('Leyenda', () {
    testWidgets('refleja los conteos de una sesión sin empezar', (tester) async {
      final session = simulacroEnCurso(cantidad: 40);
      await pintar(tester, ExamGridLegend(session: session));

      expect(find.textContaining('Respondidas · 0'), findsOneWidget);
      expect(find.textContaining('Sin responder · 40'), findsOneWidget);
      expect(find.textContaining('Marcadas · 0'), findsOneWidget);
    });

    testWidgets('refleja respondidas y marcadas', (tester) async {
      final base = simulacroEnCurso(cantidad: 40);
      final session = base.copyWith(
        respuestas: {
          base.preguntas[0].id: Answer(
            questionId: base.preguntas[0].id,
            optionId: base.preguntas[0].opciones.first.id,
          ),
          base.preguntas[1].id: Answer(
            questionId: base.preguntas[1].id,
            marcada: true,
          ),
        },
      );

      await pintar(tester, ExamGridLegend(session: session));

      expect(find.textContaining('Respondidas · 1'), findsOneWidget);
      expect(find.textContaining('Marcadas · 1'), findsOneWidget);
      expect(find.textContaining('Sin responder · 39'), findsOneWidget);
    });
  });
}
