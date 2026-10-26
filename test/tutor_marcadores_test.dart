import 'dart:convert';

import 'package:enam_app/features/tutor/data/tutor_repository.dart';
import 'package:enam_app/features/tutor/domain/marcadores.dart';
import 'package:enam_app/features/tutor/domain/tutor_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lo que el tutor escribe y cómo lo entiende la app (TUTOR-CONTRATO v3).
void main() {
  group('partirRespuesta', () {
    test('separa la tarjeta de práctica y las opciones del texto', () {
      const texto =
          'Tu área más floja es **GO**.\n\n'
          '[comp:practica:{"area":"gineco-obstetricia","tema":null,"n":10}]\n\n'
          '¿Empezamos?\n'
          '[opciones:["Sí","Ahora no"]]';

      final partes = partirRespuesta(texto);

      expect(partes, hasLength(4));
      expect((partes[0] as TextoDeRespuesta).markdown, contains('**GO**'));
      expect(
        partes[1],
        const PracticaPropuesta(areaId: 'gineco-obstetricia', cantidad: 10),
      );
      expect((partes[2] as TextoDeRespuesta).markdown, '¿Empezamos?');
      expect((partes[3] as OpcionesRapidas).opciones, ['Sí', 'Ahora no']);
    });

    test('las citas en línea se quedan dentro del párrafo', () {
      final partes = partirRespuesta(
        'Mira [pregunta:q-2] y la clase [clase:pediatria/pediatria.01-02].',
      );
      expect(partes, hasLength(1));
      expect(
        (partes.single as TextoDeRespuesta).markdown,
        contains('[pregunta:q-2]'),
      );
    });

    test('mientras llega, no enseña un marcador a medias', () {
      // Ni el de bloque, que lleva JSON con corchetes dentro…
      expect(
        _textoDe(
          partirRespuesta(
            'Te armé esto: [comp:practica:{"area":"pedia',
            completo: false,
          ),
        ),
        'Te armé esto:',
      );
      expect(
        _textoDe(partirRespuesta('Elige: [opciones:["Sí","N', completo: false)),
        'Elige:',
      );
      // …ni el de una cita que todavía no se cierra…
      expect(_textoDe(partirRespuesta('Mira [preg', completo: false)), 'Mira');
      // …pero un corchete cualquiera sí se ve.
      expect(
        _textoDe(partirRespuesta('Ver [tabla 1', completo: false)),
        'Ver [tabla 1',
      );
    });

    test('un marcador mal formado se queda como texto al terminar', () {
      final partes = partirRespuesta('Hola [comp:practica:{no es json}] chau');
      expect(_textoDe(partes), 'Hola [comp:practica:{no es json}] chau');
    });

    test('la práctica pide entre 10 y 20 preguntas', () {
      PracticaPropuesta practica(int n) =>
          partirRespuesta('[comp:practica:{"area":"pediatria","n":$n}]').single
              as PracticaPropuesta;

      expect(practica(5).cantidad, 10);
      expect(practica(15).cantidad, 15);
      expect(practica(40).cantidad, 20);
    });

    test('como mucho cuatro respuestas rápidas', () {
      final partes = partirRespuesta('[opciones:["a","b","c","d","e"]]');
      expect((partes.single as OpcionesRapidas).opciones, hasLength(4));
    });
  });

  test('copiar quita los marcadores', () {
    expect(
      textoParaCopiar(
        'La **clave** es esta [pregunta:q-1].\n'
        '[opciones:["Sí","No"]]',
      ),
      'La **clave** es esta.',
    );
  });

  group('el stream del servidor', () {
    test('lee inicio, estado, trozos y fin, e ignora el ping', () async {
      const sse =
          'event: inicio\n'
          'data: {"sesionId":"tses-1","mensajeId":"tmsg-1","mensajeUsuarioId":"tmsg-0"}\n'
          '\n'
          ': ping\n'
          '\n'
          'event: estado\n'
          'data: {"fase":"buscando_preguntas"}\n'
          '\n'
          'event: delta\n'
          'data: {"texto":"Hola "}\n'
          '\n'
          'event: delta\n'
          'data: {"texto":"Jerry"}\n'
          '\n'
          'event: algo_nuevo\n'
          'data: {"x":1}\n'
          '\n'
          'event: fin\n'
          'data: {"mensajeId":"tmsg-1","cupo":{"tipo":"prueba","total":15,"usados":11,"restantes":4,"renuevaEn":null}}\n'
          '\n';

      // En trozos que cortan líneas por la mitad, como llega por la red.
      final bytes = utf8.encode(sse);
      final eventos = await leerEventosDelTutor(
        Stream.fromIterable([
          for (var i = 0; i < bytes.length; i += 17)
            bytes.sublist(i, i + 17 > bytes.length ? bytes.length : i + 17),
        ]),
      ).toList();

      expect(eventos, hasLength(5));
      expect(
        eventos[0],
        isA<InicioDeRespuesta>()
            .having((e) => e.sesionId, 'sesionId', 'tses-1')
            .having((e) => e.mensajeId, 'mensajeId', 'tmsg-1'),
      );
      expect((eventos[1] as FaseDeRespuesta).texto, 'Buscando en el banco…');
      expect(
        [for (final e in eventos.whereType<TrozoDeRespuesta>()) e.texto],
        ['Hola ', 'Jerry'],
      );
      expect(
        eventos[4],
        isA<FinDeRespuesta>()
            .having((e) => e.restantesPrueba, 'restantesPrueba', 4)
            .having((e) => e.restantesHoy, 'restantesHoy', isNull),
      );
    });

    test('un error a mitad trae un mensaje mostrable', () async {
      final eventos = await leerEventosDelTutor(
        Stream.value(
          utf8.encode(
            'event: error\n'
            'data: {"codigo":"PROVEEDOR_CAIDO","mensaje":"El tutor no respondió."}\n\n',
          ),
        ),
      ).toList();
      expect(
        (eventos.single as FalloDeRespuesta).mensaje,
        'El tutor no respondió.',
      );
    });
  });

  group('GET /tutor/estado', () {
    test('gratis: prueba con lo que queda y las sugerencias', () {
      final e = estadoDesdeJson({
        'disponible': true,
        'nombre': 'Tu tutor ENAM',
        'plan': 'gratis',
        'cupo': {'tipo': 'prueba', 'total': 15, 'usados': 3, 'restantes': 12},
        'sugerencias': {
          'entender': ['¿Por qué la metformina?'],
          'practicar': [],
          'plan': ['¿Qué repaso?'],
        },
      });
      expect(e.disponible, isTrue);
      expect(e.premium, isFalse);
      expect(e.restantesPrueba, 12);
      expect(e.sugerencias[CategoriaDeSugerencia.entender], [
        '¿Por qué la metformina?',
      ]);
    });

    test('premium: cupo del día y sin prueba', () {
      final e = estadoDesdeJson({
        'disponible': true,
        'plan': 'premium',
        'cupo': {'tipo': 'dia', 'total': 50, 'usados': 1, 'restantes': 49},
      });
      expect(e.premium, isTrue);
      expect(e.restantesHoy, 49);
      expect(e.restantesPrueba, isNull);
    });

    test('sin nombre, el de siempre; sin disponible, no hay tutor', () {
      final e = estadoDesdeJson({'disponible': false});
      expect(e.disponible, isFalse);
      expect(e.nombreVisible, 'Tu tutor ENAM');
    });
  });
}

String _textoDe(List<ParteDeRespuesta> partes) =>
    partes.whereType<TextoDeRespuesta>().map((p) => p.markdown).join('\n');
