import 'package:enam_app/core/network/conectividad.dart';
import 'package:enam_app/core/providers.dart';
import 'package:enam_app/core/theme/app_theme.dart';
import 'package:enam_app/features/auth/domain/auth_models.dart';
import 'package:enam_app/features/catalog/domain/catalog_models.dart';
import 'package:enam_app/features/offline/data/servicio_offline.dart';
import 'package:enam_app/features/session/data/session_repository.dart';
import 'package:enam_app/features/session/data/session_repository_offline.dart';
import 'package:enam_app/features/session/domain/session_models.dart';
import 'package:enam_app/features/session/presentation/area_picker_screen.dart';
import 'package:enam_app/features/session/presentation/practice_config_screen.dart';
import 'package:enam_app/features/subscription/domain/acceso.dart';
import 'package:enam_app/features/subscription/domain/subscription_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'ayuda/dobles_offline.dart';
import 'ayuda/offline.dart';

/// «Preguntas con imagen»: practicar solo las que traen un ECG, una
/// radiografía o una foto clínica (`conImagen` en el POST de práctica).
void main() {
  const catalogo = [
    CatalogNode(
      id: 'medicina',
      nombre: 'Medicina',
      nivel: 'area',
      peso: 40,
      preguntasDisponibles: 300,
      preguntasConImagen: 12,
      hijos: [
        CatalogNode(
          id: 'medicina-cardiovascular',
          nombre: 'Cardiovascular',
          nivel: 'sub_area',
          preguntasDisponibles: 148,
          preguntasConImagen: 12,
        ),
        CatalogNode(
          id: 'medicina-respiratorio',
          nombre: 'Respiratorio',
          nivel: 'sub_area',
          preguntasDisponibles: 127,
        ),
      ],
    ),
    CatalogNode(
      id: 'pediatria',
      nombre: 'Pediatría',
      nivel: 'area',
      peso: 30,
      preguntasDisponibles: 200,
    ),
  ];

  group('el pedido', () {
    test('una práctica normal sale igual que antes, sin conImagen', () {
      expect(
        const PracticeConfig(areaIds: ['medicina']).toJson(),
        isNot(contains('conImagen')),
      );
    });

    test('con imagen, conImagen: true', () {
      expect(
        const PracticeConfig(conImagen: true).toJson()['conImagen'],
        isTrue,
      );
    });

    test('el catálogo trae cuántas tienen imagen', () {
      final nodo = CatalogNode.fromJson({
        'id': 'medicina',
        'nombre': 'Medicina',
        'nivel': 'area',
        'preguntasConImagen': 20,
      });
      expect(nodo.preguntasConImagen, 20);
      // Un servidor que todavía no lo manda: 0, y el modo no se enseña.
      expect(
        CatalogNode.fromJson({
          'id': 'x',
          'nombre': 'X',
          'nivel': 'area',
        }).preguntasConImagen,
        0,
      );
    });
  });

  group('la pantalla de práctica', () {
    testWidgets('Premium: se activa y se combina con el área', (tester) async {
      final repo = _Sesiones();
      await _montar(
        tester,
        const PracticeConfigScreen(nodoId: 'medicina-cardiovascular'),
        catalogo: catalogo,
        repo: repo,
      );

      expect(find.text('Preguntas con imagen (12)'), findsOneWidget);
      await tester.tap(find.byType(Switch));
      await _asentar(tester);

      // Hay 12: pedir 20 diría una cosa y haría otra.
      await tester.tap(find.text('Empezar · 12 preguntas'));
      await _asentar(tester);

      final pedido = repo.pedidos.single;
      expect(pedido.conImagen, isTrue);
      expect(pedido.subtemaIds, ['medicina-cardiovascular']);
      expect(pedido.cantidadPreguntas, 12);
    });

    testWidgets('sin tocarlo, la práctica es la de siempre', (tester) async {
      final repo = _Sesiones();
      await _montar(
        tester,
        const PracticeConfigScreen(),
        catalogo: catalogo,
        repo: repo,
      );
      // Sin área: cuenta las de todo el temario.
      expect(find.text('Preguntas con imagen (12)'), findsOneWidget);

      await tester.tap(find.text('Empezar · 20 preguntas'));
      await _asentar(tester);
      expect(repo.pedidos.single.conImagen, isNull);
    });

    testWidgets('un área sin imágenes no lo deja activar', (tester) async {
      await _montar(
        tester,
        const PracticeConfigScreen(nodoId: 'medicina-respiratorio'),
        catalogo: catalogo,
      );
      expect(find.text('Preguntas con imagen'), findsOneWidget);
      expect(find.textContaining('todavía no tiene'), findsOneWidget);
      expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
    });

    testWidgets('si el servidor no las cuenta, ni aparece', (tester) async {
      await _montar(
        tester,
        const PracticeConfigScreen(),
        catalogo: [for (final a in catalogo) a.copyWith(preguntasConImagen: 0)],
      );
      expect(find.byType(InterruptorConImagen), findsNothing);
    });

    testWidgets('gratis: entra en el cupo del día, sin muro', (tester) async {
      final repo = _Sesiones();
      await _montar(
        tester,
        const PracticeConfigScreen(),
        catalogo: catalogo,
        repo: repo,
        gratis: const AccesoGratis(preguntasPorDia: 12, restantesHoy: 6),
      );
      await tester.tap(find.byType(Switch));
      await _asentar(tester);
      await tester.tap(find.text('Empezar · 6 preguntas'));
      await _asentar(tester);

      final pedido = repo.pedidos.single;
      expect(pedido.conImagen, isTrue);
      expect(pedido.areaIds, isEmpty);
      expect(pedido.cantidadPreguntas, 6);
    });

    testWidgets('llega con el modo puesto desde la ruta', (tester) async {
      await _montar(
        tester,
        const PracticeConfigScreen(conImagenInicial: true),
        catalogo: catalogo,
      );
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
      expect(find.text('Empezar · 12 preguntas'), findsOneWidget);
    });
  });

  group('elegir el área', () {
    Widget picker({required bool soloConImagen}) => ProviderScope(
      overrides: [
        catalogProvider.overrideWith((_) async => catalogo),
        servicioOfflineProvider.overrideWithValue(
          ServicioOffline(
            almacen: AlmacenEnMemoria(),
            remoto: ServidorFalso(),
            sesiones: ServidorFalso(),
            usuarioId: 'u1',
          ),
        ),
        conectividadProvider.overrideWithValue(ConectividadFalsa()),
        hayRedProvider.overrideWith((_) => Stream.value(true)),
      ],
      child: MaterialApp(home: AreaPickerScreen(soloConImagen: soloConImagen)),
    );

    testWidgets('solo se ofrece lo que tiene imágenes', (tester) async {
      await tester.pumpWidget(picker(soloConImagen: true));
      await tester.pumpAndSettle();

      expect(find.text('Medicina'), findsOneWidget);
      expect(find.text('Pediatría'), findsNothing);
      expect(find.text('12 preguntas con imagen'), findsOneWidget);

      await tester.tap(find.text('Medicina'));
      await tester.pumpAndSettle();
      expect(find.text('Cardiovascular'), findsOneWidget);
      expect(find.text('Respiratorio'), findsNothing);
    });

    testWidgets('sin el modo, todo como siempre', (tester) async {
      await tester.pumpWidget(picker(soloConImagen: false));
      await tester.pumpAndSettle();
      expect(find.text('Pediatría'), findsOneWidget);
      expect(find.textContaining('con imagen'), findsNothing);
    });
  });

  group('sin conexión', () {
    late ServidorFalso servidor;
    late ConectividadFalsa red;
    late SessionRepositoryConRespaldo repo;
    late ServicioOffline servicio;

    setUp(() {
      servidor = ServidorFalso()..conImagen = {3, 7, 11};
      red = ConectividadFalsa();
      final piezas = almacenEnMemoria();
      servicio = ServicioOffline(
        almacen: piezas.almacen,
        remoto: servidor,
        sesiones: servidor,
        usuarioId: 'u1',
      );
      repo = SessionRepositoryConRespaldo(
        remoto: servidor,
        offline: servicio,
        red: red,
      );
      addTearDown(() async {
        await red.cerrar();
        await piezas.base.cerrar();
      });
    });

    test('se arma con las descargadas que tienen imagen', () async {
      await servicio.descargar('medicina', reservar: true);
      servidor.hayRed = false;
      red.cambiar(conectado: false);

      final sesion = await repo.startPractice(
        const PracticeConfig(cantidadPreguntas: 20, conImagen: true),
      );
      expect(sesion.preguntas.map((p) => p.id).toSet(), {
        'medicina-p3',
        'medicina-p7',
        'medicina-p11',
      });
      expect(
        sesion.preguntas.every((p) => p.imagenesAMostrar.isNotEmpty),
        isTrue,
      );
    });

    test('si lo descargado no tiene, lo dice', () async {
      servidor.conImagen = const {};
      await servicio.descargar('medicina', reservar: true);
      servidor.hayRed = false;
      red.cambiar(conectado: false);

      await expectLater(
        repo.startPractice(const PracticeConfig(conImagen: true)),
        throwsA(
          isA<Exception>().having(
            (e) => '$e',
            'mensaje',
            contains('no tiene preguntas con imagen'),
          ),
        ),
      );
    });
  });
}

Future<void> _montar(
  WidgetTester tester,
  Widget pantalla, {
  required List<CatalogNode> catalogo,
  SessionRepository? repo,
  AccesoGratis? gratis,
}) async {
  tester.view
    ..physicalSize = const Size(393, 852) * 3
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final sesiones = repo ?? _Sesiones();
  final router = GoRouter(
    initialLocation: '/pantalla',
    routes: [
      GoRoute(path: '/pantalla', builder: (_, _) => pantalla),
      GoRoute(
        path: '/practica/sesion/:id',
        builder: (_, s) => Text('sesion ${s.pathParameters['id']}'),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(_ConSesion.new),
        cupoGratisProvider.overrideWithValue(gratis),
        subscriptionProvider.overrideWith(
          (ref) async => Subscription(
            id: 's1',
            plan: const Plan(
              id: 'mensual',
              nombre: 'Mensual',
              precioCentimos: 0,
              duracionDias: 30,
              esGratuito: false,
            ),
            estado: SubscriptionStatus.activa,
            origen: SubscriptionOrigin.sistema,
            inicia: DateTime(2026, 10),
            acceso: gratis ?? const AccesoPremium(),
          ),
        ),
        catalogProvider.overrideWith((_) async => catalogo),
        sessionRepositoryProvider.overrideWithValue(sesiones),
        sessionRepositoryRemotoProvider.overrideWithValue(sesiones),
        sesionesAbiertasProvider.overrideWith((ref) async => const []),
        almacenOfflineProvider.overrideWithValue(AlmacenEnMemoria()),
        dashboardProvider.overrideWith((ref) => Future.error(Exception('no'))),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await _asentar(tester);
}

Future<void> _asentar(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 400));
  }
}

/// Anota lo pedido.
class _Sesiones extends MockSessionRepository {
  final pedidos = <PracticeConfig>[];

  @override
  Future<StudySession> startPractice(PracticeConfig config) async {
    pedidos.add(config);
    return super.startPractice(config);
  }
}

class _ConSesion extends AuthController {
  @override
  Future<AuthState> build() async => AuthSignedIn(
    User(
      id: 'u1',
      email: 'a@b.pe',
      nombre: 'Ana',
      emailVerificado: true,
      universidad: 'UNSA',
      condicion: StudentCondition.interno,
      fechaObjetivo: DateTime(2026, 12, 12),
    ),
  );
}
