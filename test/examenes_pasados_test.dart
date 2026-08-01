import 'package:enam_app/core/config/api_endpoints.dart';
import 'package:enam_app/features/session/domain/session_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Los exámenes pasados, contra el contrato REAL.
///
/// Esta pantalla se construyó contra un contrato imaginado y no coincidía en
/// nada con el que existe:
///
///  - Pedía `GET /exams`; el servidor expone `/past-exams`. Contra producción
///    era un 404, o sea la pantalla vacía siempre.
///  - Modelaba `fecha` como `DateTime`; el servidor manda `anio`, un entero,
///    porque no guarda el día. Llegaba nulo y la lista salía sin agrupar.
///  - Modelaba `etiqueta`; el servidor manda `convocatoria`, y **vacía** en vez
///    de nula cuando ese año hubo una sola.
///  - Modelaba `resuelto` como booleano; el servidor manda `intentos`, un
///    contador, porque un examen pasado se rinde las veces que uno quiera: es
///    material de estudio, no una competición.
///  - No modelaba `duracionMinutos`.
///
/// Nada de eso fallaba de forma ruidosa: `fromJson` ignora las claves que no
/// conoce y rellena las que faltan con su valor por defecto, así que la lista
/// se pintaba entera, en blanco y sin que nada avisara.
void main() {
  /// La respuesta literal de `GET /past-exams`, copiada del servidor.
  const respuestaDelServidor = {
    'id': 'pasado-01be237f55f96e21c8c3cf9e992b236d',
    'nombre': 'ENAM 2023-I',
    'anio': 2023,
    'convocatoria': 'I',
    'duracionMinutos': 180,
    'totalPreguntas': 180,
    'intentos': 0,
    'mejorNota': null,
  };

  test('la ruta es la del servidor, no la inventada', () {
    expect(ApiEndpoints.pastExams, '/past-exams');
    expect(ApiEndpoints.startPastExam('abc'), '/past-exams/abc/start');
  });

  test('se leen todos los campos que manda el servidor', () {
    final examen = PastExam.fromJson(respuestaDelServidor);

    expect(examen.id, 'pasado-01be237f55f96e21c8c3cf9e992b236d');
    expect(examen.nombre, 'ENAM 2023-I');
    expect(examen.anio, 2023);
    expect(examen.convocatoria, 'I');
    expect(examen.duracionMinutos, 180);
    expect(examen.totalPreguntas, 180);
    expect(examen.intentos, 0);
    expect(examen.mejorNota, isNull);
  });

  test('sin intentos no está resuelto; con uno, sí', () {
    final sinRendir = PastExam.fromJson(respuestaDelServidor);
    expect(sinRendir.resuelto, isFalse);

    final rendido = PastExam.fromJson({
      ...respuestaDelServidor,
      'intentos': 3,
      'mejorNota': 14.5,
    });
    expect(rendido.resuelto, isTrue);
    expect(rendido.intentos, 3);
    expect(rendido.mejorNota, 14.5);
  });

  test('la convocatoria vacía no se pinta como distintivo', () {
    // Un año con una sola convocatoria manda la cadena vacía, no null. Tratarlo
    // como nulo dejaría un distintivo en blanco colgando del nombre.
    final unica = PastExam.fromJson({...respuestaDelServidor, 'convocatoria': ''});

    expect(unica.convocatoria, isEmpty);
    expect(unica.nombreCompleto, 'ENAM 2023-I');
  });

  test('con convocatoria, el nombre completo la lleva', () {
    final examen = PastExam.fromJson(respuestaDelServidor);
    expect(examen.nombreCompleto, 'ENAM 2023-I · I');
  });

  test('la duración llega en minutos y se usa como Duration', () {
    final examen = PastExam.fromJson(respuestaDelServidor);
    expect(examen.duracion, const Duration(hours: 3));
  });

  test('una respuesta incompleta no revienta, pero tampoco miente', () {
    // Si el servidor recortara campos, los valores por defecto tienen que ser
    // los honestos: cero intentos y sin nota, no «resuelto».
    final minimo = PastExam.fromJson({'id': 'x', 'nombre': 'ENAM'});

    expect(minimo.anio, 0);
    expect(minimo.convocatoria, isEmpty);
    expect(minimo.intentos, 0);
    expect(minimo.resuelto, isFalse);
    expect(minimo.mejorNota, isNull);
  });
}
