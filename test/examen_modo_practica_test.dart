import 'package:enam_app/features/session/data/session_repository.dart';
import 'package:enam_app/features/session/domain/session_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Estudiar un examen pasado es una PRÁCTICA sobre sus preguntas.
///
/// Los tres rasgos que lo definen, y que se pierden en cuanto la sesión se crea
/// como examen: retroalimentación al responder, sin reloj, y tantas preguntas
/// como el estudiante pidió.
void main() {
  late MockSessionRepository repo;
  late PastExam examen;

  setUp(() async {
    repo = MockSessionRepository();
    examen = (await repo.pastExams()).first;
  });

  test('respeta la cantidad pedida', () async {
    final sesion = await repo.startPastExam(
      examen.id,
      modo: PastExamMode.practica,
      cantidad: 20,
    );

    expect(sesion.preguntas, hasLength(20));
  });

  test('sin cantidad, el examen entero', () async {
    final sesion = await repo.startPastExam(
      examen.id,
      modo: PastExamMode.practica,
    );

    expect(sesion.preguntas, hasLength(examen.totalPreguntas));
  });

  test('da retroalimentación y no lleva reloj', () async {
    final sesion = await repo.startPastExam(
      examen.id,
      modo: PastExamMode.practica,
      cantidad: 15,
    );

    expect(
      sesion.muestraFeedbackInmediato,
      isTrue,
      reason: 'estudiar sin ver la explicación no enseña nada',
    );
    expect(sesion.expiraEn, isNull, reason: 'estudiando no hay reloj');
    expect(sesion.tipo, SessionType.practica);
  });

  test('los modos de examen ignoran la cantidad y llevan reloj', () async {
    final completo = await repo.startPastExam(
      examen.id,
      modo: PastExamMode.completo,
      cantidad: 20,
    );
    expect(completo.preguntas, hasLength(examen.totalPreguntas));
    expect(completo.expiraEn, isNotNull);
    expect(completo.muestraFeedbackInmediato, isFalse);

    final corto = await repo.startPastExam(
      examen.id,
      modo: PastExamMode.corto,
      cantidad: 180,
    );
    expect(corto.preguntas, hasLength(40));
    expect(corto.expiraEn, isNotNull);
  });

  test('la cantidad se acota al examen y al mínimo de una práctica', () async {
    final pocas = await repo.startPastExam(
      examen.id,
      modo: PastExamMode.practica,
      cantidad: 3,
    );
    expect(pocas.preguntas, hasLength(10));

    final muchas = await repo.startPastExam(
      examen.id,
      modo: PastExamMode.practica,
      cantidad: 500,
    );
    expect(muchas.preguntas, hasLength(examen.totalPreguntas));
  });
}
