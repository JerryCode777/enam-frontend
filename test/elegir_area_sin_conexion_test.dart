import 'package:enam_app/core/network/conectividad.dart';
import 'package:enam_app/core/providers.dart';
import 'package:enam_app/features/catalog/domain/catalog_models.dart';
import 'package:enam_app/features/offline/data/servicio_offline.dart';
import 'package:enam_app/features/session/presentation/area_picker_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayuda/dobles_offline.dart';
import 'ayuda/offline.dart';

/// Elegir qué practicar cuando no hay señal.
///
/// Lo que se protege es el momento de decidir. Sin conexión solo se puede
/// practicar lo que está en el teléfono, y eso hay que decirlo **antes** de
/// elegir: dejar elegir un área que no se bajó y fallar al tocar «Empezar» es
/// la forma más rápida de que alguien concluya que la app está rota.
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

  setUp(() {
    servidor = ServidorFalso();
    servicio = ServicioOffline(
      almacen: AlmacenEnMemoria(),
      remoto: servidor,
      sesiones: servidor,
      usuarioId: 'usuario-1',
    );
  });

  Widget pantalla({required bool hayRed}) {
    return ProviderScope(
      overrides: [
        catalogProvider.overrideWith((_) async => areas),
        servicioOfflineProvider.overrideWithValue(servicio),
        conectividadProvider.overrideWithValue(
          ConectividadFalsa(conectado: hayRed),
        ),
        hayRedProvider.overrideWith((_) => Stream.value(hayRed)),
      ],
      child: const MaterialApp(home: AreaPickerScreen()),
    );
  }

  testWidgets('con conexión se puede elegir cualquier área', (tester) async {
    await tester.pumpWidget(pantalla(hayRed: true));
    await tester.pumpAndSettle();

    expect(find.text('Todo el temario'), findsOneWidget);
    expect(find.textContaining('Descárgala para practicarla'), findsNothing);
    expect(find.byIcon(Icons.lock), findsNothing);
  });

  testWidgets('sin conexión, lo que no se bajó queda con candado', (
    tester,
  ) async {
    await servicio.descargar('medicina', reservar: false);

    await tester.pumpWidget(pantalla(hayRed: false));
    await tester.pumpAndSettle();

    // Las dos siguen a la vista: esconder Cirugía haría creer que no existe.
    expect(find.text('Medicina'), findsOneWidget);
    expect(find.text('Cirugía'), findsOneWidget);

    // Y solo una lleva el aviso de qué hacer para tenerla.
    expect(
      find.text('Descárgala para practicarla sin conexión'),
      findsOneWidget,
    );
  });

  testWidgets('sin conexión el aviso explica la situación', (tester) async {
    await servicio.descargar('medicina', reservar: false);

    await tester.pumpWidget(pantalla(hayRed: false));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('puedes practicar lo que descargaste'),
      findsOneWidget,
    );
    expect(find.text('Todo lo descargado'), findsOneWidget);
  });

  testWidgets('sin conexión y sin nada bajado, lo dice y no ofrece nada', (
    tester,
  ) async {
    await tester.pumpWidget(pantalla(hayRed: false));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('no tienes áreas descargadas'),
      findsOneWidget,
    );

    // Y «todo» no puede llevar a ninguna parte: no hay nada que practicar.
    final opcion = tester.widget<InkWell>(
      find
          .ancestor(
            of: find.text('Todo lo descargado'),
            matching: find.byType(InkWell),
          )
          .first,
    );
    expect(opcion.onTap, isNull);
  });
}
