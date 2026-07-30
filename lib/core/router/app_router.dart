import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/complete_profile_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/reset_password_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/verify_email_screen.dart';
import '../../features/catalog/presentation/study_priority_screen.dart';
import '../../features/catalog/presentation/temario_map_screen.dart';
import '../../features/catalog/presentation/temario_node_screen.dart';
import '../../features/catalog/presentation/temario_search_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/offline/presentation/downloads_screen.dart';
import '../../features/profile/presentation/settings_screen.dart';
import '../../features/session/presentation/marked_questions_screen.dart';
import '../../features/session/presentation/national_mock_screen.dart';
import '../../features/session/presentation/practice_config_screen.dart';
import '../../features/session/presentation/question_screen.dart';
import '../../features/session/presentation/review_screen.dart';
import '../../features/session/presentation/session_summary_screen.dart';
import '../../features/session/presentation/simulacro_hub_screen.dart';
import '../../features/session/presentation/simulacro_instructions_screen.dart';
import '../../features/session/presentation/simulacro_results_screen.dart';
import '../../features/session/presentation/simulacro_screen.dart';
import '../../features/stats/presentation/progress_screen.dart';
import '../../features/stats/presentation/ranking_screen.dart';
import '../../features/subscription/presentation/checkout_screen.dart';
import '../../features/subscription/presentation/my_subscription_screen.dart';
import '../../features/subscription/presentation/payment_result_screen.dart';
import '../../features/subscription/presentation/plans_screen.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/placeholder_screen.dart';
import '../providers.dart';
import 'routes.dart';
import 'transitions.dart';

/// Router de la app.
///
/// Sustituye al patrón de la app hermana (un `StatefulWidget` con un `String
/// _currentStep` y `setState`), que no daba deep links, ni botón atrás correcto,
/// ni rutas nombradas.
///
/// Estructura:
/// - Rutas de acceso (splash, onboarding, auth) van sueltas, sin barra inferior.
/// - Las cuatro secciones principales viven en un [StatefulShellRoute] para que
///   cada pestaña conserve su propia pila de navegación.
///
/// Las guardas viven en [_redirect], en un solo lugar: ninguna pantalla decide
/// por su cuenta si el usuario puede estar ahí.
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ValueNotifier(0);

  ref.listen(authControllerProvider, (_, _) => notifier.value++);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: notifier,
    debugLogDiagnostics: true,
    redirect: (context, state) => _redirect(ref, state),
    routes: _routes,
    errorBuilder: (context, state) => PlaceholderScreen(
      titulo: 'Ruta no encontrada',
      descripcion: 'No existe una pantalla para "${state.uri}".',
      acciones: const [(label: 'Ir al inicio', ruta: Routes.home)],
    ),
  );
});

/// Rutas accesibles sin sesión iniciada.
const _publicRoutes = {
  Routes.splash,
  Routes.onboarding,
  Routes.login,
  Routes.register,
  Routes.forgotPassword,
  Routes.resetPassword,
  Routes.terms,
  Routes.maintenance,
  Routes.updateRequired,
};

/// Pantallas de acceso que dejan de tener sentido con la sesión ya lista.
const _entryRoutes = {
  Routes.splash,
  Routes.login,
  Routes.register,
  Routes.onboarding,
  Routes.verifyEmail,
  Routes.completeProfile,
};

/// Decide a dónde mandar al usuario. `null` lo deja pasar.
String? _redirect(Ref ref, GoRouterState state) {
  final auth = ref.read(authControllerProvider);
  final here = state.matchedLocation;

  // Aún leyendo el storage: quedarse en splash y no parpadear al login.
  if (auth.isLoading || !auth.hasValue) {
    return here == Routes.splash ? null : Routes.splash;
  }

  return switch (auth.requireValue) {
    AuthLoading() => Routes.splash,

    AuthSignedOut() =>
      _publicRoutes.contains(here) && here != Routes.splash ? null : Routes.login,

    AuthSignedIn(:final user) => switch (user) {
      // RF-01: sin correo verificado no se entra a la app.
      _ when !user.emailVerificado && here != Routes.verifyEmail =>
        Routes.verifyEmail,

      // RF-04: el perfil debe completarse antes de usar la app; la fecha
      // objetivo alimenta la cuenta regresiva y las estadísticas.
      _
          when user.emailVerificado &&
              !user.perfilCompleto &&
              here != Routes.completeProfile =>
        Routes.completeProfile,

      _ when user.perfilCompleto && _entryRoutes.contains(here) => Routes.home,

      _ => null,
    },
  };
}

/// Atajo para declarar una pantalla de andamiaje pendiente de diseño.
GoRoute _stub(
  String path, {
  required String titulo,
  required String descripcion,
  List<String> requisitos = const [],
  List<({String label, String ruta})> acciones = const [],
}) {
  return GoRoute(
    path: path,
    builder: (context, state) => PlaceholderScreen(
      titulo: titulo,
      descripcion: descripcion,
      requisitos: requisitos,
      acciones: acciones,
    ),
  );
}

final _shellNavigatorKey = GlobalKey<NavigatorState>();

final List<RouteBase> _routes = [
  // ==================== ACCESO (sin barra inferior) ====================
  GoRoute(
    path: Routes.splash,
    builder: (context, state) => const SplashScreen(),
  ),
  GoRoute(
    path: Routes.onboarding,
    builder: (context, state) => const OnboardingScreen(),
  ),
  GoRoute(path: Routes.login, builder: (context, state) => const LoginScreen()),
  GoRoute(
    path: Routes.register,
    builder: (context, state) => const RegisterScreen(),
  ),
  GoRoute(
    path: Routes.verifyEmail,
    // El correo llega por `extra` desde el registro; si se entra directo, la
    // pantalla lo lee del usuario en sesión.
    builder: (context, state) => VerifyEmailScreen(email: state.extra as String?),
  ),
  GoRoute(
    path: Routes.forgotPassword,
    builder: (context, state) => const ForgotPasswordScreen(),
  ),
  GoRoute(
    path: Routes.resetPassword,
    // El token viaja en la URL del enlace del correo: /nueva-contrasena?token=…
    builder: (context, state) =>
        ResetPasswordScreen(token: state.uri.queryParameters['token']),
  ),
  GoRoute(
    path: Routes.completeProfile,
    builder: (context, state) => const CompleteProfileScreen(),
  ),

  // ==================== SECCIONES PRINCIPALES ====================
  StatefulShellRoute.indexedStack(
    builder: (context, state, navigationShell) =>
        AppShell(navigationShell: navigationShell),
    branches: [
      // --- Inicio ---
      StatefulShellBranch(
        navigatorKey: _shellNavigatorKey,
        routes: [
          GoRoute(
            path: Routes.home,
            builder: (context, state) => const HomeScreen(),
          ),
        ],
      ),

      // --- Temario (RF-36 a RF-41) ---
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: Routes.temario,
            pageBuilder: (context, state) =>
                instantPage(child: const TemarioMapScreen(), state: state),
            routes: [
              // Anidada bajo /temario para que el botón atrás vuelva al mapa.
              GoRoute(
                path: 'buscar',
                pageBuilder: (context, state) =>
                    modalPage(child: const TemarioSearchScreen(), state: state),
              ),
              GoRoute(
                path: ':id',
                pageBuilder: (context, state) => slidePage(
                  child: TemarioNodeScreen(
                    nodeId: state.pathParameters['id']!,
                  ),
                  state: state,
                ),
              ),
            ],
          ),
        ],
      ),

      // --- Simulacros (RF-16 a RF-20) ---
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: Routes.simulacroSelection,
            pageBuilder: (context, state) =>
                instantPage(child: const SimulacroHubScreen(), state: state),
            routes: [
              GoRoute(
                path: 'instrucciones',
                pageBuilder: (context, state) => slidePage(
                  child: SimulacroInstructionsScreen(
                    esMuestra: state.uri.queryParameters['muestra'] == '1',
                  ),
                  state: state,
                ),
              ),
              GoRoute(
                path: 'nacional',
                pageBuilder: (context, state) =>
                    slidePage(child: const NationalMockScreen(), state: state),
              ),
              GoRoute(
                path: 'sesion/:id',
                // Desvanece: entrar al examen no es profundizar en una jerarquía.
                pageBuilder: (context, state) => fadePage(
                  child: SimulacroScreen(sessionId: state.pathParameters['id']!),
                  state: state,
                ),
              ),
              GoRoute(
                path: 'resultados/:id',
                pageBuilder: (context, state) => fadePage(
                  child: SimulacroResultsScreen(
                    sessionId: state.pathParameters['id']!,
                  ),
                  state: state,
                ),
              ),
              GoRoute(
                path: 'revision/:id',
                pageBuilder: (context, state) => slidePage(
                  child: ReviewScreen(sessionId: state.pathParameters['id']!),
                  state: state,
                ),
              ),
            ],
          ),
        ],
      ),

      // --- Progreso (RF-21, RF-22) ---
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: Routes.stats,
            pageBuilder: (context, state) =>
                instantPage(child: const ProgressScreen(), state: state),
            routes: [
              GoRoute(
                path: 'prioridades',
                pageBuilder: (context, state) =>
                    slidePage(child: const StudyPriorityScreen(), state: state),
              ),
            ],
          ),
          GoRoute(
            path: Routes.ranking,
            pageBuilder: (context, state) =>
                slidePage(child: const RankingScreen(), state: state),
          ),
        ],
      ),
    ],
  ),

  // ==================== PRÁCTICA (encima de la barra) ====================
  GoRoute(
    path: Routes.practiceConfig,
    pageBuilder: (context, state) => slidePage(
      child: PracticeConfigScreen(
        // Llega desde el temario con el nodo puesto (RF-38).
        nodoId: state.uri.queryParameters['nodo'],
        origenInicial: state.uri.queryParameters['origen'],
      ),
      state: state,
    ),
  ),
  GoRoute(
    path: Routes.practiceSession,
    // Desvanece: entrar a responder no es profundizar en una jerarquía.
    pageBuilder: (context, state) => fadePage(
      child: QuestionScreen(sessionId: state.pathParameters['id']!),
      state: state,
    ),
  ),
  GoRoute(
    path: Routes.practiceResults,
    pageBuilder: (context, state) => fadePage(
      child: SessionSummaryScreen(sessionId: state.pathParameters['id']!),
      state: state,
    ),
  ),
  GoRoute(
    path: Routes.markedQuestions,
    pageBuilder: (context, state) =>
        slidePage(child: const MarkedQuestionsScreen(), state: state),
  ),

  // ==================== SUSCRIPCIÓN (Módulo 6) ====================
  GoRoute(
    path: Routes.plans,
    // Sube desde abajo: interrumpe lo que el usuario estaba haciendo.
    pageBuilder: (context, state) =>
        modalPage(child: const PlansScreen(), state: state),
  ),
  GoRoute(
    path: Routes.checkout,
    pageBuilder: (context, state) => slidePage(
      child: CheckoutScreen(planId: state.uri.queryParameters['plan']),
      state: state,
    ),
  ),
  GoRoute(
    path: Routes.paymentResult,
    pageBuilder: (context, state) => fadePage(
      child: PaymentResultScreen(
        estado: EstadoPago.values.firstWhere(
          (e) => e.name == state.uri.queryParameters['estado'],
          orElse: () => EstadoPago.exito,
        ),
        planId: state.uri.queryParameters['plan'],
      ),
      state: state,
    ),
  ),
  GoRoute(
    path: Routes.mySubscription,
    pageBuilder: (context, state) =>
        slidePage(child: const MySubscriptionScreen(), state: state),
  ),

  // ==================== OFFLINE (Módulo 7) ====================
  GoRoute(
    path: Routes.downloads,
    pageBuilder: (context, state) =>
        slidePage(child: const DownloadsScreen(), state: state),
  ),
  _stub(
    Routes.offline,
    titulo: 'Sin conexión',
    descripcion:
        'Qué sigue funcionando y qué no. Los simulacros nacionales requieren '
        'conexión.',
    requisitos: const ['RF-31', 'RF-33'],
  ),

  // ==================== PERFIL Y AJUSTES ====================
  GoRoute(
    path: Routes.settings,
    pageBuilder: (context, state) =>
        slidePage(child: const SettingsScreen(), state: state),
  ),
  _stub(
    Routes.editProfile,
    titulo: 'Editar perfil',
    descripcion: 'Incluye cambiar la fecha objetivo de examen.',
    requisitos: const ['RF-04'],
  ),
  _stub(
    Routes.changePassword,
    titulo: 'Cambiar contraseña',
    descripcion: 'Contraseña actual y nueva.',
  ),

  // ==================== SISTEMA ====================
  _stub(
    Routes.maintenance,
    titulo: 'Mantenimiento',
    descripcion: 'El servicio está temporalmente fuera de servicio.',
    requisitos: const ['RNF-03'],
  ),
  _stub(
    Routes.updateRequired,
    titulo: 'Actualización requerida',
    descripcion: 'Esta versión ya no es compatible con el servidor.',
  ),
];
