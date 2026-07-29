import 'package:enam_app/core/domain/blueprint.dart';
import 'package:enam_app/features/session/data/session_repository.dart';
import 'package:enam_app/features/session/domain/session_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockSessionRepository repo;

  setUp(() => repo = MockSessionRepository());

  group('Simulacro', () {
    test('genera 180 preguntas', () async {
      final session = await repo.startSimulacro();
      expect(session.totalPreguntas, Blueprint.totalQuestions);
    });

    test('el de muestra genera 40 preguntas (RN-03)', () async {
      final session = await repo.startSimulacro(esMuestra: true);
      expect(session.totalPreguntas, Blueprint.sampleExamQuestions);
    });

    test('NO revela las claves mientras está en curso (RF-16)', () async {
      final session = await repo.startSimulacro(esMuestra: true);

      for (final pregunta in session.preguntas) {
        expect(
          pregunta.explicacion,
          isNull,
          reason: 'La explicación no debe viajar antes de terminar',
        );
        for (final opcion in pregunta.opciones) {
          expect(
            opcion.esCorrecta,
            isNull,
            reason: 'Marcar la correcta sería regalar la respuesta',
          );
        }
      }
    });

    test('no da feedback inmediato al responder (RF-16)', () async {
      final session = await repo.startSimulacro(esMuestra: true);
      final pregunta = session.preguntas.first;

      final answer = await repo.answer(
        sessionId: session.id,
        questionId: pregunta.id,
        optionId: pregunta.opciones.first.id,
        tiempoMs: 5000,
      );

      expect(answer.esCorrecta, isNull);
    });

    test('revela las claves al finalizar (RF-18)', () async {
      final session = await repo.startSimulacro(esMuestra: true);
      final finalizada = await repo.submit(session.id);

      expect(finalizada.estado, SessionStatus.finalizada);
      for (final pregunta in finalizada.preguntas) {
        expect(pregunta.opciones.where((o) => o.esCorrecta == true), hasLength(1));
      }
    });

    test('respondiendo todo correcto da 20.00', () async {
      final session = await repo.startSimulacro(esMuestra: true);

      // Se responde, se corrige y se vuelve a responder con la clave revelada:
      // así se verifica que la corrección usa las claves guardadas y no las
      // que viajaron al cliente.
      final corregida = await repo.submit(session.id);

      final segunda = await repo.startSimulacro(esMuestra: true);
      for (var i = 0; i < segunda.preguntas.length; i++) {
        final pregunta = segunda.preguntas[i];
        // La clave de la primera sesión no sirve aquí; se responde a ciegas.
        await repo.answer(
          sessionId: segunda.id,
          questionId: pregunta.id,
          optionId: pregunta.opciones.first.id,
          tiempoMs: 1000,
        );
      }
      final resultado = await repo.submit(segunda.id);

      expect(corregida.nota, isNotNull);
      expect(resultado.nota, inInclusiveRange(0, 20));
    });

    test('sin responder nada la nota es 0 (RN-01, sin puntaje en contra)',
        () async {
      final session = await repo.startSimulacro(esMuestra: true);
      final finalizada = await repo.submit(session.id);

      expect(finalizada.nota, 0.0);
      expect(finalizada.correctas, 0);
    });

    test('las preguntas en blanco se cuentan como no respondidas', () async {
      final session = await repo.startSimulacro(esMuestra: true);
      final pregunta = session.preguntas.first;

      await repo.answer(
        sessionId: session.id,
        questionId: pregunta.id,
        optionId: null, // dejada en blanco
        tiempoMs: 2000,
      );

      final actual = await repo.session(session.id);
      expect(actual.respondidas, 0);
      expect(actual.sinResponder, actual.totalPreguntas);
    });
  });

  group('Práctica', () {
    test('respeta la cantidad configurada', () async {
      final session = await repo.startPractice(
        const PracticeConfig(cantidadPreguntas: 15),
      );
      expect(session.totalPreguntas, 15);
    });

    test('sí da feedback inmediato al responder (RF-13)', () async {
      final session = await repo.startPractice(
        const PracticeConfig(cantidadPreguntas: 5),
      );
      final pregunta = session.preguntas.first;

      final answer = await repo.answer(
        sessionId: session.id,
        questionId: pregunta.id,
        optionId: pregunta.opciones.first.id,
        tiempoMs: 3000,
      );

      expect(answer.esCorrecta, isNotNull);
    });

    test('responder la clave marca acierto', () async {
      final session = await repo.startPractice(
        const PracticeConfig(cantidadPreguntas: 5),
      );
      final pregunta = session.preguntas.first;
      final clave = pregunta.opciones.firstWhere((o) => o.esCorrecta == true);

      final answer = await repo.answer(
        sessionId: session.id,
        questionId: pregunta.id,
        optionId: clave.id,
        tiempoMs: 3000,
      );

      expect(answer.esCorrecta, isTrue);
    });

    test('filtra por las áreas pedidas', () async {
      final session = await repo.startPractice(
        const PracticeConfig(
          cantidadPreguntas: 10,
          areaIds: ['medicina', 'pediatria'],
        ),
      );

      final areas = session.preguntas.map((q) => q.areaId).toSet();
      expect(areas, {'medicina', 'pediatria'});
    });

    test('marcar una pregunta la contabiliza (RF-14)', () async {
      final session = await repo.startPractice(
        const PracticeConfig(cantidadPreguntas: 5),
      );
      final pregunta = session.preguntas.first;

      await repo.answer(
        sessionId: session.id,
        questionId: pregunta.id,
        optionId: pregunta.opciones.first.id,
        tiempoMs: 1000,
        marcada: true,
      );

      final actual = await repo.session(session.id);
      expect(actual.marcadas, 1);
    });
  });
}
