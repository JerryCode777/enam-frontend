import 'package:enam_app/core/theme/app_theme.dart';
import 'package:enam_app/features/catalog/domain/catalog_models.dart';
import 'package:enam_app/features/catalog/presentation/widgets/node_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sin respuestas no hay dominio que medir (plan §6): se lee «Aún sin
/// práctica», nunca un 0 % que parecería un mal resultado.
void main() {
  Future<void> montar(WidgetTester tester, CatalogNode nodo) =>
      tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: NodeRow(nodo: nodo, onTap: () {})),
        ),
      );

  testWidgets('vistas pero sin respuestas contadas no es un 0 %', (
    tester,
  ) async {
    // El caso que salía mal: el servidor cuenta la pregunta como vista y
    // todavía no tiene respuestas. Decía «acierto 0 %».
    await montar(
      tester,
      const CatalogNode(
        id: 't',
        nombre: 'Síndrome coronario agudo',
        nivel: 'tema',
        preguntasDisponibles: 20,
        preguntasVistas: 3,
      ),
    );

    expect(find.textContaining('0 %'), findsNothing);
    expect(find.textContaining('aún sin práctica'), findsOneWidget);
  });

  testWidgets('con respuestas, el acierto real', (tester) async {
    await montar(
      tester,
      const CatalogNode(
        id: 't',
        nombre: 'Síndrome coronario agudo',
        nivel: 'tema',
        preguntasDisponibles: 20,
        preguntasVistas: 4,
        respuestasTotales: 4,
        respuestasCorrectas: 3,
      ),
    );

    expect(find.textContaining('acierto 75 %'), findsOneWidget);
  });
}
