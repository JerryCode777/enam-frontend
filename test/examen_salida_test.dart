import 'package:enam_app/features/session/data/session_repository.dart';
import 'package:enam_app/features/session/domain/session_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Un examen pasado se entra desde el inicio, así que al salir se vuelve ahí.
///
/// Devolver a la pestaña de simulacros dejaba al estudiante en un sitio por el
/// que no pasó: entró por «Exámenes pasados» desde el inicio y salió a otra
/// pantalla, sin forma evidente de volver a la lista de exámenes.
///
/// La pantalla del examen distingue una cosa de la otra por el tipo de sesión,
/// y de ahí que esta prueba viva en el tipo: si el repositorio vuelve a crear
/// la sesión como `simulacro`, la salida se rompe sin que nada más se queje.
void main() {
  late MockSessionRepository repo;
  late PastExam examen;

  setUp(() async {
    repo = MockSessionRepository();
    examen = (await repo.pastExams()).first;
  });

  test('rendir un examen pasado crea una sesión de examen pasado', () async {
    for (final modo in [PastExamMode.completo, PastExamMode.corto]) {
      final sesion = await repo.startPastExam(examen.id, modo: modo);

      expect(
        sesion.tipo,
        SessionType.examenPasado,
        reason: 'es lo que manda el servidor, y de ahí sale la ruta de salida',
      );
      expect(
        sesion.esSimulacro,
        isTrue,
        reason: 'sigue rindiéndose como examen: con reloj y sin ver las claves',
      );
    }
  });

  test('estudiarlo no lo es: es una práctica y se sale como práctica', () async {
    final sesion = await repo.startPastExam(
      examen.id,
      modo: PastExamMode.practica,
    );

    expect(sesion.tipo, SessionType.practica);
  });
}
