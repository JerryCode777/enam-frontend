import 'package:enam_app/core/error/failure.dart';
import 'package:enam_app/core/network/conectividad.dart';
import 'package:enam_app/core/storage/base_local.dart';
import 'package:enam_app/features/offline/data/almacen_offline.dart';
import 'package:enam_app/features/offline/data/servicio_offline.dart';
import 'package:enam_app/features/offline/domain/offline_models.dart';
import 'package:enam_app/features/session/data/session_repository_offline.dart';
import 'package:enam_app/features/session/domain/session_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayuda/dobles_offline.dart';
import 'ayuda/offline.dart';

/// Practicar sin señal con lo que uno descargó, sin tope (RF-31).
///
/// Es el arreglo de un absurdo: se descargaban las 480 preguntas de un área y
/// la app dejaba hacer **una** práctica de 20, porque cada práctica necesitaba
/// una sesión creada por el servidor de antemano. Al gastarla decía «no tienes
/// prácticas listas» con el banco entero guardado en el teléfono.
///
/// Y le pasaba a todo el mundo el primer día: la prueba de 24 h arranca en la
/// primera práctica (D-02), así que descargar un área **no** crea ninguna
/// sesión —sería regalarle el día a quien solo prepara el viaje— y el
/// estudiante nuevo se quedaba con cero.
void main() {
  late ServidorFalso servidor;
  late ConectividadFalsa red;
  late AlmacenOffline almacen;
  late BaseLocal base;
  late ServicioOffline servicio;
  late SessionRepositoryConRespaldo repo;

  const yo = 'usuario-1';
  const veinte = PracticeConfig(
    areaIds: ['medicina'],
    cantidadPreguntas: 20,
  );

  setUp(() {
    servidor = ServidorFalso();
    red = ConectividadFalsa();

    final piezas = almacenEnMemoria();
    almacen = piezas.almacen;
    base = piezas.base;

    servicio = ServicioOffline(
      almacen: almacen,
      remoto: servidor,
      sesiones: servidor,
      usuarioId: yo,
    );

    repo = SessionRepositoryConRespaldo(
      remoto: servidor,
      offline: servicio,
      red: red,
    );
  });

  tearDown(() async {
    await red.cerrar();
    await base.cerrar();
  });

  void cortarLaSenal() {
    servidor.hayRed = false;
    red.cambiar(conectado: false);
  }

  void volverLaSenal() {
    servidor.hayRed = true;
    red.cambiar(conectado: true);
  }

  group('preparar el viaje', () {
    test('descargar no le arranca las 24 h a nadie', () async {
      await servicio.descargar('medicina', reservar: false);

      expect(await servicio.resumenes(), hasLength(1));
      expect(
        servidor.practicasCreadas,
        0,
        reason: 'crear una sesión arrancaría la prueba de quien solo prepara',
      );
    });
  });

  group('sin señal', () {
    test('se puede practicar con lo descargado', () async {
      await servicio.descargar('medicina', reservar: false);
      cortarLaSenal();

      final sesion = await repo.startPractice(veinte);

      expect(sesion.preguntas, hasLength(20));
      expect(sesion.tipo, SessionType.practica);
      expect(sesion.estado, SessionStatus.enCurso);
    });

    // Lo que antes era imposible pasada la primera.
    test('y otra, y otra, sin tope', () async {
      await servicio.descargar('medicina', reservar: false);
      cortarLaSenal();

      for (var i = 1; i <= 5; i++) {
        final sesion = await repo.startPractice(veinte);
        expect(sesion.preguntas, hasLength(20), reason: 'práctica $i');
      }
    });

    test('las preguntas no se repiten mientras queden sin ver', () async {
      // 40 preguntas descargadas dan para dos prácticas de 20 sin repetir.
      await servicio.descargar('medicina', reservar: false);
      cortarLaSenal();

      final primera = await repo.startPractice(veinte);
      final segunda = await repo.startPractice(veinte);

      final ids = {for (final p in primera.preguntas) p.id};
      final otras = {for (final p in segunda.preguntas) p.id};

      expect(ids.intersection(otras), isEmpty);
    });

    // Agotado el banco se repite antes que dejar al estudiante sin practicar.
    test('cuando ya se vio todo, se repasa en vez de fallar', () async {
      await servicio.descargar('medicina', reservar: false);
      cortarLaSenal();

      for (var i = 0; i < 3; i++) {
        expect((await repo.startPractice(veinte)).preguntas, hasLength(20));
      }
    });

    test('la clave no viaja en la práctica sin responder', () async {
      await servicio.descargar('medicina', reservar: false);
      cortarLaSenal();

      final sesion = await repo.startPractice(veinte);

      for (final pregunta in sesion.preguntas) {
        for (final opcion in pregunta.opciones) {
          expect(
            opcion.esCorrecta,
            isNull,
            reason: 'enseñar la clave antes de responder la regala',
          );
        }
      }
    });

    test('corrige al instante, que es para lo que se descargó', () async {
      await servicio.descargar('medicina', reservar: false);
      cortarLaSenal();

      final sesion = await repo.startPractice(veinte);
      final local = await servicio.sesionLocal(sesion.id);
      final pregunta = sesion.preguntas.first;

      final respuesta = await servicio.responderSinConexion(
        local!,
        preguntaId: pregunta.id,
        opcionId: '${pregunta.id}-b',
        tiempoMs: 4000,
      );

      expect(respuesta.esCorrecta, isNotNull);
    });

    test('sin nada descargado dice qué hay que hacer', () async {
      cortarLaSenal();

      expect(
        () => repo.startPractice(veinte),
        throwsA(isA<SinDescargasFailure>()),
      );
    });

    test('pedir un área que no se bajó lo dice claro', () async {
      await servicio.descargar('medicina', reservar: false);
      cortarLaSenal();

      await expectLater(
        () => repo.startPractice(
          const PracticeConfig(areaIds: ['cirugia'], cantidadPreguntas: 20),
        ),
        throwsA(
          isA<SinDescargasFailure>().having(
            (e) => e.message,
            'mensaje',
            contains('no está descargado'),
          ),
        ),
      );
    });
  });

  group('al volver la señal', () {
    test('la práctica del bus se da de alta en el servidor', () async {
      await servicio.descargar('medicina', reservar: false);
      cortarLaSenal();

      final sesion = await repo.startPractice(veinte);
      volverLaSenal();
      await servicio.sincronizar();

      expect(servidor.registradas.map((s) => s.id), contains(sesion.id));
      expect(servidor.sesiones, contains(sesion.id));
    });

    test('con sus preguntas, para que las respuestas encajen', () async {
      await servicio.descargar('medicina', reservar: false);
      cortarLaSenal();

      final sesion = await repo.startPractice(veinte);
      volverLaSenal();
      await servicio.sincronizar();

      final registrada = servidor.registradas.single;
      expect(
        registrada.preguntaIds,
        [for (final p in sesion.preguntas) p.id],
      );
      expect(registrada.areaIds, ['medicina']);
    });

    test('lo respondido en el bus llega y queda aplicado', () async {
      await servicio.descargar('medicina', reservar: false);
      cortarLaSenal();

      final sesion = await repo.startPractice(veinte);
      final local = await servicio.sesionLocal(sesion.id);
      for (final pregunta in sesion.preguntas.take(3)) {
        await servicio.responderSinConexion(
          local!,
          preguntaId: pregunta.id,
          opcionId: '${pregunta.id}-b',
          tiempoMs: 3000,
        );
      }

      volverLaSenal();
      final resultado = await servicio.sincronizar();

      expect(resultado?.aceptadas, 3);
      expect(servidor.sesiones[sesion.id]!.respuestas, hasLength(3));
    });

    test('sincronizar dos veces no la da de alta dos veces', () async {
      await servicio.descargar('medicina', reservar: false);
      cortarLaSenal();
      await repo.startPractice(veinte);

      volverLaSenal();
      await servicio.sincronizar();
      await servicio.sincronizar();

      expect(servidor.registradas, hasLength(1));
    });

    test('si la sincronización falla, la práctica sigue pendiente', () async {
      await servicio.descargar('medicina', reservar: false);
      cortarLaSenal();
      final sesion = await repo.startPractice(veinte);

      // La red sigue caída: el intento falla y no se puede dar por hecho.
      await expectLater(servicio.sincronizar(), throwsA(isA<NetworkFailure>()));
      expect(servidor.registradas, isEmpty);

      volverLaSenal();
      await servicio.sincronizar();

      expect(servidor.registradas.map((s) => s.id), contains(sesion.id));
    });
  });

  // La app puede llegar antes que el despliegue del servidor: una tienda tarda
  // dias en aprobar. Contra un servidor anterior, lo estudiado en el bus tiene
  // que quedarse esperando, nunca perderse.
  group('contra un servidor que aun no sabe de esto', () {
    test('no se da por entregado lo que el servidor ignoro', () async {
      await servicio.descargar('medicina', reservar: false);
      cortarLaSenal();

      final sesion = await repo.startPractice(veinte);
      final local = await servicio.sesionLocal(sesion.id);
      await servicio.responderSinConexion(
        local!,
        preguntaId: sesion.preguntas.first.id,
        opcionId: '${sesion.preguntas.first.id}-b',
        tiempoMs: 3000,
      );

      volverLaSenal();
      // Un servidor viejo no manda `sesionesCreadas` y rechaza las respuestas
      // por apuntar a una sesión que para él no existe.
      servidor.respuestaDeSync = const ResultadoDeSync(
        conflictos: [
          ConflictoDeSync(
            questionId: 'q',
            motivo: 'La sesión ya no existe o no es tuya.',
          ),
        ],
      );
      await servicio.sincronizar();

      // Nada se ha perdido: sigue en la bandeja esperando al servidor bueno.
      expect(await servicio.cuantasPendientes(), 1);

      // Y cuando el servidor se pone al día, entra todo.
      servidor.respuestaDeSync = null;
      await servicio.sincronizar();

      expect(await servicio.cuantasPendientes(), 0);
      expect(servidor.registradas.map((s) => s.id), contains(sesion.id));
    });
  });
}
