import 'package:enam_app/core/error/failure.dart';
import 'package:enam_app/core/network/conectividad.dart';
import 'package:enam_app/core/storage/base_local.dart';
import 'package:enam_app/features/offline/data/almacen_offline.dart';
import 'package:enam_app/features/offline/data/servicio_offline.dart';
import 'package:enam_app/features/session/data/session_repository_offline.dart';
import 'package:enam_app/features/session/domain/session_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayuda/dobles_offline.dart';
import 'ayuda/offline.dart';

/// Descargar un área con la prueba **sin empezar** (RN-03 v2 / D-02).
///
/// Es el caso de todo el mundo el primer día: al registrarse hay una prueba de
/// 24 h que **no ha arrancado**, y el reloj arranca en cuanto se crea una
/// sesión. Por eso la descarga no reserva una práctica: sería regalarle el día
/// a alguien que solo estaba preparando el viaje.
///
/// La decisión es correcta; lo que no puede quedar es el hueco que deja. El
/// resto del banco de pruebas descarga siempre con `reservar: true`, así que
/// este camino —el que recorre el usuario nuevo— no lo miraba nadie.
void main() {
  late ServidorFalso servidor;
  late ConectividadFalsa red;
  late AlmacenOffline almacen;
  late BaseLocal base;
  late ServicioOffline servicio;
  late SessionRepositoryConRespaldo repo;

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

  test(
    'el área queda descargada aunque no se reserve práctica',
    () async {
      await servicio.descargar('medicina', reservar: false);

      expect(await servicio.resumenes(), hasLength(1));
      expect(await servicio.cuantasReservas(), 0);
    },
  );

  test('practicar con internet deja preparado el viaje', () async {
    // Con internet: descarga, sin gastar la prueba.
    await servicio.descargar('medicina', reservar: false);
    expect(await servicio.cuantasReservas(), 0);

    // La primera práctica normal. Acá el reloj de la prueba ya arrancó, así
    // que preparar el viaje deja de costar nada.
    await repo.startPractice(
      const PracticeConfig(areaIds: ['medicina'], cantidadPreguntas: 20),
    );
    await repo.preparandoElViaje; // se repone sin hacer esperar a nadie

    expect(await servicio.cuantasReservas(), 1);
  });

  test('y entonces se puede practicar sin señal', () async {
    await servicio.descargar('medicina', reservar: false);
    await repo.startPractice(
      const PracticeConfig(areaIds: ['medicina'], cantidadPreguntas: 20),
    );
    await repo.preparandoElViaje;

    // Se corta la señal, que es para lo que se descargó.
    servidor.hayRed = false;
    red.cambiar(conectado: false);

    final sesion = await repo.startPractice(
      const PracticeConfig(areaIds: ['medicina'], cantidadPreguntas: 20),
    );

    expect(sesion.preguntas, isNotEmpty);
  });

  test(
    'al reponer reservas sí se prepara la práctica del área descargada',
    () async {
      await servicio.descargar('medicina', reservar: false);
      expect(await servicio.cuantasReservas(), 0);

      // Es lo que corre cuando la prueba ya arrancó y vuelve la señal.
      await servicio.reponerReservas();

      expect(await servicio.cuantasReservas(), 1);
    },
  );

  test('el error de «no hay nada descargado» sigue siendo el correcto', () async {
    servidor.hayRed = false;
    red.cambiar(conectado: false);

    expect(
      () => repo.startPractice(
        const PracticeConfig(areaIds: ['medicina'], cantidadPreguntas: 20),
      ),
      throwsA(isA<SinDescargasFailure>()),
    );
  });
}
