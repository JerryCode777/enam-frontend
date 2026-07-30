// Genera el seed SQL de la taxonomía a partir de `Taxonomy`.
//
// La taxonomía del frontend está validada por 31 tests contra la Tabla de
// Especificaciones. Generar el seed desde ahí, en vez de transcribir 58 filas a
// mano, elimina la única forma realista de que los pesos difieran entre app y
// base de datos.
//
//   dart run tool/generate_seed.dart > ../docs/seed_taxonomia.sql
//
// Volver a correrlo si cambia `lib/core/domain/taxonomy.dart`.

import 'package:enam_app/core/domain/blueprint.dart';
import 'package:enam_app/core/domain/taxonomy.dart';

void main() {
  final b = StringBuffer();

  b
    ..writeln('-- =========================================================')
    ..writeln('-- Seed de la taxonomía oficial del ENAM')
    ..writeln('--')
    ..writeln('-- GENERADO. No editar a mano.')
    ..writeln('-- Fuente: enam-frontend/lib/core/domain/taxonomy.dart')
    ..writeln('-- Origen: Tabla de Especificaciones de ASPEFAM, 12.10.2025')
    ..writeln('--')
    ..writeln('-- ${Taxonomy.areas.length} áreas · ${Taxonomy.subAreas.length} '
        'sub áreas · ${Blueprint.totalQuestions} preguntas')
    ..writeln('--')
    ..writeln('-- Los pesos son configurables a propósito (RN-02): ASPEFAM')
    ..writeln('-- puede cambiarlos y el generador de simulacros los lee de aquí,')
    ..writeln('-- no del código.')
    ..writeln('-- =========================================================')
    ..writeln()
    ..writeln('BEGIN;')
    ..writeln()
    ..writeln('-- Idempotente: se puede correr sobre una base ya sembrada.')
    ..writeln('INSERT INTO areas (id, nombre, grupo, preguntas_blueprint, orden)')
    ..writeln('VALUES');

  final areas = <String>[];
  for (var i = 0; i < Taxonomy.areas.length; i++) {
    final a = Taxonomy.areas[i];
    areas.add(
      "  ('${a.id}', '${_esc(a.nombre)}', '${_grupo(a.grupo!)}', "
      '${a.peso}, ${i + 1})',
    );
  }
  b
    ..writeln(areas.join(',\n'))
    ..writeln('ON CONFLICT (id) DO UPDATE SET')
    ..writeln('  nombre = EXCLUDED.nombre,')
    ..writeln('  grupo = EXCLUDED.grupo,')
    ..writeln('  preguntas_blueprint = EXCLUDED.preguntas_blueprint,')
    ..writeln('  orden = EXCLUDED.orden;')
    ..writeln();

  // Sub áreas y bloques. `parent_id` apunta al área o al bloque, y `nivel`
  // distingue los dos casos.
  b
    ..writeln('INSERT INTO subtopics (id, area_id, parent_id, nombre, nivel, '
        'preguntas_blueprint, orden)')
    ..writeln('VALUES');

  final filas = <String>[];
  for (final area in Taxonomy.areas) {
    var orden = 0;
    for (final hijo in area.hijos) {
      orden++;
      filas.add(_fila(hijo, area.id, null, orden));

      // Los bloques de Gineco-Obstetricia cuelgan sus propias sub áreas.
      var subOrden = 0;
      for (final nieto in hijo.hijos) {
        subOrden++;
        filas.add(_fila(nieto, area.id, hijo.id, subOrden));
      }
    }
  }

  b
    ..writeln(filas.join(',\n'))
    ..writeln('ON CONFLICT (id) DO UPDATE SET')
    ..writeln('  area_id = EXCLUDED.area_id,')
    ..writeln('  parent_id = EXCLUDED.parent_id,')
    ..writeln('  nombre = EXCLUDED.nombre,')
    ..writeln('  nivel = EXCLUDED.nivel,')
    ..writeln('  preguntas_blueprint = EXCLUDED.preguntas_blueprint,')
    ..writeln('  orden = EXCLUDED.orden;')
    ..writeln()
    ..writeln('-- Comprobaciones. Si alguna falla, la transacción se revierte y')
    ..writeln('-- la base no queda a medias.')
    ..writeln('DO \$\$')
    ..writeln('DECLARE')
    ..writeln('  total_areas INT;')
    ..writeln('  total_sub INT;')
    ..writeln('BEGIN')
    ..writeln('  SELECT SUM(preguntas_blueprint) INTO total_areas FROM areas;')
    ..writeln('  IF total_areas <> ${Blueprint.totalQuestions} THEN')
    ..writeln("    RAISE EXCEPTION 'Las áreas suman %, deberían sumar "
        "${Blueprint.totalQuestions}', total_areas;")
    ..writeln('  END IF;')
    ..writeln()
    ..writeln("  SELECT COUNT(*) INTO total_sub FROM subtopics "
        "WHERE nivel = 'sub_area';")
    ..writeln('  IF total_sub <> ${Taxonomy.subAreas.length} THEN')
    ..writeln("    RAISE EXCEPTION 'Hay % sub áreas, deberían ser "
        "${Taxonomy.subAreas.length}', total_sub;")
    ..writeln('  END IF;')
    ..writeln('END \$\$;')
    ..writeln()
    ..writeln('COMMIT;');

  // ignore: avoid_print
  print(b.toString());
}

String _fila(TaxonomyNode nodo, String areaId, String? parentId, int orden) {
  final parent = parentId == null ? 'NULL' : "'$parentId'";
  return "  ('${nodo.id}', '$areaId', $parent, '${_esc(nodo.nombre)}', "
      "'${_nivel(nodo.nivel)}', ${nodo.peso}, $orden)";
}

String _nivel(TaxonomyLevel n) => switch (n) {
  TaxonomyLevel.area => 'area',
  TaxonomyLevel.bloque => 'bloque',
  TaxonomyLevel.subArea => 'sub_area',
  TaxonomyLevel.tema => 'tema',
};

String _grupo(AreaGroup g) => switch (g) {
  AreaGroup.clinicoMedicas => 'clinico_medicas',
  AreaGroup.clinicoQuirurgicas => 'clinico_quirurgicas',
  AreaGroup.transversales => 'transversales',
};

/// Escapa comillas simples para SQL. Los nombres oficiales no las traen, pero
/// dejarlo sin escapar es una inyección esperando a que alguien agregue una.
String _esc(String s) => s.replaceAll("'", "''");
