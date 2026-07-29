import 'package:enam_app/core/domain/blueprint.dart';
import 'package:enam_app/core/theme/area_colors.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Blueprint oficial', () {
    test('las áreas suman exactamente 180 preguntas', () {
      final total = Blueprint.areas.fold(0, (sum, a) => sum + a.questionCount);
      expect(total, Blueprint.totalQuestions);
    });

    test('los grupos suman según la tabla de ASPEFAM', () {
      // SSD §1.3: Clínico Médicas 90, Quirúrgicas 60, Transversales 30.
      expect(Blueprint.questionsInGroup(AreaGroup.clinicoMedicas), 90);
      expect(Blueprint.questionsInGroup(AreaGroup.clinicoQuirurgicas), 60);
      expect(Blueprint.questionsInGroup(AreaGroup.transversales), 30);
    });

    test('no hay ids de área duplicados', () {
      final ids = Blueprint.areas.map((a) => a.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('cada área tiene un color asignado', () {
      // Si alguien agrega un área al blueprint y olvida el color, la UI la
      // pintaría gris sin avisar. Esto lo detecta.
      for (final area in Blueprint.areas) {
        expect(
          AreaColors.knownAreaIds,
          contains(area.id),
          reason: 'Falta color para "${area.id}"',
        );
      }
    });

    test('los pesos suman 1.0', () {
      final suma = Blueprint.areas.fold(0.0, (sum, a) => sum + a.weight);
      expect(suma, closeTo(1.0, 0.0001));
    });
  });

  group('Calificación vigesimal (RN-01)', () {
    test('todas correctas es 20.00', () {
      expect(Blueprint.toVigesimal(180), 20.0);
    });

    test('ninguna correcta es 0.00', () {
      expect(Blueprint.toVigesimal(0), 0.0);
    });

    test('99 de 180 da 11.00, justo el mínimo aprobatorio', () {
      expect(Blueprint.toVigesimal(99), 11.0);
      expect(Blueprint.isPassing(11.0), isTrue);
    });

    test('98 de 180 desaprueba', () {
      final nota = Blueprint.toVigesimal(98);
      expect(nota, lessThan(Blueprint.passingGrade));
      expect(Blueprint.isPassing(nota), isFalse);
    });

    test('redondea a 2 decimales', () {
      // 100/180*20 = 11.111... → 11.11
      expect(Blueprint.toVigesimal(100), 11.11);
    });

    test('funciona con el simulacro de muestra de 40 preguntas', () {
      expect(Blueprint.toVigesimal(20, total: 40), 10.0);
      expect(Blueprint.toVigesimal(40, total: 40), 20.0);
    });

    test('no revienta si el total es cero', () {
      expect(Blueprint.toVigesimal(0, total: 0), 0.0);
    });
  });

  group('Búsqueda de áreas', () {
    test('encuentra un área conocida', () {
      expect(Blueprint.byId('medicina')?.questionCount, 40);
    });

    test('devuelve null para un área desconocida en vez de reventar', () {
      expect(Blueprint.byId('area-que-no-existe'), isNull);
    });
  });
}
