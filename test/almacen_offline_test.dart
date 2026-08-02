import 'package:enam_app/core/storage/base_local.dart';
import 'package:enam_app/features/offline/data/almacen_offline.dart';
import 'package:enam_app/features/offline/domain/offline_models.dart';
import 'package:enam_app/features/session/domain/session_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayuda/offline.dart';

/// La base local, contra SQLite de verdad.
void main() {
  late AlmacenOffline almacen;
  late BaseLocal base;

  const yo = 'usuario-1';
  const otro = 'usuario-2';

  final paquete = PaqueteOffline(
    areaId: 'medicina',
    generadoEn: DateTime(2026, 7, 20),
    preguntas: [preguntaDePrueba('q1'), preguntaDePrueba('q2')],
    total: 2,
  );

  setUp(() {
    final piezas = almacenEnMemoria();
    almacen = piezas.almacen;
    base = piezas.base;
  });

  // Sin esto la base en memoria se comparte entre pruebas: sqflite reutiliza la
  // que ya está abierta para la misma ruta, y una prueba ve las filas de otra.
  tearDown(() => base.cerrar());

  group('paquetes', () {
    test('lo guardado se recupera entero, con claves y explicaciones', () async {
      await almacen.guardarPaquete(yo, paquete);

      final leido = await almacen.paquete(yo, 'medicina');
      expect(leido, isNotNull);
      expect(leido!.preguntas, hasLength(2));
      // Lo que hace posible corregir sin conexión.
      expect(
        leido.preguntas.first.opciones.where((o) => o.esCorrecta == true),
        hasLength(1),
      );
      expect(leido.preguntas.first.explicacion, isNotEmpty);
    });

    test('descargar otra vez pisa la versión anterior', () async {
      await almacen.guardarPaquete(yo, paquete);
      await almacen.guardarPaquete(
        yo,
        paquete.copyWith(
          preguntas: [...paquete.preguntas, preguntaDePrueba('q3')],
          total: 3,
        ),
      );

      final resumenes = await almacen.resumenes(yo);
      expect(resumenes, hasLength(1), reason: 'no se duplica el área');
      expect(resumenes.single.total, 3);
    });

    test('el resumen sabe el tamaño sin descifrar el contenido', () async {
      await almacen.guardarPaquete(yo, paquete);

      final resumen = (await almacen.resumenes(yo)).single;
      expect(resumen.areaId, 'medicina');
      expect(resumen.total, 2);
      expect(resumen.bytes, greaterThan(0));
    });

    test('un área que no se descargó no está', () async {
      expect(await almacen.paquete(yo, 'cirugia'), isNull);
    });

    test('eliminar libera el área', () async {
      await almacen.guardarPaquete(yo, paquete);
      await almacen.borrarPaquete(yo, 'medicina');

      expect(await almacen.paquete(yo, 'medicina'), isNull);
      expect(await almacen.resumenes(yo), isEmpty);
    });

    test('lo de una cuenta no se ve desde la otra', () async {
      await almacen.guardarPaquete(yo, paquete);

      expect(await almacen.resumenes(otro), isEmpty);
      expect(await almacen.paquete(otro, 'medicina'), isNull);
    });
  });

  group('sesiones guardadas', () {
    test('una reserva se guarda con sus preguntas y se recupera', () async {
      final sesion = sesionDePrueba(cuantas: 5);
      await almacen.guardarSesion(
        yo,
        areaId: 'medicina',
        estado: EstadoSesionLocal.reservada,
        sesion: sesion,
      );

      final guardada = await almacen.sesion(yo, sesion.id);
      expect(guardada, isNotNull);
      expect(guardada!.estado, EstadoSesionLocal.reservada);
      expect(guardada.areaId, 'medicina');
      expect(guardada.sesion.preguntas, hasLength(5));
    });

    test('se puede filtrar por estado', () async {
      await almacen.guardarSesion(
        yo,
        areaId: 'medicina',
        estado: EstadoSesionLocal.reservada,
        sesion: sesionDePrueba(id: 'reservada-1'),
      );
      await almacen.guardarSesion(
        yo,
        areaId: 'cirugia',
        estado: EstadoSesionLocal.enCurso,
        sesion: sesionDePrueba(id: 'a-medias'),
      );

      final reservas = await almacen.sesiones(
        yo,
        estado: EstadoSesionLocal.reservada,
      );
      expect(reservas.map((s) => s.sesion.id), ['reservada-1']);
      expect(await almacen.sesiones(yo), hasLength(2));
    });

    test('guardar la misma sesión actualiza su estado y sus respuestas',
        () async {
      final sesion = sesionDePrueba();
      await almacen.guardarSesion(
        yo,
        areaId: 'medicina',
        estado: EstadoSesionLocal.reservada,
        sesion: sesion,
      );

      await almacen.guardarSesion(
        yo,
        areaId: 'medicina',
        estado: EstadoSesionLocal.enCurso,
        sesion: sesion.copyWith(
          respuestas: {
            'x': const Answer(questionId: 'x', optionId: 'x-b', esCorrecta: true),
          },
        ),
      );

      final guardada = await almacen.sesion(yo, sesion.id);
      expect(guardada!.estado, EstadoSesionLocal.enCurso);
      expect(guardada.sesion.respuestas, hasLength(1));
      expect(await almacen.sesiones(yo), hasLength(1));
    });
  });

  group('bandeja de salida', () {
    RespuestaPendiente respuesta(String pregunta, {DateTime? cuando}) => (
      sesionId: 'sesion-1',
      preguntaId: pregunta,
      opcionId: '$pregunta-b',
      tiempoMs: 4000,
      marcada: false,
      respondidaEn: cuando ?? DateTime(2026, 7, 30, 10),
    );

    test('encolar y contar', () async {
      await almacen.encolar(yo, respuesta('q1'));
      await almacen.encolar(yo, respuesta('q2'));

      expect(await almacen.cuantasPendientes(yo), 2);
      expect(await almacen.cuantasPendientes(otro), 0);
    });

    test('responder otra vez la misma pregunta reemplaza, no duplica',
        () async {
      await almacen.encolar(yo, respuesta('q1'));
      await almacen.encolar(
        yo,
        (
          sesionId: 'sesion-1',
          preguntaId: 'q1',
          opcionId: 'q1-c',
          tiempoMs: 9000,
          marcada: true,
          respondidaEn: DateTime(2026, 7, 30, 10, 5),
        ),
      );

      final pendientes = await almacen.pendientes(yo);
      expect(pendientes, hasLength(1));
      expect(pendientes.single.opcionId, 'q1-c');
      expect(pendientes.single.marcada, isTrue);
    });

    test('salen en el orden en que se respondieron', () async {
      await almacen.encolar(
        yo,
        respuesta('tarde', cuando: DateTime(2026, 7, 30, 12)),
      );
      await almacen.encolar(
        yo,
        respuesta('temprano', cuando: DateTime(2026, 7, 30, 8)),
      );

      expect(
        (await almacen.pendientes(yo)).map((r) => r.preguntaId),
        ['temprano', 'tarde'],
      );
    });

    test('una respuesta en blanco se encola igual', () async {
      await almacen.encolar(yo, (
        sesionId: 'sesion-1',
        preguntaId: 'q9',
        opcionId: null,
        tiempoMs: 1000,
        marcada: false,
        respondidaEn: DateTime(2026, 7, 30, 10),
      ));

      expect((await almacen.pendientes(yo)).single.opcionId, isNull);
    });

    test('quitar solo saca las preguntas indicadas', () async {
      await almacen.encolar(yo, respuesta('q1'));
      await almacen.encolar(yo, respuesta('q2'));
      await almacen.encolar(yo, respuesta('q3'));

      await almacen.quitarPendientes(yo, 'sesion-1', ['q1', 'q3']);

      expect((await almacen.pendientes(yo)).map((r) => r.preguntaId), ['q2']);
    });

    test('quitar sin ids no borra nada', () async {
      await almacen.encolar(yo, respuesta('q1'));
      await almacen.quitarPendientes(yo, 'sesion-1', const []);

      expect(await almacen.cuantasPendientes(yo), 1);
    });
  });

  group('cierres pendientes', () {
    test('se apuntan y se quitan', () async {
      await almacen.marcarPorEnviar(yo, 'sesion-1', DateTime(2026, 7, 30));
      await almacen.marcarPorEnviar(yo, 'sesion-2', DateTime(2026, 7, 31));

      expect(await almacen.porEnviar(yo), ['sesion-1', 'sesion-2']);

      await almacen.quitarPorEnviar(yo, 'sesion-1');
      expect(await almacen.porEnviar(yo), ['sesion-2']);
    });
  });

  test('cerrar sesión borra todo lo del usuario y nada de los demás', () async {
    await almacen.guardarPaquete(yo, paquete);
    await almacen.guardarPaquete(otro, paquete);
    await almacen.guardarSesion(
      yo,
      areaId: 'medicina',
      estado: EstadoSesionLocal.reservada,
      sesion: sesionDePrueba(),
    );
    await almacen.encolar(yo, (
      sesionId: 'sesion-1',
      preguntaId: 'q1',
      opcionId: 'q1-b',
      tiempoMs: 100,
      marcada: false,
      respondidaEn: DateTime(2026, 7, 30),
    ));
    await almacen.marcarPorEnviar(yo, 'sesion-1', DateTime(2026, 7, 30));

    await almacen.olvidarTodo(yo);

    expect(await almacen.resumenes(yo), isEmpty);
    expect(await almacen.sesiones(yo), isEmpty);
    expect(await almacen.cuantasPendientes(yo), 0);
    expect(await almacen.porEnviar(yo), isEmpty);

    expect(await almacen.resumenes(otro), hasLength(1));
  });
}
