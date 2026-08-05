import 'dart:convert';

import 'package:enam_app/features/duelo/domain/duelo_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Que Dart lea exactamente lo que manda Go.
///
/// # Por qué este fichero es el más importante del port
///
/// Porque el duelo tiene **dos** clientes leyendo el mismo JSON, y si se
/// entienden distinto el fallo aparece en producción y solo en uno de los dos
/// — que es la peor forma de encontrarlo. Aquí no se prueba lógica: se prueba
/// que los nombres, los tipos y los valores nulos son los que el servidor
/// promete en `internal/duelos/mensajes.go`.
///
/// Los JSON de abajo están copiados de ese contrato, no inventados. Si el
/// backend cambia un nombre, este fichero se pone rojo antes de que nadie
/// abra la app.
void main() {
  group('la ficha del duelo', () {
    test('lee lo que devuelve POST /duels/random', () {
      final duelo = DueloDTO.fromJson(
        jsonDecode('''
        {
          "id": "duelo-abc123",
          "estado": "esperando",
          "origen": "aleatorio",
          "contraBot": false,
          "completo": false,
          "totalPreguntas": 10,
          "esTuyo": true,
          "expiraEn": "2026-08-05T03:10:00Z",
          "faltanParaBotSegundos": 30
        }
        ''') as Map<String, dynamic>,
      );

      expect(duelo.id, 'duelo-abc123');
      expect(duelo.estado, EstadoDuelo.esperando);
      expect(duelo.origen, OrigenDuelo.aleatorio);
      expect(duelo.esTuyo, isTrue);
      expect(duelo.codigo, isNull, reason: 'los aleatorios no llevan PIN');
      expect(duelo.faltanParaBotSegundos, 30);
    });

    test('`en_curso` llega en snake_case y no revienta', () {
      // El servidor manda `en_curso`; Dart lo llama `enCurso`. Es el desliz más
      // fácil de todo el port y no daría error de compilación: solo un estado
      // que nunca coincide, y una pantalla que se queda en la sala de espera
      // mientras la partida ya empezó.
      final duelo = DueloDTO.fromJson({
        'id': 'd',
        'estado': 'en_curso',
        'origen': 'enlace',
      });

      expect(duelo.estado, EstadoDuelo.enCurso);
      expect(duelo.estado.terminal, isFalse);
    });

    test('un estado que este cliente no conoce no tira la app', () {
      // Una app publicada no se actualiza sola. Si el servidor añade un estado,
      // lo peor que puede pasar es que la pantalla no sepa pintarlo — no que
      // la app se caiga al abrir el duelo.
      final duelo = DueloDTO.fromJson({
        'id': 'd',
        'estado': 'algo_nuevo',
        'origen': 'otra_cosa',
      });

      expect(duelo.estado, EstadoDuelo.desconocido);
      expect(duelo.origen, OrigenDuelo.desconocido);
    });
  });

  group('el pase diario (RF-65)', () {
    test('activo y disponible son campos distintos, y hacen falta los dos', () {
      // «No puedes jugar» significa dos cosas y la pantalla dice cosas
      // distintas: apagado no enseña nada, gastado enseña «vuelve mañana».
      final gastado = PaseDeDuelo.fromJson({
        'activo': true,
        'disponible': false,
        'restantes': 0,
      });
      final apagado = PaseDeDuelo.fromJson({
        'activo': false,
        'disponible': false,
        'restantes': 0,
      });

      expect(gastado.activo, isTrue);
      expect(gastado.disponible, isFalse);
      expect(apagado.activo, isFalse);
    });

    test('una respuesta sin los campos no rompe: se toma como apagado', () {
      // La dirección segura. Si algo va mal leyendo, lo que NO puede pasar es
      // que se le ofrezca un duelo gratis a quien no le toca.
      final pase = PaseDeDuelo.fromJson(const {});
      expect(pase.activo, isFalse);
      expect(pase.disponible, isFalse);
    });
  });

  group('los mensajes del socket', () {
    test('el marcador del rival llega en nulo durante la partida', () {
      // ES la regla que mantiene la tensión: sabes que va más rápido, no que
      // va ganando. Un cero significaría «va fallando todo», así que tiene que
      // distinguirse de «todavía no te lo digo».
      final msg = MensajeDeDuelo.fromJson(
        jsonDecode('''
        {
          "tipo": "emparejado",
          "duelo": {
            "id": "duelo-1",
            "estado": "en_curso",
            "totalPreguntas": 10,
            "tu": {"nombre":"Ana","esBot":false,"respondidas":3,
                   "aciertos":2,"conectado":true,
                   "resultados":["acierto","acierto","fallo"]},
            "rival": {"nombre":"Luis","esBot":false,"respondidas":4,
                      "aciertos":null,"conectado":true,"resultados":[]},
            "botBloqueado": false
          }
        }
        ''') as Map<String, dynamic>,
      );

      expect(msg.tipo, TipoMensajeDuelo.emparejado);
      expect(msg.duelo!.tu.aciertos, 2);
      expect(msg.duelo!.rival.aciertos, isNull);
      expect(msg.duelo!.rival.respondidas, 4);
    });

    test('los resultados por pregunta se traducen uno a uno', () {
      final lado = LadoDuelo.fromJson(const {
        'nombre': 'Ana',
        'resultados': ['acierto', 'fallo', 'en_blanco', ''],
      });

      expect(lado.resultados, [
        ResultadoPorPregunta.acierto,
        ResultadoPorPregunta.fallo,
        // No responder NO es fallar: se distingue también en la fila de
        // puntos, no solo en la revisión.
        ResultadoPorPregunta.enBlanco,
        ResultadoPorPregunta.sinContestar,
      ]);
    });

    test('`botBloqueado` llega y se conserva (RF-65)', () {
      final msg = MensajeDeDuelo.fromJson(const {
        'tipo': 'sin_rival',
        'duelo': {
          'id': 'd',
          'estado': 'esperando',
          'tu': {'nombre': 'Ana'},
          'rival': {'nombre': ''},
          'botBloqueado': true,
        },
        'espera': {'esperandoSegundos': 30, 'faltanSegundos': 0},
      });

      expect(msg.duelo!.botBloqueado, isTrue);
      expect(msg.espera!.esperandoSegundos, 30);
    });

    test('el final trae la revisión con los tres estados', () {
      final msg = MensajeDeDuelo.fromJson(
        jsonDecode('''
        {
          "tipo": "terminado",
          "final": {
            "desenlace": "ganaste",
            "tusAciertos": 7, "rivalAciertos": 4,
            "tuNota": 14.0, "rivalNota": 8.0,
            "tuTiempoTotalMs": 42000, "rivalTiempoTotalMs": 51000,
            "porAbandono": false, "porTiempo": false,
            "conPaseGratis": false,
            "revision": [
              {"orden":1,"enunciado":"¿La conducta?",
               "opciones":[{"id":"a","texto":"A","esCorrecta":true}],
               "explicacion":"Porque sí.","tuOpcionId":"a","acertaste":true,
               "rivalOpcionId":null,"rivalAcerto":false,
               "tuEstado":"acierto","rivalEstado":"en_blanco"}
            ]
          }
        }
        ''') as Map<String, dynamic>,
      );

      final f = msg.final$!;
      expect(f.desenlace, Desenlace.ganaste);
      expect(f.tuNota, 14.0);
      expect(f.revision.single.tuEstado, EstadoDeRespuesta.acierto);
      // La que nadie llegó a ver: en blanco, no fallo.
      expect(f.revision.single.rivalEstado, EstadoDeRespuesta.enBlanco);
    });

    test('con el pase diario la revisión llega vacía y se dice por qué', () {
      // El servidor NO manda la revisión a quien jugó gratis, y manda
      // `conPaseGratis` explícito para que la pantalla no tenga que deducirlo
      // de que la lista venga vacía.
      final msg = MensajeDeDuelo.fromJson(const {
        'tipo': 'terminado',
        'final': {
          'desenlace': 'perdiste',
          'conPaseGratis': true,
          'revision': <dynamic>[],
        },
      });

      expect(msg.final$!.conPaseGratis, isTrue);
      expect(msg.final$!.revision, isEmpty);
    });

    test('un tipo desconocido se reconoce como tal', () {
      final msg = MensajeDeDuelo.fromJson(const {'tipo': 'algo_del_futuro'});
      expect(msg.tipo, TipoMensajeDuelo.desconocido);
    });
  });

  group('lo que manda el cliente', () {
    test('son dos verbos y solo dos', () {
      // Cada verbo que se le da al cliente es una regla que el servidor tiene
      // que defender. Un «pasa a la siguiente» permitiría hacer trampa con
      // solo mandar el mensaje antes de tiempo.
      expect(const Responder(orden: 3, opcionId: 'b').toJson(), {
        'tipo': 'responder',
        'orden': 3,
        'opcionId': 'b',
      });

      // `null` es «se acabó el tiempo y no marqué nada», y viaja igual: el
      // servidor tiene que poder distinguirlo de no haber mandado nada.
      expect(const Responder(orden: 4, opcionId: null).toJson(), {
        'tipo': 'responder',
        'orden': 4,
        'opcionId': null,
      });

      expect(const Abandonar().toJson(), {'tipo': 'abandonar'});
    });
  });
}
