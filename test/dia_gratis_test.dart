import 'package:enam_app/core/error/failure.dart';
import 'package:enam_app/core/providers.dart';
import 'package:enam_app/core/router/routes.dart';
import 'package:enam_app/core/theme/app_theme.dart';
import 'package:enam_app/features/auth/domain/auth_models.dart';
import 'package:enam_app/features/session/data/session_repository.dart';
import 'package:enam_app/features/session/domain/session_models.dart';
import 'package:enam_app/features/session/presentation/simulacro_screen.dart';
import 'package:enam_app/features/session/presentation/widgets/option_card.dart';
import 'package:enam_app/features/subscription/domain/acceso.dart';
import 'package:enam_app/features/subscription/domain/subscription_models.dart';
import 'package:enam_app/features/subscription/presentation/muro_de_venta_screen.dart';
import 'package:enam_app/features/subscription/presentation/my_subscription_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

/// El día gratis de 24 h de las cuentas nuevas (Jerry, 11/10/2026): todo menos
/// los cursos completos.
///
/// El servidor lo manda como una suscripción en prueba con acceso premium. La
/// app lo llama «día gratis», nunca «prueba»; no le vende lo que ya tiene; y si
/// vence a mitad de un simulacro, lo dice en vez de dejar «Responder» mudo.
void main() {
  setUpAll(() => initializeDateFormatting('es'));

  final diaGratis = Subscription(
    id: 's1',
    plan: const Plan(
      id: 'trial',
      nombre: 'Prueba de 1 día',
      precioCentimos: 0,
      duracionDias: 1,
      esGratuito: true,
    ),
    estado: SubscriptionStatus.prueba,
    origen: SubscriptionOrigin.sistema,
    inicia: DateTime(2026, 10, 11, 15, 15),
    expira: DateTime(2026, 10, 12, 15, 15),
    acceso: const AccesoPremium(),
  );

  Subscription enGratis(AccesoGratis? gratis) => Subscription(
    id: 's1',
    plan: const Plan(
      id: 'trial',
      nombre: 'Prueba de 1 día',
      precioCentimos: 0,
      duracionDias: 1,
      esGratuito: true,
    ),
    estado: SubscriptionStatus.expirada,
    origen: SubscriptionOrigin.sistema,
    inicia: DateTime(2026, 10, 1),
    acceso: gratis,
  );

  /// Todo el texto en pantalla, en minúsculas.
  List<String> textos(WidgetTester tester) => tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => (t.data ?? t.textSpan?.toPlainText() ?? '').toLowerCase())
      .toList();

  Future<void> montar(
    WidgetTester tester,
    Widget pantalla,
    Subscription sub, {
    SessionRepository? repo,
    String inicio = '/pantalla',
  }) async {
    tester.view
      ..physicalSize = const Size(393, 1400) * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: inicio,
      routes: [
        GoRoute(path: '/', builder: (_, _) => const SizedBox()),
        GoRoute(path: '/pantalla', builder: (_, _) => pantalla),
        GoRoute(
          path: '/rindiendo/:id',
          builder: (_, s) =>
              SimulacroScreen(sessionId: s.pathParameters['id']!),
        ),
        GoRoute(
          path: Routes.premium,
          builder: (_, s) => MuroDeVentaScreen(
            motivo: MotivoDeMuro.desdeConsulta(s.uri.queryParameters)!,
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_ConSesion.new),
          subscriptionProvider.overrideWith((_) async => sub),
          if (repo != null) sessionRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    // `pump` a mano: el simulacro lleva un cronómetro y nunca se asienta.
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  group('Mi suscripción en el día gratis', () {
    testWidgets('«Día gratis», con su hora de fin y sin «Si cancelas»', (
      tester,
    ) async {
      await montar(tester, const MySubscriptionScreen(), diaGratis);

      expect(find.text('Día gratis'), findsOneWidget);
      expect(find.text('DÍA GRATIS'), findsOneWidget);
      // Son 24 h: sin la hora no se sabe cuándo termina.
      expect(find.text('12 oct 2026, 3:15 p.m.'), findsOneWidget);
      expect(find.textContaining('Tu día gratis incluye'), findsOneWidget);
      expect(find.textContaining('Si cancelas'), findsNothing);
      expect(textos(tester).where((t) => t.contains('prueba')), isEmpty);
    });

    testWidgets('sin empezar: tampoco dice «prueba»', (tester) async {
      await montar(
        tester,
        const MySubscriptionScreen(),
        diaGratis.copyWith(
          estado: SubscriptionStatus.pruebaSinIniciar,
          expira: null,
        ),
      );

      expect(find.text('DÍA GRATIS'), findsOneWidget);
      expect(find.text('Empieza con tu primera práctica'), findsOneWidget);
      expect(textos(tester).where((t) => t.contains('prueba')), isEmpty);
    });
  });

  group('El muro', () {
    testWidgets('en el día gratis dice lo que ya tiene, no la cuenta gratis', (
      tester,
    ) async {
      await montar(
        tester,
        const MuroDeVentaScreen(motivo: FuncionDePago(FuncionPremium.cursos)),
        diaGratis,
      );

      expect(
        find.text(
          'Tu día gratis incluye práctica sin límite, simulacros y '
          'estadísticas; los cursos completos son de Premium.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Tu cuenta gratis sigue'), findsNothing);
      expect(textos(tester).where((t) => t.contains('prueba')), isEmpty);
    });

    testWidgets('en gratis, el cupo es el que manda el servidor', (
      tester,
    ) async {
      await montar(
        tester,
        const MuroDeVentaScreen(motivo: CupoAgotado()),
        enGratis(const AccesoGratis(preguntasPorDia: 20, restantesHoy: 0)),
      );

      expect(find.text('Se acabaron tus 20 preguntas de hoy'), findsOneWidget);
      expect(
        find.textContaining('Tu cuenta gratis sigue: 20 preguntas al día'),
        findsOneWidget,
      );
    });

    testWidgets('si el servidor no manda el cupo, no se inventa uno', (
      tester,
    ) async {
      await montar(
        tester,
        const MuroDeVentaScreen(motivo: CupoAgotado()),
        enGratis(null),
      );

      expect(find.text('Se acabaron tus preguntas de hoy'), findsOneWidget);
      expect(
        find.textContaining('Tu cuenta gratis sigue: preguntas cada día'),
        findsOneWidget,
      );
      // Ningún número del cupo en pantalla.
      expect(
        textos(tester).where((t) => RegExp(r'\d+ preguntas').hasMatch(t)),
        isEmpty,
      );
    });
  });

  group('Vence a mitad de un simulacro', () {
    late _Vencido repo;
    late StudySession simulacro;

    // Fuera de `testWidgets`: el mock espera con `Future.delayed`, y con el
    // reloj falso de la prueba esa espera no termina nunca.
    setUp(() async {
      repo = _Vencido();
      simulacro = await repo.startSimulacro();
    });

    testWidgets('responder abre el muro y deja un aviso para enviar', (
      tester,
    ) async {
      await montar(
        tester,
        const SizedBox(),
        diaGratis,
        repo: repo,
        inicio: '/rindiendo/${simulacro.id}',
      );

      await tester.ensureVisible(find.byType(OptionCard).first);
      await tester.pump();
      await tester.tap(find.byType(OptionCard).first);
      await tester.pump();
      await tester.tap(find.text('Responder y seguir'));
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(find.byType(MuroDeVentaScreen), findsOneWidget);

      await tester.tap(find.byTooltip('Cerrar'));
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
      expect(find.byType(SimulacroScreen), findsOneWidget);
      expect(
        find.text(
          'Tu acceso a los simulacros terminó. Envía el examen para ver tu '
          'nota con lo que respondiste.',
        ),
        findsOneWidget,
      );
      // Una vez: cerrar el muro no lo vuelve a abrir.
      expect(find.byType(MuroDeVentaScreen), findsNothing);
    });
  });
}

/// El servidor tras vencer el día gratis: cada respuesta del simulacro, 403.
class _Vencido extends MockSessionRepository {
  @override
  Future<Answer> answer({
    required String sessionId,
    required String questionId,
    String? optionId,
    required int tiempoMs,
    bool marcada = false,
  }) async => throw const ForbiddenFailure('x', 'FUNCION_PREMIUM', {
    'funcion': 'simulacro',
  });
}

class _ConSesion extends AuthController {
  @override
  Future<AuthState> build() async => AuthSignedIn(
    User(
      id: 'u1',
      email: 'a@b.pe',
      nombre: 'Ana',
      emailVerificado: true,
      condicion: StudentCondition.interno,
      fechaObjetivo: DateTime(2026, 12, 12),
    ),
  );
}
