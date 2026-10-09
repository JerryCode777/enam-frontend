import 'package:enam_app/features/catalog/domain/catalog_models.dart';
import 'package:enam_app/features/home/domain/siguiente_accion.dart';
import 'package:enam_app/features/stats/domain/stats_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// La regla del inicio contextual (plan de rediseño §5).
///
/// Cada estado tiene una siguiente acción distinta, y ninguna inventa cifras.
/// La web aplica la misma regla en el mismo orden; si esto cambia, hay que
/// cambiarla allí también.
void main() {
  const medicina = CatalogNode(
    id: 'medicina',
    nombre: 'Medicina',
    nivel: 'area',
    peso: 40,
  );
  const pediatria = CatalogNode(
    id: 'pediatria',
    nombre: 'Pediatría',
    nivel: 'area',
    peso: 34,
  );

  DashboardStats stats({int respondidas = 0}) => DashboardStats(
    notaProyectada: 0,
    porArea: [
      AreaPerformance(
        areaId: 'medicina',
        areaNombre: 'Medicina',
        preguntasBlueprint: 40,
        respondidas: respondidas,
        correctas: respondidas ~/ 2,
      ),
    ],
  );

  const abierta = (
    sessionId: 's1',
    esSimulacro: false,
    respondidas: 7,
    total: 20,
  );

  SiguienteAccion decidir({
    ({String sessionId, bool esSimulacro, int respondidas, int total})?
    sesion,
    bool sinRed = false,
    int offline = 0,
    DashboardStats? dashboard,
    List<({CatalogNode area, double? acierto})> prioridades = const [],
  }) => decidirSiguienteAccion(
    sesionAbierta: sesion,
    sinRed: sinRed,
    practicasOffline: offline,
    stats: dashboard,
    prioridades: prioridades,
  );

  group('Prioridad', () {
    test('una sesión abierta gana a todo lo demás', () {
      final accion = decidir(
        sesion: abierta,
        sinRed: true,
        dashboard: stats(respondidas: 100),
        prioridades: [(area: medicina, acierto: 0.5)],
      );

      expect(accion, isA<RetomarSesion>());
      final r = accion as RetomarSesion;
      expect(r.sessionId, 's1');
      expect(r.siguiente, 8);
    });

    test('sin red y sin sesión abierta, se ofrece lo descargado', () {
      final accion = decidir(
        sinRed: true,
        offline: 2,
        dashboard: stats(respondidas: 100),
        prioridades: [(area: medicina, acierto: 0.5)],
      );

      expect(accion, isA<EstudiarSinConexion>());
      expect((accion as EstudiarSinConexion).practicasListas, 2);
    });

    test('sin ninguna respuesta, una primera práctica corta', () {
      expect(decidir(dashboard: stats()), isA<PrimeraPractica>());
      expect(PrimeraPractica.cantidad, 10);
    });

    test('con historial, el área que el algoritmo pone primera', () {
      final accion = decidir(
        dashboard: stats(respondidas: 60),
        prioridades: [
          (area: medicina, acierto: 0.52),
          (area: pediatria, acierto: 0.8),
        ],
      );

      expect(accion, isA<PracticarArea>());
      expect((accion as PracticarArea).area.id, 'medicina');
    });

    test('con el dashboard caído, elegir un área sin porcentajes', () {
      expect(decidir(), isA<ElegirArea>());
    });

    test('con historial pero sin catálogo, elegir un área', () {
      expect(decidir(dashboard: stats(respondidas: 60)), isA<ElegirArea>());
    });
  });

  group('El criterio que se muestra', () {
    test('dice el peso y el acierto real', () {
      const accion = PracticarArea(area: medicina, acierto: 0.524);
      expect(
        accion.criterio,
        'Pesa 40 preguntas en el ENAM y vas en 52 % de acierto.',
      );
    });

    test('sin acierto medido no inventa un porcentaje', () {
      const accion = PracticarArea(area: medicina);
      expect(
        accion.criterio,
        'Pesa 40 preguntas en el ENAM y aún no la practicas.',
      );
      expect(accion.criterio, isNot(contains('%')));
    });
  });

  test('la pregunta siguiente nunca pasa del total', () {
    const r = RetomarSesion(
      sessionId: 's',
      esSimulacro: false,
      respondidas: 20,
      total: 20,
    );
    expect(r.siguiente, 20);
  });
}
