import 'package:enam_app/core/domain/blueprint.dart';
import 'package:enam_app/core/domain/taxonomy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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

  group('Densidad de estudio', () {
    test('Ciencias Básicas rinde más por tema que Medicina', () {
      // El dato clave del temario: 7 temas producen 10 preguntas en Ciencias
      // Básicas, mientras que en Medicina hacen falta 123 para 40.
      final medicina = Taxonomy.byId('medicina')!;
      final basicas = Taxonomy.byId('ciencias-basicas')!;

      final densidadMedicina = Blueprint.topicsPerQuestion(medicina, temas: 123)!;
      final densidadBasicas = Blueprint.topicsPerQuestion(basicas, temas: 7)!;

      expect(densidadMedicina, closeTo(3.075, 0.01));
      expect(densidadBasicas, closeTo(0.7, 0.01));
      expect(densidadBasicas, lessThan(densidadMedicina));
    });

    test('devuelve null si el área no tiene temas contabilizados', () {
      // Cuatro áreas no desarrollan el tercer nivel en el documento oficial.
      final etica = Taxonomy.byId('etica')!;
      expect(Blueprint.topicsPerQuestion(etica, temas: 0), isNull);
    });
  });
}
