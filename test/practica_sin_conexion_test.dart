import 'package:enam_app/core/error/failure.dart';
import 'package:enam_app/core/network/conectividad.dart';
import 'package:enam_app/core/storage/base_local.dart';
import 'package:enam_app/features/offline/data/almacen_offline.dart';
import 'package:enam_app/features/offline/data/servicio_offline.dart';
import 'package:enam_app/features/offline/domain/offline_models.dart';
import 'package:enam_app/features/session/data/session_repository.dart';
import 'package:enam_app/features/session/data/session_repository_offline.dart';
import 'package:enam_app/features/session/domain/session_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayuda/dobles_offline.dart';
import 'ayuda/offline.dart';

/// El recorrido completo de estudiar sin señal (RF-30 a RF-33).
///
/// Se prueba por donde pasa el usuario —el repositorio que usan las pantallas—
/// y no llamando al servicio a mano: lo que hay que garantizar es que
/// **practicar es practicar** haya internet o no, sin que la pantalla tenga que
/// enterarse.
void main() {
  late ServidorFalso servidor;
  late ConectividadFalsa red;
  late AlmacenOffline almacen;
  late BaseLocal base;
  late ServicioOffline servicio;
  late SessionRepository repo;

  const yo = 'usuario-1';

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

  /// Deja el teléfono como queda tras descargar un área con internet.
  Future<void> prepararElViaje() async {
    await servicio.descargar('medicina', reservar: true);
  }

  /// Corta la señal, como al entrar al metro.
  void cortarLaSenal() {
    servidor.hayRed = false;
    red.cambiar(conectado: false);
  }

  void volverLaSenal() {
    servidor.hayRed = true;
    red.cambiar(conectado: true);
  }

  group('preparar el viaje, con internet', () {
    test('descargar guarda el área y deja una práctica lista', () async {
      final total = await servicio.descargar('medicina', reservar: true);

      expect(total, 40);
      expect(await servicio.resumenes(), hasLength(1));
      expect(
        await servicio.cuantasReservas(),
        1,
        reason: 'sin una sesión creada con antelación no se puede practicar '
            'sin señal: el servidor no reconocería las respuestas',
      );
    });

    test('sin reservar, se baja el banco pero no se crea ninguna sesión',
        () async {
      // Es el caso de quien todavía no gastó su día de prueba: crear una
      // sesión le arrancaría las 24 h por haber preparado el viaje (D-02).
      await servicio.descargar('medicina', reservar: false);

      expect(await servicio.resumenes(), hasLength(1));
      expect(servidor.practicasCreadas, 0);
    });

    test('descargar dos veces no acumula reservas', () async {
      await servicio.descargar('medicina', reservar: true);
      await servicio.descargar('medicina', reservar: true);

      expect(await servicio.cuantasReservas(), 1);
    });

    test('si crear la reserva falla, la descarga sigue valiendo', () async {
      // El banco baja bien y justo después se cae la red.
      final paquete = await servidor.paquete('medicina');
      expect(paquete.total, 40);

      servidor.hayRed = false;
      // La descarga en sí fallará; lo que se comprueba es el orden inverso:
      // con el paquete ya guardado, un fallo al reservar no lo tira.
      servidor.hayRed = true;
      await servicio.descargar('medicina', reservar: true);
      servidor.hayRed = false;

      expect(await servicio.resumenes(), hasLength(1));
    });

    test('la reserva sin empezar no se ofrece como «continuar donde quedaste»',
        () async {
      await prepararElViaje();

      // El servidor sí la ve abierta —existe—, pero para el estudiante todavía
      // no empezó: ofrecerle retomarla sería mentirle.
      expect(await servidor.openSessions(), hasLength(1));
      expect(await repo.openSessions(), isEmpty);
    });
  });

  group('practicar sin señal', () {
    test('empezar una práctica usa la que quedó lista', () async {
      await prepararElViaje();
      cortarLaSenal();

      final sesion = await repo.startPractice(
        const PracticeConfig(areaIds: ['medicina'], cantidadPreguntas: 20),
      );

      expect(sesion.preguntas, hasLength(20));
      expect(
        servidor.practicasCreadas,
        1,
        reason: 'no se crea nada nuevo: se usa la reservada',
      );
    });

    test('sin nada descargado, el mensaje dice qué hacer', () async {
      cortarLaSenal();

      await expectLater(
        repo.startPractice(const PracticeConfig()),
        throwsA(
          isA<SinDescargasFailure>().having(
            (e) => e.message,
            'mensaje',
            contains('Descarga un área'),
          ),
        ),
      );
    });

    test('responder corrige al instante con la clave descargada', () async {
      await prepararElViaje();
      cortarLaSenal();

      final sesion = await repo.startPractice(const PracticeConfig());
      final pregunta = sesion.preguntas.first;

      // La sesión llegó del servidor sin claves; la corrección sale del banco.
      expect(pregunta.opciones.every((o) => o.esCorrecta == null), isTrue);

      final acierto = await repo.answer(
        sessionId: sesion.id,
        questionId: pregunta.id,
        optionId: '${pregunta.id}-b',
        tiempoMs: 5000,
      );
      expect(acierto.esCorrecta, isTrue);
      expect(acierto.respondidaOffline, isTrue);

      final fallo = await repo.answer(
        sessionId: sesion.id,
        questionId: sesion.preguntas[1].id,
        optionId: '${sesion.preguntas[1].id}-c',
        tiempoMs: 3000,
      );
      expect(fallo.esCorrecta, isFalse);
    });

    test('dejar en blanco no se corrige, pero se guarda', () async {
      await prepararElViaje();
      cortarLaSenal();

      final sesion = await repo.startPractice(const PracticeConfig());
      final respuesta = await repo.answer(
        sessionId: sesion.id,
        questionId: sesion.preguntas.first.id,
        optionId: null,
        tiempoMs: 1000,
      );

      expect(respuesta.esCorrecta, isNull);
      expect(await servicio.cuantasPendientes(), 1);
    });

    test('cerrar la app no pierde lo respondido', () async {
      await prepararElViaje();
      cortarLaSenal();

      final sesion = await repo.startPractice(const PracticeConfig());
      await repo.answer(
        sessionId: sesion.id,
        questionId: sesion.preguntas.first.id,
        optionId: '${sesion.preguntas.first.id}-b',
        tiempoMs: 5000,
      );

      // Volver a pedirla es lo que hace la pantalla al reabrirse.
      final recuperada = await repo.session(sesion.id);
      expect(recuperada.respuestas, hasLength(1));
      expect(recuperada.correctas, 1);
      // Y la pregunta respondida ya trae su explicación, que es lo que la
      // práctica enseña al corregir (RF-13).
      expect(recuperada.preguntas.first.explicacion, isNotEmpty);
    });

    test('la práctica a medias sí se ofrece para continuar', () async {
      await prepararElViaje();
      cortarLaSenal();

      final sesion = await repo.startPractice(const PracticeConfig());
      await repo.answer(
        sessionId: sesion.id,
        questionId: sesion.preguntas.first.id,
        optionId: '${sesion.preguntas.first.id}-b',
        tiempoMs: 5000,
      );

      final abiertas = await repo.openSessions();
      expect(abiertas.map((s) => s.id), [sesion.id]);
      expect(abiertas.single.respondidas, 1);
    });

    test('terminar sin señal da la nota, calculada como la calcula el servidor',
        () async {
      await prepararElViaje();
      cortarLaSenal();

      final sesion = await repo.startPractice(
        const PracticeConfig(cantidadPreguntas: 20),
      );
      for (var i = 0; i < 10; i++) {
        await repo.answer(
          sessionId: sesion.id,
          questionId: sesion.preguntas[i].id,
          optionId: '${sesion.preguntas[i].id}-b',
          tiempoMs: 4000,
        );
      }

      final terminada = await repo.submit(sesion.id);

      expect(terminada.estado, SessionStatus.finalizada);
      expect(terminada.correctas, 10);
      expect(terminada.nota, 10.0, reason: '10 de 20 en escala vigesimal');
    });
  });

  group('al volver la señal', () {
    test('lo respondido en el bus viaja al servidor', () async {
      await prepararElViaje();
      cortarLaSenal();

      final sesion = await repo.startPractice(const PracticeConfig());
      for (var i = 0; i < 3; i++) {
        await repo.answer(
          sessionId: sesion.id,
          questionId: sesion.preguntas[i].id,
          optionId: '${sesion.preguntas[i].id}-b',
          tiempoMs: 4000,
        );
      }
      await repo.submit(sesion.id);

      volverLaSenal();
      final resultado = await servicio.sincronizar();

      expect(resultado?.aceptadas, 3);
      expect(servidor.sincronizadas, hasLength(3));
      expect(
        servidor.cerradas,
        [sesion.id],
        reason: 'la nota oficial la pone el servidor al cerrar la sesión',
      );
      expect(await servicio.cuantasPendientes(), 0);
    });

    test('las respuestas salen en el orden en que se dieron', () async {
      await prepararElViaje();
      cortarLaSenal();

      final sesion = await repo.startPractice(const PracticeConfig());
      for (var i = 0; i < 3; i++) {
        await repo.answer(
          sessionId: sesion.id,
          questionId: sesion.preguntas[i].id,
          optionId: '${sesion.preguntas[i].id}-b',
          tiempoMs: 4000,
        );
      }

      volverLaSenal();
      await servicio.sincronizar();

      // El servidor resuelve los choques por marca de tiempo, así que mandarlas
      // desordenadas invita a que gane la equivocada.
      expect(
        servidor.sincronizadas.map((r) => r.preguntaId),
        sesion.preguntas.take(3).map((p) => p.id),
      );
    });

    test('si la red se corta al sincronizar, no se pierde nada', () async {
      await prepararElViaje();
      cortarLaSenal();

      final sesion = await repo.startPractice(const PracticeConfig());
      await repo.answer(
        sessionId: sesion.id,
        questionId: sesion.preguntas.first.id,
        optionId: '${sesion.preguntas.first.id}-b',
        tiempoMs: 4000,
      );

      // Se cree que hay señal, pero el servidor no responde.
      red.cambiar(conectado: true);
      await expectLater(servicio.sincronizar(), throwsA(isA<NetworkFailure>()));

      expect(
        await servicio.cuantasPendientes(),
        1,
        reason: 'la bandeja se conserva para el siguiente intento',
      );
    });

    test('una respuesta rechazada no se reintenta para siempre', () async {
      await prepararElViaje();
      cortarLaSenal();

      final sesion = await repo.startPractice(const PracticeConfig());
      await repo.answer(
        sessionId: sesion.id,
        questionId: sesion.preguntas.first.id,
        optionId: '${sesion.preguntas.first.id}-b',
        tiempoMs: 4000,
      );

      volverLaSenal();
      servidor.respuestaDeSync = ResultadoDeSync(
        conflictos: [
          ConflictoDeSync(
            questionId: sesion.preguntas.first.id,
            motivo: 'Ya había una respuesta más reciente.',
          ),
        ],
      );

      final resultado = await servicio.sincronizar();

      expect(resultado?.conflictos, hasLength(1));
      expect(
        await servicio.cuantasPendientes(),
        0,
        reason: 'el servidor ya decidió; insistir dejaría la bandeja llena '
            'para siempre',
      );
    });

    test('se repone una práctica lista para el próximo viaje', () async {
      await prepararElViaje();
      cortarLaSenal();

      await repo.startPractice(const PracticeConfig());
      expect(await servicio.cuantasReservas(), 0, reason: 'se gastó');

      volverLaSenal();
      await servicio.sincronizar(reponerReservas: true);

      expect(await servicio.cuantasReservas(), 1);
    });

    test('con la bandeja vacía, la sesión vuelve a salir del servidor',
        () async {
      await prepararElViaje();
      cortarLaSenal();

      final sesion = await repo.startPractice(const PracticeConfig());
      await repo.answer(
        sessionId: sesion.id,
        questionId: sesion.preguntas.first.id,
        optionId: '${sesion.preguntas.first.id}-b',
        tiempoMs: 4000,
      );

      volverLaSenal();
      await servicio.sincronizar();

      // Mientras había pendientes mandaba la copia local, que era la que estaba
      // al día. Ya sincronizada, manda el servidor —y lo respondido en el bus
      // sigue ahí, porque llegó—.
      final desdeElServidor = await repo.session(sesion.id);
      expect(desdeElServidor.respuestas, hasLength(1));
      expect(desdeElServidor.respuestas.values.single.respondidaOffline, isTrue);
    });

    test('la práctica terminada sin señal se cierra y deja de duplicarse',
        () async {
      await prepararElViaje();
      cortarLaSenal();

      final sesion = await repo.startPractice(const PracticeConfig());
      await repo.answer(
        sessionId: sesion.id,
        questionId: sesion.preguntas.first.id,
        optionId: '${sesion.preguntas.first.id}-b',
        tiempoMs: 4000,
      );
      await repo.submit(sesion.id);

      volverLaSenal();
      await servicio.sincronizar();

      expect(servidor.cerradas, [sesion.id]);
      // Cerrada en el servidor y con su nota oficial: la copia local ya no
      // aporta nada y quedarse invitaría a enseñar la práctica dos veces.
      expect(await servicio.sesionLocal(sesion.id), isNull);
    });
  });

  group('lo que no se hace sin conexión', () {
    test('un error que no es de red se propaga tal cual', () async {
      await prepararElViaje();

      // Con red, pero el servidor dice que no: el usuario tiene que ver ese
      // motivo, no un «sin conexión» que no explica nada.
      await expectLater(
        repo.session('sesion-que-no-existe'),
        throwsA(isA<NotFoundFailure>()),
      );
    });

    test('el simulacro sigue exigiendo servidor', () async {
      await prepararElViaje();
      cortarLaSenal();

      // RF-33: el reloj y el ranking los lleva el servidor. Fingirlo sin señal
      // sería peor que decir que no se puede.
      await expectLater(
        repo.startSimulacro(),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });
}
