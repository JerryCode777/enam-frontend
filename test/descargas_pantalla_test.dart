import 'dart:async';

import 'package:enam_app/core/network/conectividad.dart';
import 'package:enam_app/core/providers.dart';
import 'package:enam_app/features/catalog/domain/catalog_models.dart';
import 'package:enam_app/features/offline/data/servicio_offline.dart';
import 'package:enam_app/features/offline/presentation/downloads_screen.dart';
import 'package:enam_app/features/subscription/domain/subscription_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'ayuda/dobles_offline.dart';
import 'ayuda/offline.dart';

/// La pantalla de descargas, con datos de verdad detrás.
///
/// Monta el servicio completo sobre SQLite en memoria: lo que se comprueba es
/// que tocar «Descargar» acabe en un área guardada y en una práctica lista,
/// que es la promesa de la pantalla.
void main() {
  late ServidorFalso servidor;
  late ServicioOffline servicio;

  const areas = [
    CatalogNode(
      id: 'medicina',
      nombre: 'Medicina',
      nivel: 'area',
      preguntasDisponibles: 40,
    ),
    CatalogNode(
      id: 'cirugia',
      nombre: 'Cirugía',
      nivel: 'area',
      preguntasDisponibles: 40,
    ),
  ];

  // La fila dice la fecha del paquete en español, como en la app.
  setUpAll(() => initializeDateFormatting('es'));

  setUp(() {
    servidor = ServidorFalso();

    servicio = ServicioOffline(
      // En memoria y no SQLite: dentro de `testWidgets` el reloj es falso y una
      // consulta a la base de verdad no se resuelve nunca. El SQL se prueba en
      // `almacen_offline_test.dart`.
      almacen: AlmacenEnMemoria(),
      remoto: servidor,
      sesiones: servidor,
      usuarioId: 'usuario-1',
    );
  });

  /// `pumpAndSettle` no sirve aquí: mientras algo se descarga la barra va
  /// indeterminada, y esa animación no termina nunca. Se bombea a mano.
  Future<void> asentar(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  Widget pantalla({bool hayRed = true, Subscription? suscripcion}) {
    return ProviderScope(
      overrides: [
        catalogProvider.overrideWith((_) async => areas),
        servicioOfflineProvider.overrideWithValue(servicio),
        conectividadProvider.overrideWithValue(
          ConectividadFalsa(conectado: hayRed),
        ),
        hayRedProvider.overrideWith((_) => Stream.value(hayRed)),
        subscriptionProvider.overrideWith(
          (_) async => suscripcion ?? suscripcionActiva,
        ),
      ],
      child: const MaterialApp(home: DownloadsScreen()),
    );
  }

  testWidgets('lista las áreas con lo que hay para bajar', (tester) async {
    await tester.pumpWidget(pantalla());
    await asentar(tester);

    expect(find.text('Medicina'), findsOneWidget);
    expect(find.text('Cirugía'), findsOneWidget);
    expect(find.text('40 preguntas disponibles'), findsNWidgets(2));
    expect(find.text('Todavía no hay prácticas listas'), findsOneWidget);
  });

  testWidgets('descargar deja el área al día y una práctica lista', (
    tester,
  ) async {
    await tester.pumpWidget(pantalla());
    await asentar(tester);

    await tester.tap(find.byTooltip('Descargar').first);
    await asentar(tester);

    expect(find.textContaining('40 preguntas'), findsWidgets);
    // La fecha en que el servidor generó el paquete, no un «al día» sin
    // referencia.
    expect(find.textContaining('actualizada el 20 jul'), findsOneWidget);
    expect(find.text('1 práctica lista sin conexión'), findsOneWidget);
    expect(find.text('Empezar una práctica'), findsOneWidget);

    // Y lo que importa de verdad: quedó guardado.
    expect(await servicio.resumenes(), hasLength(1));
    expect(await servicio.cuantasReservas(), 1);
  });

  testWidgets('con la prueba sin arrancar no promete lo que no da', (
    tester,
  ) async {
    await tester.pumpWidget(pantalla(suscripcion: pruebaSinArrancar));
    await asentar(tester);

    await tester.tap(find.byTooltip('Descargar').first);
    await asentar(tester);

    // El área sí baja: lo que no se crea es la práctica, para no gastarle las
    // 24 h a quien todavía no ha estudiado.
    expect(await servicio.resumenes(), hasLength(1));
    expect(await servicio.cuantasReservas(), 0);

    // Y entonces la pantalla no puede pedirle que descargue un área: acaba de
    // hacerlo. Ese texto era el que dejaba a la gente sin saber qué hacer.
    expect(
      find.text('Descarga un área y te dejamos una preparada.'),
      findsNothing,
    );
    expect(find.text('Tu práctica se prepara sola'), findsOneWidget);
  });

  testWidgets('eliminar pide confirmación antes de borrar', (tester) async {
    await servicio.descargar('medicina', reservar: true);

    await tester.pumpWidget(pantalla());
    await asentar(tester);

    await tester.tap(find.byTooltip('Eliminar del teléfono'));
    await asentar(tester);

    expect(find.text('¿Eliminar Medicina?'), findsOneWidget);

    await tester.tap(find.text('Conservar'));
    await asentar(tester);
    expect(await servicio.resumenes(), hasLength(1), reason: 'no se borró');

    await tester.tap(find.byTooltip('Eliminar del teléfono'));
    await asentar(tester);
    await tester.tap(find.text('Eliminar'));
    await asentar(tester);

    expect(await servicio.resumenes(), isEmpty);
  });

  testWidgets('sin conexión avisa en vez de intentar la descarga', (
    tester,
  ) async {
    servidor.hayRed = false;

    await tester.pumpWidget(pantalla(hayRed: false));
    await asentar(tester);

    expect(find.textContaining('Estás sin conexión'), findsOneWidget);

    await tester.tap(find.byTooltip('Descargar').first);
    await asentar(tester);

    expect(
      find.text('Necesitas internet para descargar Medicina.'),
      findsOneWidget,
    );
  });

  testWidgets('lo respondido sin señal se anuncia como pendiente', (
    tester,
  ) async {
    await servicio.descargar('medicina', reservar: true);
    servidor.hayRed = false;

    final sesion = (await servicio.tomarReserva());
    final local = await servicio.sesionLocal(sesion.id);
    await servicio.responderSinConexion(
      local!,
      preguntaId: sesion.preguntas.first.id,
      opcionId: '${sesion.preguntas.first.id}-b',
      tiempoMs: 3000,
    );

    await tester.pumpWidget(pantalla(hayRed: false));
    await asentar(tester);

    expect(find.textContaining('1 respuesta por enviar'), findsOneWidget);
  });

  testWidgets('si la descarga falla, la fila lo dice y deja reintentar', (
    tester,
  ) async {
    await tester.pumpWidget(pantalla());
    await asentar(tester);

    // El teléfono cree tener señal, pero el servidor no responde.
    servidor.hayRed = false;
    await tester.tap(find.byTooltip('Descargar').first);
    await asentar(tester);

    expect(
      find.text('No se pudo descargar. Toca para reintentar.'),
      findsOneWidget,
    );

    servidor.hayRed = true;
    await tester.tap(find.byTooltip('Reintentar la descarga'));
    await asentar(tester);

    expect(find.textContaining('No se pudo descargar'), findsNothing);
    expect(find.textContaining('actualizada el'), findsOneWidget);
  });

  testWidgets('una descarga en marcha se puede cancelar', (tester) async {
    await tester.pumpWidget(pantalla());
    await asentar(tester);

    final retener = servidor.retenerDescarga = Completer<void>();
    await tester.tap(find.byTooltip('Descargar').first);
    await tester.pump(const Duration(milliseconds: 250));

    await tester.tap(find.byTooltip('Cancelar la descarga'));
    retener.complete();
    await asentar(tester);

    // Nada guardado y sin aviso de error: cancelar no es fallar.
    expect(find.textContaining('actualizada el'), findsNothing);
    expect(find.textContaining('No se pudo descargar'), findsNothing);
    expect(find.byTooltip('Descargar'), findsNWidgets(2));
  });
}

/// Un plan pagado vigente: es quien puede descargar y para quien reservar una
/// práctica no gasta nada (la prueba ya no cuenta).
final suscripcionActiva = Subscription(
  id: 'sus-1',
  plan: const Plan(
    id: 'mensual',
    nombre: 'Mensual',
    precioCentimos: 2900,
    duracionDias: 30,
  ),
  estado: SubscriptionStatus.activa,
  origen: SubscriptionOrigin.culqi,
  inicia: DateTime(2026, 7),
  expira: DateTime(2026, 12),
);

/// La prueba de 24 h concedida y **sin arrancar**: el estado de todo usuario
/// recién registrado, y el que ningún test miraba.
///
/// Aquí descargar NO reserva práctica a propósito —crear la sesión arrancaría
/// el reloj de alguien que solo prepara el viaje (D-02)—, así que la pantalla
/// tiene que decir la verdad sobre lo que falta.
final pruebaSinArrancar = Subscription(
  id: 'sus-2',
  plan: const Plan(
    id: 'mensual',
    nombre: 'Mensual',
    precioCentimos: 2900,
    duracionDias: 30,
  ),
  estado: SubscriptionStatus.pruebaSinIniciar,
  origen: SubscriptionOrigin.sistema,
  inicia: DateTime(2026, 7),
);
