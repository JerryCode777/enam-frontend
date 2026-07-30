import 'package:enam_app/core/mock/mock_data.dart';
import 'package:enam_app/features/catalog/domain/catalog_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verifica el árbol del catálogo y la derivación de estados.
///
/// Los casos que se prueban son los que el temario oficial hace irregulares:
/// áreas sin tercer nivel, la capa de bloques de Gineco y los nodos sin
/// preguntas cargadas.
void main() {
  late List<CatalogNode> arbol;

  setUp(() => arbol = MockData.catalog());

  CatalogNode area(String id) => arbol.firstWhere((a) => a.id == id);

  CatalogNode? buscar(String id) {
    for (final a in arbol) {
      final encontrado = a.buscar(id);
      if (encontrado != null) return encontrado;
    }
    return null;
  }

  group('Estructura del árbol', () {
    test('hay 10 áreas raíz', () {
      expect(arbol, hasLength(10));
    });

    test('las áreas suman 180 preguntas de blueprint', () {
      final total = arbol.fold(0, (s, a) => s + (a.peso ?? 0));
      expect(total, 180);
    });

    test('las 58 sub áreas están presentes', () {
      var subAreas = 0;
      for (final a in arbol) {
        subAreas += a.descendientes.where((n) => n.nivel == 'sub_area').length;
      }
      expect(subAreas, 58);
    });

    test('Gineco-Obstetricia es la única con nivel de bloque', () {
      final conBloques = arbol
          .where((a) => a.hijos.any((h) => h.nivel == 'bloque'))
          .map((a) => a.id)
          .toList();
      expect(conBloques, ['gineco-obstetricia']);
    });

    test('las 4 áreas sin tercer nivel no tienen temas', () {
      // RF-37: la navegación termina en la sub área. No es dato faltante.
      for (final id in ['emergencias', 'etica', 'investigacion', 'gestion']) {
        final temas = area(id).descendientes.where((n) => n.esTema);
        expect(temas, isEmpty, reason: '"$id" no debería tener temas');
      }
    });

    test('Medicina sí desarrolla temas', () {
      expect(area('medicina').totalTemas, greaterThan(0));
    });

    test('los bloques de Gineco cuadran con sus sub áreas', () {
      final go = area('gineco-obstetricia');
      for (final bloque in go.hijos.where((h) => h.nivel == 'bloque')) {
        final suma = bloque.hijos.fold(0, (s, h) => s + (h.peso ?? 0));
        expect(suma, bloque.peso, reason: '"${bloque.nombre}" no cuadra');
      }
    });
  });

  group('Estado del nodo (RF-36, RF-40)', () {
    test('sin preguntas disponibles es sinContenido, no un error', () {
      const nodo = CatalogNode(
        id: 'x',
        nombre: 'Tema nuevo',
        nivel: 'tema',
        preguntasDisponibles: 0,
      );
      expect(nodo.estado, NodeState.sinContenido);
    });

    test('con preguntas pero ninguna vista es sinEmpezar', () {
      const nodo = CatalogNode(
        id: 'x',
        nombre: 'T',
        nivel: 'tema',
        preguntasDisponibles: 10,
      );
      expect(nodo.estado, NodeState.sinEmpezar);
    });

    test('vistas todas es agotado', () {
      const nodo = CatalogNode(
        id: 'x',
        nombre: 'T',
        nivel: 'tema',
        preguntasDisponibles: 10,
        preguntasVistas: 10,
        respuestasTotales: 10,
        respuestasCorrectas: 6,
      );
      expect(nodo.estado, NodeState.agotado);
    });

    test('buen acierto y buena cobertura es dominado', () {
      const nodo = CatalogNode(
        id: 'x',
        nombre: 'T',
        nivel: 'tema',
        preguntasDisponibles: 10,
        preguntasVistas: 8,
        respuestasTotales: 8,
        respuestasCorrectas: 7, // 87 %
      );
      expect(nodo.estado, NodeState.dominado);
    });

    test('buen acierto con poca cobertura sigue en curso', () {
      // Acertar 2 de 2 no significa dominar un tema de 10 preguntas.
      const nodo = CatalogNode(
        id: 'x',
        nombre: 'T',
        nivel: 'tema',
        preguntasDisponibles: 10,
        preguntasVistas: 2,
        respuestasTotales: 2,
        respuestasCorrectas: 2,
      );
      expect(nodo.estado, NodeState.enCurso);
    });

    test('preguntasRestantes nunca es negativo', () {
      const nodo = CatalogNode(
        id: 'x',
        nombre: 'T',
        nivel: 'tema',
        preguntasDisponibles: 5,
        preguntasVistas: 9, // dato inconsistente del servidor
      );
      expect(nodo.preguntasRestantes, 0);
    });
  });

  group('Porcentaje de acierto', () {
    test('sin respuestas es null, no cero', () {
      // Un 0 % se lee como mal resultado; "sin datos" es la verdad.
      const nodo = CatalogNode(id: 'x', nombre: 'T', nivel: 'tema');
      expect(nodo.porcentajeAcierto, isNull);
    });

    test('con respuestas calcula la proporción', () {
      const nodo = CatalogNode(
        id: 'x',
        nombre: 'T',
        nivel: 'tema',
        respuestasTotales: 4,
        respuestasCorrectas: 3,
      );
      expect(nodo.porcentajeAcierto, 0.75);
    });

    test('la cobertura se acota a 1.0', () {
      const nodo = CatalogNode(
        id: 'x',
        nombre: 'T',
        nivel: 'tema',
        preguntasDisponibles: 4,
        preguntasVistas: 10,
      );
      expect(nodo.cobertura, 1.0);
    });
  });

  group('Densidad de estudio', () {
    test('Ciencias Básicas rinde más por tema que Medicina', () {
      final medicina = area('medicina').temasPorPregunta;
      final basicas = area('ciencias-basicas').temasPorPregunta;

      expect(medicina, isNotNull);
      expect(basicas, isNotNull);
      expect(basicas!, lessThan(medicina!));
    });

    test('un área sin temas no reporta densidad', () {
      expect(area('etica').temasPorPregunta, isNull);
    });
  });

  group('Agregación de progreso', () {
    test('un área agrega el progreso de sus descendientes', () {
      final medicina = area('medicina');
      final sumaHijos = medicina.hijos.fold(
        0,
        (s, h) => s + h.preguntasDisponibles,
      );
      expect(medicina.preguntasDisponibles, sumaHijos);
    });

    test('Gineco tiene 13 sub áreas repartidas en sus bloques', () {
      // 6 de ginecología + 6 de obstetricia + 1 de ética, contando las que
      // cuelgan de los bloques y la que cuelga del área directamente.
      final go = area('gineco-obstetricia');
      final subAreas = go.descendientes.where((n) => n.nivel == 'sub_area');
      expect(subAreas.length, 13);
    });

    test('Gineco sí desarrolla temas, a diferencia de Emergencias', () {
      expect(area('gineco-obstetricia').totalTemas, greaterThan(0));
      expect(area('emergencias').totalTemas, 0);
    });
  });

  group('Búsqueda del árbol', () {
    test('encuentra un nodo anidado por id', () {
      expect(buscar('go-parto')?.nombre, 'Parto');
    });

    test('oftalmología vive dentro de Cirugía', () {
      // El caso real: alguien la buscaría como área propia y no está.
      final cirugia = area('cirugia');
      expect(
        cirugia.hijos.map((h) => h.nombre),
        contains('Problemas en oftalmología'),
      );
    });

    test('devuelve null para un id inexistente', () {
      expect(buscar('no-existe'), isNull);
    });
  });
}
