import 'package:enam_app/core/domain/blueprint.dart';
import 'package:enam_app/core/domain/taxonomy.dart';
import 'package:enam_app/core/theme/area_colors.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verifica la taxonomía contra la Tabla de Especificaciones de ASPEFAM
/// (12 de octubre de 2025).
///
/// Si alguien transcribe mal un peso, estos tests lo detectan antes de que la
/// app calcule mal una proyección de nota.
void main() {
  group('Estructura general', () {
    test('hay exactamente 10 áreas', () {
      expect(Taxonomy.areas, hasLength(10));
    });

    test('hay exactamente 58 sub áreas', () {
      expect(Taxonomy.subAreas.length, 58);
    });

    test('las áreas suman 180 preguntas', () {
      final total = Taxonomy.areas.fold(0, (s, a) => s + (a.peso ?? 0));
      expect(total, Blueprint.totalQuestions);
    });

    test('no hay ids duplicados en todo el árbol', () {
      final ids = <String>[];
      for (final area in Taxonomy.areas) {
        ids.add(area.id);
        ids.addAll(area.descendientes.map((n) => n.id));
      }
      expect(ids.toSet().length, ids.length);
    });

    test('cada área tiene un color asignado', () {
      for (final area in Taxonomy.areas) {
        expect(
          AreaColors.knownAreaIds,
          contains(area.id),
          reason: 'Falta color para "${area.id}"',
        );
      }
    });
  });

  group('Grupos del blueprint', () {
    test('suman 90 / 60 / 30 según la tabla oficial', () {
      expect(AreaGroup.clinicoMedicas.preguntas, 90);
      expect(AreaGroup.clinicoQuirurgicas.preguntas, 60);
      expect(AreaGroup.transversales.preguntas, 30);
    });

    test('las áreas de cada grupo suman el total del grupo', () {
      for (final grupo in AreaGroup.values) {
        final suma = Taxonomy.byGroup(
          grupo,
        ).fold(0, (s, a) => s + (a.peso ?? 0));
        expect(
          suma,
          grupo.preguntas,
          reason: 'El grupo ${grupo.label} no cuadra',
        );
      }
    });

    test('los porcentajes suman 100', () {
      final suma = AreaGroup.values.fold(0.0, (s, g) => s + g.porcentaje);
      expect(suma, closeTo(1.0, 0.01));
    });
  });

  group('Pesos por área', () {
    // Los valores exactos de la Tabla de Especificaciones.
    const esperado = {
      'medicina': 40,
      'pediatria': 34,
      'emergencias': 16,
      'gineco-obstetricia': 30,
      'cirugia': 30,
      'salud-publica': 14,
      'ciencias-basicas': 10,
      'etica': 2,
      'investigacion': 2,
      'gestion': 2,
    };

    for (final entry in esperado.entries) {
      test('${entry.key} aporta ${entry.value} preguntas', () {
        expect(Taxonomy.byId(entry.key)?.peso, entry.value);
      });
    }
  });

  group('Consistencia interna de cada área', () {
    test('las sub áreas de cada área suman el peso del área', () {
      for (final area in Taxonomy.areas) {
        expect(
          area.pesoDeHijos,
          area.peso,
          reason:
              '"${area.nombre}": los hijos suman ${area.pesoDeHijos} '
              'pero el área pesa ${area.peso}',
        );
      }
    });

    test('los bloques de Gineco-Obstetricia cuadran con sus sub áreas', () {
      final go = Taxonomy.byId('gineco-obstetricia')!;
      for (final bloque in go.hijos.where(
        (h) => h.nivel == TaxonomyLevel.bloque,
      )) {
        expect(
          bloque.pesoDeHijos,
          bloque.peso,
          reason: '"${bloque.nombre}" no cuadra',
        );
      }
    });

    test('Obstetricia usa 23, no los 24 del encabezado oficial', () {
      // El documento tiene un descuadre conocido: el encabezado dice 24 pero
      // sus partes suman 23, y solo con 23 el área cierra en 30. Pendiente de
      // confirmar con ASPEFAM.
      expect(Taxonomy.byId('go-obstetricia')?.peso, 23);
    });
  });

  group('Asimetrías del árbol', () {
    test('cuatro áreas no desarrollan el tercer nivel', () {
      // Emergencias, Ética, Investigación y Gestión: 22 preguntas, 12 % del
      // examen. No es un dato faltante, es como está el documento oficial.
      const sinTercerNivel = {
        'emergencias',
        'etica',
        'investigacion',
        'gestion',
      };
      final suma = sinTercerNivel
          .map((id) => Taxonomy.byId(id)!.peso!)
          .fold(0, (a, b) => a + b);
      expect(suma, 22);
    });

    test('Gineco-Obstetricia es la única área con nivel intermedio', () {
      final conBloques = Taxonomy.areas
          .where((a) => a.hijos.any((h) => h.nivel == TaxonomyLevel.bloque))
          .map((a) => a.id)
          .toList();
      expect(conBloques, ['gineco-obstetricia']);
    });

    test('el peso varía 20 a 1 entre la mayor y la menor', () {
      final pesos = Taxonomy.areas.map((a) => a.peso!).toList()..sort();
      expect(pesos.last / pesos.first, 20);
    });

    test('las cuatro áreas mayores concentran 134 preguntas', () {
      final mayores = ['medicina', 'pediatria', 'gineco-obstetricia', 'cirugia'];
      final suma = mayores
          .map((id) => Taxonomy.byId(id)!.peso!)
          .fold(0, (a, b) => a + b);
      expect(suma, 134);
      expect(suma / Blueprint.totalQuestions, closeTo(0.744, 0.01));
    });
  });

  group('Particularidades de contenido', () {
    test('oftalmología y otorrino están en Cirugía, no como áreas propias', () {
      final cirugia = Taxonomy.byId('cirugia')!;
      final nombres = cirugia.hijos.map((h) => h.nombre).toList();
      expect(nombres, contains('Problemas en oftalmología'));
      expect(nombres, contains('Problemas en otorrinolaringología'));
    });

    test('la cirugía pediátrica está en Cirugía, no en Pediatría', () {
      expect(Taxonomy.byId('cirugia-pediatrica'), isNotNull);
      final pediatria = Taxonomy.byId('pediatria')!;
      expect(
        pediatria.hijos.any((h) => h.nombre.toLowerCase().contains('cirugía')),
        isFalse,
      );
    });

    test('la ética suma 4 preguntas repartidas en 3 áreas', () {
      // El área transversal Ética (2), más ética propia de Pediatría (1) y de
      // Gineco-Obstetricia (1). Viven en ramas separadas del árbol.
      final areaEtica = Taxonomy.byId('etica')!.peso!;
      final pediatria = Taxonomy.byId('pediatria-etica')!.peso!;
      final gineco = Taxonomy.byId('go-etica')!.peso!;
      expect(areaEtica + pediatria + gineco, 4);
    });

    test('Emergencias se organiza por falla orgánica', () {
      final emergencias = Taxonomy.byId('emergencias')!;
      final porFalla = emergencias.hijos
          .where((h) => h.nombre.toLowerCase().contains('falla'))
          .length;
      expect(porFalla, greaterThanOrEqualTo(7));
    });
  });

  group('Navegación del árbol', () {
    test('pathTo devuelve la ruta completa hasta una sub área anidada', () {
      final path = Taxonomy.pathTo('go-parto');
      expect(path.map((n) => n.id), [
        'gineco-obstetricia',
        'go-obstetricia',
        'go-parto',
      ]);
    });

    test('pathTo devuelve un solo nodo para un área', () {
      expect(Taxonomy.pathTo('medicina').map((n) => n.id), ['medicina']);
    });

    test('pathTo devuelve vacío para un id inexistente', () {
      expect(Taxonomy.pathTo('no-existe'), isEmpty);
    });

    test('byId encuentra nodos en cualquier profundidad', () {
      expect(Taxonomy.byId('medicina')?.nivel, TaxonomyLevel.area);
      expect(Taxonomy.byId('go-obstetricia')?.nivel, TaxonomyLevel.bloque);
      expect(Taxonomy.byId('go-parto')?.nivel, TaxonomyLevel.subArea);
      expect(Taxonomy.byId('no-existe'), isNull);
    });

    test('las hojas de un área son sus sub áreas más específicas', () {
      final go = Taxonomy.byId('gineco-obstetricia')!;
      // 6 de ginecología + 6 de obstetricia + 1 de ética = 13.
      expect(go.hojas.length, 13);
    });
  });

  group('Longitud de nombres', () {
    test('ningún nombre de sub área pasa de 80 caracteres', () {
      for (final sub in Taxonomy.subAreas) {
        expect(
          sub.nombre.length,
          lessThanOrEqualTo(80),
          reason: 'Nombre inesperadamente largo: "${sub.nombre}"',
        );
      }
    });

    test('existe el caso de 75 caracteres que la UI debe soportar', () {
      final masLargo = Taxonomy.subAreas
          .map((s) => s.nombre.length)
          .reduce((a, b) => a > b ? a : b);
      expect(masLargo, greaterThanOrEqualTo(70));
    });
  });
}
