import 'package:enam_app/core/mock/mock_data.dart';
import 'package:enam_app/core/providers.dart';
import 'package:enam_app/features/catalog/data/catalog_repository.dart';
import 'package:enam_app/features/catalog/domain/catalog_models.dart';
import 'package:enam_app/features/session/data/session_repository.dart';
import 'package:enam_app/features/session/domain/session_models.dart';
import 'package:enam_app/features/stats/data/stats_repository.dart';
import 'package:enam_app/features/stats/domain/stats_models.dart';
import 'package:enam_app/core/theme/app_theme.dart';
import 'package:enam_app/features/auth/domain/auth_models.dart';
import 'package:enam_app/features/auth/presentation/complete_profile_screen.dart';
import 'package:enam_app/features/auth/presentation/forgot_password_screen.dart';
import 'package:enam_app/features/auth/presentation/login_screen.dart';
import 'package:enam_app/features/auth/presentation/onboarding_screen.dart';
import 'package:enam_app/features/auth/presentation/register_screen.dart';
import 'package:enam_app/features/auth/presentation/reset_password_screen.dart';
import 'package:enam_app/features/auth/presentation/splash_screen.dart';
import 'package:enam_app/features/auth/presentation/verify_email_screen.dart';
import 'package:enam_app/features/catalog/presentation/study_priority_screen.dart';
import 'package:enam_app/features/catalog/presentation/temario_map_screen.dart';
import 'package:enam_app/features/catalog/presentation/temario_node_screen.dart';
import 'package:enam_app/features/catalog/presentation/temario_search_screen.dart';
import 'package:enam_app/features/home/presentation/home_screen.dart';
import 'package:enam_app/features/session/presentation/marked_questions_screen.dart';
import 'package:enam_app/features/session/presentation/national_mock_screen.dart';
import 'package:enam_app/features/session/presentation/practice_config_screen.dart';
import 'package:enam_app/features/session/presentation/simulacro_hub_screen.dart';
import 'package:enam_app/features/offline/domain/offline_models.dart';
import 'package:enam_app/features/offline/presentation/downloads_screen.dart';
import 'package:enam_app/features/profile/presentation/change_password_screen.dart';
import 'package:enam_app/features/profile/presentation/delete_account_screen.dart';
import 'package:enam_app/features/profile/presentation/edit_profile_screen.dart';
import 'package:enam_app/features/profile/presentation/help_screen.dart';
import 'package:enam_app/features/profile/presentation/legal_screen.dart';
import 'package:enam_app/features/profile/presentation/settings_screen.dart';
import 'package:enam_app/features/session/presentation/simulacro_instructions_screen.dart';
import 'package:enam_app/features/stats/presentation/progress_screen.dart';
import 'package:enam_app/features/stats/presentation/ranking_screen.dart';
import 'package:enam_app/features/subscription/data/subscription_repository.dart';
import 'package:enam_app/features/subscription/domain/subscription_models.dart';
import 'package:enam_app/features/subscription/presentation/access_ended_screen.dart';
import 'package:enam_app/features/subscription/presentation/my_subscription_screen.dart';
import 'package:enam_app/features/system/presentation/system_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'ayuda/offline.dart';

/// Verifica que ninguna pantalla desborde a **360 px de ancho** (RNF-09) ni en
/// tema claro ni en oscuro, y que aguante la fuente del sistema ampliada.
///
/// El diseño se entregó dibujado a 390 px y sin comprobar 360. Esto lo comprueba
/// de forma automática, así que deja de depender de que alguien se acuerde.
void main() {
  // Igual que en `main()`: sin esto, DateFormat con locale 'es' revienta.
  setUpAll(() async {
    await initializeDateFormatting('es');

    // La pantalla de descargas se mide **con contenido**: un área guardada y
    // una práctica lista. Vacía no prueba nada, y es justo con los textos
    // largos —«40 preguntas · 47 KB · al día»— donde puede desbordar.
    await _almacen.guardarPaquete(
      'u1',
      PaqueteOffline(
        areaId: 'medicina',
        generadoEn: DateTime(2026, 7, 20),
        preguntas: [preguntaDePrueba('q1')],
        total: 40,
      ),
    );
    await _almacen.guardarSesion(
      'u1',
      areaId: 'medicina',
      estado: EstadoSesionLocal.reservada,
      sesion: sesionDePrueba(),
    );
  });

  /// El teléfono más angosto que soportamos, y uno bajo para forzar desborde
  /// vertical si una pantalla no es desplazable.
  const anchoMinimo = 360.0;
  const altoBajo = 640.0;

  final pantallas = <String, Widget>{
    // Temario. Los casos difíciles del árbol irregular:
    'Temario · mapa': const TemarioMapScreen(),
    // Medicina: 11 sub áreas, la lista más larga de segundo nivel
    'Temario · Medicina': const TemarioNodeScreen(nodeId: 'medicina'),
    // Gineco: la única con capa de bloques
    'Temario · Gineco': const TemarioNodeScreen(nodeId: 'gineco-obstetricia'),
    // Emergencias: sin tercer nivel, nombres de sub área largos
    'Temario · Emergencias': const TemarioNodeScreen(nodeId: 'emergencias'),
    // Gestión: contiene el nombre de sub área más largo del temario (75 car.)
    'Temario · Gestión': const TemarioNodeScreen(nodeId: 'gestion'),
    // Una sub área con su lista de temas, con nombres de hasta 107 caracteres
    'Temario · temas': const TemarioNodeScreen(nodeId: 'medicina-infecciosos'),
    'Temario · búsqueda': const TemarioSearchScreen(),
    'Prioridades de estudio': const StudyPriorityScreen(),

    'Splash': const SplashScreen(),
    'Onboarding': const OnboardingScreen(),
    'Login': const LoginScreen(),
    'Registro': const RegisterScreen(),
    'Verificar correo': const VerifyEmailScreen(email: 'valeria@unmsm.edu.pe'),
    'Recuperar contraseña': const ForgotPasswordScreen(),
    'Nueva contraseña': const ResetPasswordScreen(email: 'valeria@unmsm.edu.pe'),
    'Perfil inicial': const CompleteProfileScreen(),
    'Inicio': const HomeScreen(),

    // Práctica
    'Práctica · configurador': const PracticeConfigScreen(),
    // Con nodo puesto desde el temario (RF-38), y con el nombre más largo
    'Práctica · configurador con nodo': const PracticeConfigScreen(
      nodoId: 'gestion-establecimientos',
    ),
    'Práctica · marcadas': const MarkedQuestionsScreen(),

    // Simulacros
    'Simulacro · hub': const SimulacroHubScreen(),
    'Simulacro · instrucciones': const SimulacroInstructionsScreen(),
    'Simulacro · muestra': const SimulacroInstructionsScreen(esMuestra: true),
    'Simulacro · nacional': const NationalMockScreen(),

    // Progreso, pagos, offline y ajustes
    'Progreso': const ProgressScreen(),
    'Ranking': const RankingScreen(),
    // Ya no hay pantallas de planes, checkout ni resultado de pago: la app no
    // cobra ni enseña precios (modelo Netflix, ver opciones_de_pago.dart).
    'Mi suscripción': const MySubscriptionScreen(),
    // El bloqueo por prueba vencida (D-01): titular largo, aviso de RN-07 y
    // dos botones apilados, que es lo que aprieta a 360 px.
    'Acceso terminado': const AccessEndedScreen(),
    'Descargas': const DownloadsScreen(),
    'Ajustes': const SettingsScreen(),

    // Pantallas que no venían en el diseño
    'Términos y privacidad': const LegalScreen(),
    'Eliminar cuenta': const DeleteAccountScreen(),
    'Ayuda': const HelpScreen(),
    'Mantenimiento': const MaintenanceScreen(hasta: 'el lunes a las 8 a.m.'),
    'Actualización requerida': const UpdateRequiredScreen(),
    'Sin conexión': const OfflineScreen(),
    'Editar perfil': const EditProfileScreen(),
    'Cambiar contraseña': const ChangePasswordScreen(),
  };

  for (final entry in pantallas.entries) {
    for (final brightness in Brightness.values) {
      final tema = brightness == Brightness.light ? 'claro' : 'oscuro';

      testWidgets('${entry.key} entra en 360 px · tema $tema', (tester) async {
        tester.view
          ..physicalSize = const Size(anchoMinimo * 3, altoBajo * 3)
          ..devicePixelRatio = 3.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(_harness(entry.value, brightness));
        await tester.pump(const Duration(seconds: 1));

        expect(
          tester.takeException(),
          isNull,
          reason: '"${entry.key}" desborda o falla a $anchoMinimo px en $tema',
        );
      });
    }
  }

  testWidgets('las pantallas de formulario aguantan la fuente al 140 %', (
    tester,
  ) async {
    // 1.4 es el tope que fija la app en `EnamApp.builder`.
    tester.view
      ..physicalSize = const Size(anchoMinimo * 3, altoBajo * 3)
      ..devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    for (final pantalla in [
      const RegisterScreen(),
      const CompleteProfileScreen(),
      const ResetPasswordScreen(email: 'valeria@unmsm.edu.pe'),
    ]) {
      await tester.pumpWidget(
        _harness(pantalla, Brightness.light, textScale: 1.4),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    }
  });
}

/// La base local de estas pruebas, con un área ya descargada.
final _almacen = AlmacenEnMemoria();

/// Envuelve la pantalla con lo mínimo para pintarla, con datos ya resueltos.
///
/// Los repositorios se sustituyen por versiones **instantáneas**: los mocks de
/// producción simulan latencia con `Future.delayed`, y dentro de `testWidgets` el
/// tiempo es simulado, así que dejarían temporizadores pendientes al terminar.
/// Este test mide layout, no latencia.
Widget _harness(Widget screen, Brightness brightness, {double textScale = 1.0}) {
  return ProviderScope(
    overrides: [
      // Un usuario con perfil completo, para que el Home tenga qué mostrar.
      authControllerProvider.overrideWith(_FakeAuthController.new),
      catalogRepositoryProvider.overrideWithValue(_InstantCatalog()),
      statsRepositoryProvider.overrideWithValue(_InstantStats()),
      subscriptionRepositoryProvider.overrideWithValue(_InstantSubscription()),
      // Sin esto, la tarjeta del nacional del inicio deja un temporizador del
      // mock pendiente y el test de layout falla por algo que no es el layout.
      sessionRepositoryProvider.overrideWithValue(_InstantSessions()),
      // Sin esto la base local intentaría abrir SQLite, que en las pruebas no
      // existe, y la pantalla de descargas se mediría en su estado de error.
      almacenOfflineProvider.overrideWithValue(_almacen),
    ],
    child: MaterialApp(
      theme: brightness == Brightness.light ? AppTheme.light : AppTheme.dark,
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: screen,
      ),
    ),
  );
}

class _FakeAuthController extends AuthController {
  @override
  Future<AuthState> build() async => AuthSignedIn(
    User(
      id: 'u1',
      email: 'valeria.rojas@unmsm.edu.pe',
      nombre: 'Valeria Rojas',
      emailVerificado: true,
      universidad: 'UNMSM',
      condicion: StudentCondition.repitiente,
      // Fecha fija para que el test no dependa del día en que corre.
      fechaObjetivo: DateTime(2026, 12, 12),
    ),
  );
}


/// Suscripción que responde sin latencia.
///
/// En prueba sin empezar, que es como nace todo usuario (RN-03 v2) y el caso
/// con `expira` nulo — el que rompe cualquier formato de fecha descuidado.
class _InstantSubscription implements SubscriptionRepository {
  static const _plan = Plan(
    id: 'mensual',
    nombre: 'Premium mensual',
    precioCentimos: 4900,
    duracionDias: 30,
    beneficios: ['Banco completo y práctica ilimitada'],
  );

  @override
  Future<Subscription> current() => Future.value(
    Subscription(
      id: 's1',
      plan: _plan,
      estado: SubscriptionStatus.pruebaSinIniciar,
      origen: SubscriptionOrigin.sistema,
      inicia: DateTime(2026, 7, 30),
    ),
  );

  @override
  Future<void> enviarEnlaceDeSuscripcion(String email) async {}

  @override
  Future<void> cancelar() async {}
}

/// Sesiones que responden sin latencia.
///
/// Solo lo que la pantalla de inicio consulta: el nacional y las sesiones a
/// medias. El resto no se toca al pintar, y una excepción es mejor aviso que
/// un dato inventado si algún día se toca.
class _InstantSessions implements SessionRepository {
  @override
  Future<List<NationalMock>> nationalMocks() async => [
    NationalMock(
      id: 'nac-1',
      nombre: 'Simulacro Nacional · Agosto',
      inicio: DateTime(2026, 8, 15, 8),
      fin: DateTime(2026, 8, 15, 11),
      duracionMinutos: 180,
      participantes: 1847,
      totalPreguntas: 180,
    ),
  ];

  @override
  Future<List<OpenSession>> openSessions() async => const [];

  @override
  Future<List<Question>> markedQuestions() async => const [];

  @override
  Future<StudySession> joinNationalMock(String mockId) =>
      throw UnimplementedError();

  @override
  Future<StudySession> startPractice(PracticeConfig config) =>
      throw UnimplementedError();

  @override
  Future<StudySession> startSimulacro({bool esMuestra = false}) =>
      throw UnimplementedError();

  @override
  Future<StudySession> session(String id) => throw UnimplementedError();

  @override
  Future<Answer> answer({
    required String sessionId,
    required String questionId,
    String? optionId,
    required int tiempoMs,
    bool marcada = false,
  }) => throw UnimplementedError();

  @override
  Future<StudySession> submit(String sessionId) => throw UnimplementedError();

  @override
  Future<List<PastExam>> pastExams() async => const [];

  @override
  Future<StudySession> startPastExam(
    String examId, {
    required PastExamMode modo,
    int? cantidad,
  }) async => throw UnimplementedError();
}

/// Catálogo que responde sin latencia.
class _InstantCatalog implements CatalogRepository {
  static final _arbol = MockData.catalog();

  @override
  Future<List<CatalogNode>> tree() => Future.value(_arbol);
}

/// Estadísticas que responden sin latencia.
class _InstantStats implements StatsRepository {
  static final _dashboard = _construir();

  static DashboardStats _construir() {
    // Suficientes respuestas para que la nota proyectada se muestre, y no el
    // estado de "aún no hay datos".
    final porArea = [
      for (final area in MockData.catalog())
        AreaPerformance(
          areaId: area.id,
          areaNombre: area.nombre,
          preguntasBlueprint: area.peso ?? 0,
          respondidas: 40,
          correctas: 25,
        ),
    ];
    return DashboardStats(
      notaProyectada: 12.4,
      preguntasVistas: 1286,
      preguntasTotalesBanco: 4500,
      simulacrosCompletados: 3,
      porArea: porArea,
      evolucion: [
        for (var i = 4; i >= 0; i--)
          GradePoint(
            fecha: DateTime(2026, 7, 30 - i * 3),
            nota: 9.5 + (4 - i) * 0.7,
          ),
      ],
    );
  }

  @override
  Future<DashboardStats> dashboard() => Future.value(_dashboard);

  @override
  Future<List<RankingEntry>> rankingGeneral() => Future.value([
    for (var i = 1; i <= 10; i++)
      RankingEntry(
        posicion: i,
        usuarioNombre: 'Estudiante $i',
        universidad: 'UNMSM',
        promedio: 16.5 - i * 0.3,
        esUsuarioActual: i == 7,
      ),
  ]);
}
