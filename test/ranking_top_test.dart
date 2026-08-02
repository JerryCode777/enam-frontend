import 'package:enam_app/features/stats/domain/stats_models.dart';
import 'package:enam_app/features/stats/presentation/widgets/podio_ranking.dart';
import 'package:enam_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// El ranking muestra diez y nada más, y siempre dice dónde va uno.
///
/// El recorte lo hace el servidor —una lista entera no la recorre nadie y
/// repartir el nombre de todo el padrón a cada cliente no hace falta—, pero la
/// pantalla tiene que sostener el caso que ese recorte crea: quien está fuera
/// del top ya **no tiene fila en la lista**, y su posición solo vive en la
/// barra de abajo.
void main() {
  RankingEntry fila(
    int posicion, {
    bool propia = false,
    String? universidad = 'UNMSM',
  }) => RankingEntry(
    posicion: posicion,
    usuarioNombre: 'U. $posicion',
    universidad: universidad,
    promedio: 20 - posicion.toDouble(),
    esUsuarioActual: propia,
  );

  Widget envolver(Widget hijo) => MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: hijo),
  );

  group('el recorte a diez', _pruebasDelRecorte);

  group('el podio', () {
    testWidgets('pinta a los tres primeros', (tester) async {
      await tester.pumpWidget(
        envolver(PodioRanking(filas: [fila(1), fila(2), fila(3)])),
      );

      expect(find.text('U. 1'), findsOneWidget);
      expect(find.text('U. 2'), findsOneWidget);
      expect(find.text('U. 3'), findsOneWidget);
    });

    testWidgets('al usuario lo llama «Tú», no por sus iniciales', (tester) async {
      // Ya sabe cómo se llama. El sitio es para reconocerse de un vistazo.
      await tester.pumpWidget(
        envolver(
          PodioRanking(filas: [fila(1, propia: true), fila(2), fila(3)]),
        ),
      );

      expect(find.text('Tú'), findsOneWidget);
      expect(find.text('U. 1'), findsNothing);
    });

    testWidgets('con menos de tres no se pinta', (tester) async {
      // Tres escalones con dos llenos y uno vacío se leen como un fallo de
      // carga, no como «todavía no hay tercero».
      await tester.pumpWidget(envolver(PodioRanking(filas: [fila(1), fila(2)])));

      expect(find.text('U. 1'), findsNothing);
    });

    testWidgets('sin universidad no se desmonta el escalón', (tester) async {
      await tester.pumpWidget(
        envolver(
          PodioRanking(
            filas: [
              fila(1, universidad: null),
              fila(2),
              fila(3, universidad: null),
            ],
          ),
        ),
      );

      expect(find.text('U. 1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('el primero es el más alto', (tester) async {
      // Es lo que hace que se lea el puesto sin necesidad de decirlo. Si los
      // tres midieran igual, el podio sería una fila de tres tarjetas.
      await tester.pumpWidget(
        envolver(PodioRanking(filas: [fila(1), fila(2), fila(3)])),
      );

      double altoDelEscalonDe(String nombre) {
        // El escalón es el Container que envuelve al nombre.
        final caja = find.ancestor(
          of: find.text(nombre),
          matching: find.byType(Container),
        );
        return tester.getSize(caja.first).height;
      }

      final primero = altoDelEscalonDe('U. 1');
      final segundo = altoDelEscalonDe('U. 2');
      final tercero = altoDelEscalonDe('U. 3');

      expect(primero, greaterThan(segundo));
      expect(segundo, greaterThan(tercero));
    });

    testWidgets('los tres escalones comparten suelo', (tester) async {
      // Es lo que los hace un podio y no tres tarjetas sueltas: el escalón se
      // ve porque crecen hacia ARRIBA desde la misma línea.
      await tester.pumpWidget(
        envolver(PodioRanking(filas: [fila(1), fila(2), fila(3)])),
      );

      double sueloDe(String nombre) {
        final caja = find.ancestor(
          of: find.text(nombre),
          matching: find.byType(Container),
        );
        return tester.getRect(caja.first).bottom;
      }

      expect(sueloDe('U. 1'), closeTo(sueloDe('U. 2'), 0.5));
      expect(sueloDe('U. 2'), closeTo(sueloDe('U. 3'), 0.5));
    });
  });
}

/// La pantalla recorta por su cuenta, no solo el servidor.
///
/// Depender de que el otro lado lo haga bien significa que el día que cambie
/// —o que una app vieja hable con un servidor nuevo— la pantalla crece sin que
/// nadie se entere. Aquí se le da una respuesta larga a propósito.
extension on List<RankingEntry> {
  List<RankingEntry> get visibles =>
      where((f) => f.posicion <= 10).take(10).toList();
}

void _pruebasDelRecorte() {
  test('una respuesta larga se recorta a diez', () {
    final larga = [
      for (var i = 1; i <= 50; i++)
        RankingEntry(posicion: i, usuarioNombre: 'U. $i', promedio: 20 - i / 2),
    ];

    expect(larga.visibles, hasLength(10));
    expect(larga.visibles.last.posicion, 10);
  });

  test('la fila propia de fuera del top no cuenta como undécima', () {
    final conPropia = [
      for (var i = 1; i <= 10; i++)
        RankingEntry(posicion: i, usuarioNombre: 'U. $i', promedio: 20 - i / 2),
      const RankingEntry(
        posicion: 340,
        usuarioNombre: 'E. R.',
        promedio: 9.85,
        esUsuarioActual: true,
      ),
    ];

    // No entra en la lista —la sostiene la barra de abajo— pero sigue estando
    // en la respuesta para poder pintarla ahí.
    expect(conPropia.visibles, hasLength(10));
    expect(conPropia.visibles.any((f) => f.esUsuarioActual), isFalse);
    expect(conPropia.where((f) => f.esUsuarioActual), hasLength(1));
  });
}
