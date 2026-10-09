import 'dart:convert';

import 'package:enam_app/core/error/failure.dart';
import 'package:enam_app/core/providers.dart';
import 'package:enam_app/core/router/routes.dart';
import 'package:enam_app/core/theme/app_theme.dart';
import 'package:enam_app/features/auth/domain/auth_models.dart';
import 'package:enam_app/features/home/domain/siguiente_accion.dart';
import 'package:enam_app/features/session/data/session_repository.dart';
import 'package:enam_app/features/session/domain/session_models.dart';
import 'package:enam_app/features/session/presentation/national_mock_screen.dart';
import 'package:enam_app/features/session/presentation/practice_config_screen.dart';
import 'package:enam_app/features/session/presentation/question_screen.dart';
import 'package:enam_app/features/session/presentation/simulacro_hub_screen.dart';
import 'package:enam_app/features/session/presentation/widgets/option_card.dart';
import 'package:enam_app/features/subscription/domain/acceso.dart';
import 'package:enam_app/features/subscription/domain/subscription_models.dart';
import 'package:enam_app/features/subscription/presentation/muro_de_venta_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'ayuda/offline.dart';

/// Gratis limitado, fase 1 (`PLAN-GRATIS-LIMITADO.md`).
///
/// Tras la prueba la app sigue abierta con 10 preguntas al día, y se vende en
/// el momento en que se topa un límite: el cupo agotado o una función de pago.
/// Los dos 403 nuevos (`LIMITE_DIARIO`, `FUNCION_PREMIUM`) son el muro, nunca
/// un error.
void main() {
  setUpAll(() => initializeDateFormatting('es'));

  group('El acceso que manda el servidor', () {
    test('premium, gratis con su cupo, o nada si el servidor es anterior', () {
      expect(
        Acceso.fromJson({'nivel': 'premium', 'gratis': null}),
        const AccesoPremium(),
      );
      expect(
        Acceso.fromJson({
          'nivel': 'gratis',
          'gratis': {
            'preguntasPorDia': 10,
            'restantesHoy': 6,
            'renuevaEn': '2026-10-05T05:00:00Z',
          },
        }),
        AccesoGratis(
          preguntasPorDia: 10,
          restantesHoy: 6,
          renuevaEn: DateTime.utc(2026, 10, 5, 5),
        ),
      );
      expect(Acceso.fromJson(null), isNull);
      expect(Acceso.fromJson({'nivel': 'otro'}), isNull);
    });

    test('dentro de la suscripción, y solo bloquea sin `acceso`', () {
      Map<String, dynamic> json({Object? acceso}) => {
        'id': 's1',
        'plan': {
          'id': 'prueba',
          'nombre': 'Prueba',
          'precioCentimos': 0,
          'duracionDias': 1,
          'esGratuito': true,
        },
        'estado': 'expirada',
        'origen': 'sistema',
        'inicia': '2026-10-01T10:00:00Z',
        'expira': '2026-10-02T10:00:00Z',
        'acceso': ?acceso,
      };

      final antes = Subscription.fromJson(json());
      expect(antes.acceso, isNull);
      expect(antes.bloqueada, isTrue);

      final ahora = Subscription.fromJson(
        json(
          acceso: {
            'nivel': 'gratis',
            'gratis': {'preguntasPorDia': 10, 'restantesHoy': 0},
          },
        ),
      );
      expect(ahora.bloqueada, isFalse);
      expect(ahora.gratis?.agotado, isTrue);
      // Ida y vuelta, como la guarda la caché.
      expect(
        Subscription.fromJson(
          jsonDecode(jsonEncode(ahora.toJson())) as Map<String, dynamic>,
        ),
        ahora,
      );
    });

    test('sin números, el cupo entero: el límite lo aplica el servidor', () {
      final g = AccesoGratis.fromJson(const {});
      expect(g.preguntasPorDia, 10);
      expect(g.restantesHoy, 10);
    });
  });

  group('Los 403 del gratis son el muro', () {
    test('LIMITE_DIARIO: cupo agotado', () {
      expect(
        motivoDelMuro(const ForbiddenFailure('x', 'LIMITE_DIARIO')),
        const CupoAgotado(),
      );
    });

    test('FUNCION_PREMIUM: la función que dice el servidor', () {
      expect(
        motivoDelMuro(
          const ForbiddenFailure('x', 'FUNCION_PREMIUM', {
            'funcion': 'examen_pasado',
          }),
        ),
        const FuncionDePago(FuncionPremium.examenPasado),
      );
      // Una que la app aún no conoce: el muro genérico, no un error.
      expect(
        motivoDelMuro(
          const ForbiddenFailure('x', 'FUNCION_PREMIUM', {'funcion': 'nueva'}),
        ),
        const FuncionDePago(FuncionPremium.otra),
      );
    });

    test('otros 403 no son el muro', () {
      expect(motivoDelMuro(const ForbiddenFailure('x', 'OTRO')), isNull);
      expect(motivoDelMuro(const NetworkFailure()), isNull);
    });

    test('la ruta del muro lleva el motivo y se lee de vuelta', () {
      for (final m in [
        const CupoAgotado(),
        for (final f in FuncionPremium.values) FuncionDePago(f),
      ]) {
        final uri = Uri.parse(rutaDelMuro(m));
        expect(uri.path, Routes.premium);
        expect(MotivoDeMuro.desdeConsulta(uri.queryParameters), m);
      }
    });
  });

  group('La siguiente acción en gratis', () {
    SiguienteAccion decidir({
      ({int restantes, int porDia})? gratis,
      bool sinRed = false,
      bool abierta = false,
    }) => decidirSiguienteAccion(
      sesionAbierta: abierta
          ? (sessionId: 's', esSimulacro: false, respondidas: 3, total: 10)
          : null,
      sinRed: sinRed,
      practicasOffline: 0,
      stats: null,
      prioridades: const [],
      gratis: gratis,
    );

    test('con cupo, la práctica del día; sin cupo, el aviso', () {
      expect(
        decidir(gratis: (restantes: 6, porDia: 10)),
        isA<PracticaDelDia>().having((p) => p.restantes, 'restantes', 6),
      );
      expect(
        decidir(gratis: (restantes: 0, porDia: 10)),
        isA<CupoDelDiaAgotado>(),
      );
    });

    test('retomar y sin conexión van antes', () {
      const g = (restantes: 0, porDia: 10);
      expect(decidir(gratis: g, abierta: true), isA<RetomarSesion>());
      expect(decidir(gratis: g, sinRed: true), isA<EstudiarSinConexion>());
    });
  });

  group('El muro', () {
    for (final ios in [false, true]) {
      final tienda = ios ? 'iPhone' : 'Android';

      testWidgets('$tienda: explica, ofrece y nunca menciona una oferta', (
        tester,
      ) async {
        if (ios) debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);

        await _montar(
          tester,
          const MuroDeVentaScreen(motivo: CupoAgotado()),
          gratis: const AccesoGratis(preguntasPorDia: 10, restantesHoy: 0),
        );

        expect(
          find.text('Se acabaron tus 10 preguntas de hoy'),
          findsOneWidget,
        );
        expect(find.textContaining('Tu cuenta gratis sigue'), findsOneWidget);
        // Solo web, por las normas de las tiendas.
        for (final palabra in ['%', 'descuento', 'oferta', 'Oferta']) {
          expect(find.textContaining(palabra), findsNothing, reason: palabra);
        }
        // Ninguna tienda lleva a pagar fuera: en iPhone, App Store; en
        // Android no se vende en la app.
        expect(find.text('Continuar en el navegador'), findsNothing);
        if (!ios) {
          await tester.scrollUntilVisible(
            find.text(
              'Tu acceso Premium se activa con tu cuenta de ENAM Prep.',
            ),
            300,
          );
        }
        debugDefaultTargetPlatformOverride = null;
      });
    }

    testWidgets('una función: qué es, antes del botón', (tester) async {
      await _montar(
        tester,
        const MuroDeVentaScreen(
          motivo: FuncionDePago(FuncionPremium.simulacro),
        ),
        gratis: const AccesoGratis(preguntasPorDia: 10, restantesHoy: 6),
      );
      expect(find.text(FuncionPremium.simulacro.titulo), findsOneWidget);
      expect(find.text(FuncionPremium.simulacro.vistaPrevia), findsOneWidget);
    });

    testWidgets('cerrarlo deja la app abierta', (tester) async {
      await _montar(
        tester,
        const _Abre(CupoAgotado()),
        gratis: const AccesoGratis(preguntasPorDia: 10, restantesHoy: 0),
      );
      await tester.tap(find.text('abrir'));
      await _asentar(tester);
      expect(find.byType(MuroDeVentaScreen), findsOneWidget);

      // En Android dice «Entendido»: no hay nada que comprar después.
      await tester.scrollUntilVisible(find.text('Entendido'), 300);
      await tester.ensureVisible(find.text('Entendido'));
      await _asentar(tester);
      await tester.tap(find.text('Entendido'));
      await _asentar(tester);
      expect(find.byType(MuroDeVentaScreen), findsNothing);
      expect(find.text('abrir'), findsOneWidget);
    });
  });

  group('Configurar práctica en gratis', () {
    testWidgets('todo el banco, `todas` y hasta el cupo; sin área', (
      tester,
    ) async {
      final repo = _Sesiones();
      await _montar(
        tester,
        const PracticeConfigScreen(nodoId: 'medicina'),
        gratis: const AccesoGratis(preguntasPorDia: 10, restantesHoy: 6),
        repo: repo,
      );

      // Llegó con un área: se dice por qué no va a ser de esa área.
      expect(
        find.textContaining('Elegir área o tema es Premium'),
        findsOneWidget,
      );
      expect(find.text('Todo el temario'), findsOneWidget);

      await tester.tap(find.text('Empezar · 6 preguntas'));
      await _asentar(tester);

      final pedido = repo.pedidos.single;
      expect(pedido.areaIds, isEmpty);
      expect(pedido.subtemaIds, isEmpty);
      expect(pedido.origen, QuestionSource.todas);
      expect(pedido.cantidadPreguntas, 6);
    });

    testWidgets('elegir área abre el muro', (tester) async {
      await _montar(
        tester,
        const PracticeConfigScreen(),
        gratis: const AccesoGratis(preguntasPorDia: 10, restantesHoy: 6),
      );
      await tester.tap(find.text('Todo el temario'));
      await _asentar(tester);
      expect(find.text(FuncionPremium.practicaAMedida.titulo), findsOneWidget);
    });

    testWidgets('sin cupo, el botón es Premium y no crea nada', (tester) async {
      final repo = _Sesiones();
      await _montar(
        tester,
        const PracticeConfigScreen(),
        gratis: const AccesoGratis(preguntasPorDia: 10, restantesHoy: 0),
        repo: repo,
      );
      await tester.tap(find.text('Ver Premium'));
      await _asentar(tester);
      expect(find.text('Se acabaron tus 10 preguntas de hoy'), findsOneWidget);
      expect(repo.pedidos, isEmpty);
    });

    testWidgets('el servidor dice LIMITE_DIARIO al crear: muro', (
      tester,
    ) async {
      await _montar(
        tester,
        const PracticeConfigScreen(),
        gratis: const AccesoGratis(preguntasPorDia: 10, restantesHoy: 3),
        repo: _Sesiones(alCrear: const ForbiddenFailure('x', 'LIMITE_DIARIO')),
      );
      await tester.tap(find.text('Empezar · 3 preguntas'));
      await _asentar(tester);
      expect(find.byType(MuroDeVentaScreen), findsOneWidget);
    });
  });

  testWidgets('responder sin cupo: el muro, y un aviso en vez de un error', (
    tester,
  ) async {
    final repo = _Sesiones(
      alResponder: const ForbiddenFailure('x', 'LIMITE_DIARIO'),
    );
    final sesion = await tester.runAsync(
      () => repo.startPractice(
        const PracticeConfig(areaIds: ['medicina'], cantidadPreguntas: 10),
      ),
    );
    await _montar(
      tester,
      QuestionScreen(sessionId: sesion!.id),
      gratis: const AccesoGratis(preguntasPorDia: 10, restantesHoy: 1),
      repo: repo,
    );

    // El enunciado es largo: las alternativas quedan más abajo.
    while (find.byType(OptionCard).evaluate().isEmpty) {
      await tester.drag(find.byType(ListView).first, const Offset(0, -300));
      await tester.pump();
    }
    await tester.ensureVisible(find.byType(OptionCard).first);
    await tester.pump();
    await tester.tap(find.byType(OptionCard).first);
    await tester.pump();
    await tester.tap(find.text('Responder'));
    await _asentar(tester);
    expect(find.byType(MuroDeVentaScreen), findsOneWidget);

    await tester.tap(find.byTooltip('Cerrar'));
    await _asentar(tester);
    expect(
      find.textContaining('Se acabaron tus preguntas gratis de hoy'),
      findsOneWidget,
    );
  });

  testWidgets('simulacros en gratis: etiqueta, y empezar abre el muro', (
    tester,
  ) async {
    await _montar(
      tester,
      const SimulacroHubScreen(),
      gratis: const AccesoGratis(preguntasPorDia: 10, restantesHoy: 6),
    );
    expect(find.text('Premium'), findsNWidgets(3));
    await tester.tap(find.text('Simulacro completo'));
    await _asentar(tester);
    expect(find.text(FuncionPremium.simulacro.titulo), findsOneWidget);
  });
}

/// Monta [pantalla] con un router de verdad (el muro se abre navegando) y, si
/// se da [gratis], en gratis limitado.
Future<void> _montar(
  WidgetTester tester,
  Widget pantalla, {
  AccesoGratis? gratis,
  SessionRepository? repo,
}) async {
  tester.view
    ..physicalSize = const Size(393, 852) * 3
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final sesiones = repo ?? _Sesiones();
  final overrides = <Override>[
    authControllerProvider.overrideWith(_ConSesion.new),
    cupoGratisProvider.overrideWithValue(gratis),
    subscriptionProvider.overrideWith(
      (ref) async => Subscription(
        id: 's1',
        plan: const Plan(
          id: 'prueba',
          nombre: 'Prueba',
          precioCentimos: 0,
          duracionDias: 1,
          esGratuito: true,
        ),
        estado: SubscriptionStatus.expirada,
        origen: SubscriptionOrigin.sistema,
        inicia: DateTime(2026, 10),
        acceso: gratis ?? const AccesoPremium(),
      ),
    ),
    sessionRepositoryProvider.overrideWithValue(sesiones),
    sessionRepositoryRemotoProvider.overrideWithValue(sesiones),
    sesionesAbiertasProvider.overrideWith((ref) async => const []),
    almacenOfflineProvider.overrideWithValue(AlmacenEnMemoria()),
    nacionalesProvider.overrideWith((ref) async => const []),
    dashboardProvider.overrideWith((ref) => Future.error(Exception('no'))),
  ];

  final router = GoRouter(
    initialLocation: '/pantalla',
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SizedBox()),
      GoRoute(path: '/pantalla', builder: (_, _) => pantalla),
      GoRoute(
        path: Routes.premium,
        builder: (_, s) => MuroDeVentaScreen(
          motivo: MotivoDeMuro.desdeConsulta(s.uri.queryParameters)!,
        ),
      ),
      GoRoute(
        path: '/practica/sesion/:id',
        builder: (_, s) => Text('sesion ${s.pathParameters['id']}'),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await _asentar(tester);
}

/// El repositorio de ejemplo simula la red con esperas: se dejan pasar.
Future<void> _asentar(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 400));
  }
}

class _Abre extends ConsumerWidget {
  const _Abre(this.motivo);

  final MotivoDeMuro motivo;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    body: TextButton(
      onPressed: () => abrirMuro(context, ref, motivo),
      child: const Text('abrir'),
    ),
  );
}

/// El repositorio de ejemplo, que anota lo pedido y puede contestar con un
/// 403 al crear o al responder.
class _Sesiones extends MockSessionRepository {
  _Sesiones({this.alCrear, this.alResponder});

  final Failure? alCrear;
  final Failure? alResponder;
  final pedidos = <PracticeConfig>[];

  @override
  Future<StudySession> startPractice(PracticeConfig config) async {
    pedidos.add(config);
    if (alCrear case final f?) throw f;
    return super.startPractice(config);
  }

  @override
  Future<Answer> answer({
    required String sessionId,
    required String questionId,
    String? optionId,
    required int tiempoMs,
    bool marcada = false,
  }) async {
    if (alResponder case final f?) throw f;
    return super.answer(
      sessionId: sessionId,
      questionId: questionId,
      optionId: optionId,
      tiempoMs: tiempoMs,
      marcada: marcada,
    );
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
