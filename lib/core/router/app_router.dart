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
import '../../features/home/presentation/home_screen.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/placeholder_screen.dart';
import '../providers.dart';
import 'routes.dart';

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

      // --- Temario (RF-06) ---
      StatefulShellBranch(
        routes: [
          _stub(
            Routes.temario,
            titulo: 'Temario',
            descripcion:
                'Las 10 áreas agrupadas en Clínico Médicas, Clínico '
                'Quirúrgicas y Transversales, con el peso de cada una visible.',
            requisitos: const ['RF-06'],
            acciones: const [
              (label: 'Buscar en el temario', ruta: Routes.temarioSearch),
              (label: 'Medicina (11 sub áreas)', ruta: '/temario/medicina'),
            ],
          ),
          _stub(
            Routes.temarioSearch,
            titulo: 'Buscar en el temario',
            descripcion:
                'Cruza los tres niveles. Debe resolver que "glaucoma" vive '
                'dentro de Cirugía, mostrando la ruta completa.',
            requisitos: const ['RF-06'],
          ),
          _stub(
            Routes.temarioArea,
            titulo: 'Sub áreas del área',
            descripcion:
                'Funciona con 11 sub áreas (Medicina) y con 2 (Ciencias '
                'Básicas), y soporta el nivel de bloques de Gineco-Obstetricia.',
            requisitos: const ['RF-06'],
            acciones: const [
              (label: 'Ver temas', ruta: '/temario/medicina-infecciosos/temas'),
            ],
          ),
          _stub(
            Routes.temarioSubArea,
            titulo: 'Temas',
            descripcion:
                'Hasta 123 temas en una lista, con nombres de hasta 107 '
                'caracteres. Con estado propio para las áreas sin tercer nivel.',
            requisitos: const ['RF-06'],
          ),
        ],
      ),

      // --- Simulacros ---
      StatefulShellBranch(
        routes: [
          _stub(
            Routes.simulacroSelection,
            titulo: 'Simulacros',
            descripcion: 'Individual autogenerado o nacional programado.',
            requisitos: const ['RF-16', 'RF-19'],
            acciones: const [
              (label: 'Instrucciones', ruta: Routes.simulacroInstructions),
              (label: 'Historial', ruta: Routes.simulacroHistory),
              (label: 'Simulacro nacional', ruta: Routes.nationalMock),
            ],
          ),
          _stub(
            Routes.simulacroInstructions,
            titulo: 'Antes de empezar',
            descripcion:
                '180 preguntas, 3 horas, sin retroalimentación, sin puntaje '
                'en contra y envío automático al agotarse el tiempo. No se '
                'puede pausar.',
            requisitos: const ['RF-16', 'RN-01'],
            acciones: const [(label: 'Comenzar', ruta: '/simulacro/sesion/demo')],
          ),
          _stub(
            Routes.simulacroSession,
            titulo: 'Simulacro en curso',
            descripcion:
                'Cronómetro siempre visible, sin feedback. Autoguardado cada '
                '30 s. No muestra de qué área es la pregunta.',
            requisitos: const ['RF-16'],
            acciones: const [
              (
                label: 'Grilla de navegación',
                ruta: '/simulacro/sesion/demo/navegacion',
              ),
              (label: 'Resultados', ruta: '/simulacro/resultados/demo'),
            ],
          ),
          _stub(
            Routes.simulacroNavigation,
            titulo: 'Navegación del examen',
            descripcion:
                'Grilla de 180 casillas agrupadas por área: respondida, sin '
                'responder y marcada. El reto de layout más difícil en 360 px.',
            requisitos: const ['RF-17'],
          ),
          _stub(
            Routes.simulacroResults,
            titulo: 'Resultados del simulacro',
            descripcion:
                'Nota vigesimal con 2 decimales (aprueba con 11.00), desglose '
                'por área y tiempo.',
            requisitos: const ['RF-18', 'RN-01'],
            acciones: const [
              (label: 'Revisar preguntas', ruta: '/simulacro/revision/demo'),
            ],
          ),
          _stub(
            Routes.simulacroReview,
            titulo: 'Revisión',
            descripcion:
                'Pregunta por pregunta con tu respuesta, la correcta y la '
                'explicación. Filtros por falladas y marcadas.',
            requisitos: const ['RF-18'],
          ),
          _stub(
            Routes.simulacroHistory,
            titulo: 'Historial de simulacros',
            descripcion: 'Lista con la evolución de la nota en el tiempo.',
            requisitos: const ['RF-20'],
          ),
          _stub(
            Routes.nationalMock,
            titulo: 'Simulacro nacional',
            descripcion:
                'Inscripción, sala de espera con cuenta regresiva y '
                'resultados con ranking. Requiere conexión.',
            requisitos: const ['RF-19', 'RF-33'],
          ),
        ],
      ),

      // --- Progreso ---
      StatefulShellBranch(
        routes: [
          _stub(
            Routes.stats,
            titulo: 'Progreso',
            descripcion:
                'Acierto por área contra el peso del blueprint, evolución '
                'temporal y desglose de la nota proyectada.',
            requisitos: const ['RF-21', 'RN-04'],
            acciones: const [
              (label: 'Dónde invertir tu tiempo', ruta: Routes.studyPriority),
              (label: 'Ranking', ruta: Routes.ranking),
            ],
          ),
          _stub(
            Routes.studyPriority,
            titulo: 'Dónde invertir tu tiempo',
            descripcion:
                'Cruza peso en el examen, cantidad de temario y desempeño. '
                '7 temas de Ciencias Básicas dan 10 preguntas; 123 de '
                'Medicina dan 40.',
            requisitos: const ['RF-21'],
          ),
          _stub(
            Routes.ranking,
            titulo: 'Ranking',
            descripcion:
                'General por promedio y por simulacro nacional, con opción de '
                'ocultarse del ranking público.',
            requisitos: const ['RF-22', 'RN-05'],
          ),
        ],
      ),
    ],
  ),

  // ==================== PRÁCTICA (encima de la barra) ====================
  _stub(
    Routes.practiceConfig,
    titulo: 'Configurar práctica',
    descripcion:
        'Selección de nodos del árbol a cualquier nivel, cantidad (10-50) y '
        'origen: todas / no vistas / falladas. Muestra cuántas hay disponibles.',
    requisitos: const ['RF-12'],
    acciones: const [(label: 'Sesión de ejemplo', ruta: '/practica/sesion/demo')],
  ),
  _stub(
    Routes.practiceSession,
    titulo: 'Práctica en curso',
    descripcion:
        'Enunciado clínico, 4 alternativas, marca de agua si es premium, y '
        'retroalimentación inmediata al responder. No muestra el área.',
    requisitos: const ['RF-13', 'RF-14', 'RNF-05'],
    acciones: const [
      (label: 'Ver resultados', ruta: '/practica/resultados/demo'),
    ],
  ),
  _stub(
    Routes.practiceResults,
    titulo: 'Resultados de práctica',
    descripcion: 'Aciertos, errores, tiempo y desglose por sub área.',
  ),
  _stub(
    Routes.markedQuestions,
    titulo: 'Preguntas marcadas',
    descripcion: 'Las guardadas para repasar después.',
    requisitos: const ['RF-14'],
  ),

  // ==================== SUSCRIPCIÓN ====================
  _stub(
    Routes.plans,
    titulo: 'Planes',
    descripcion: 'Free, mensual e intensivo pre-examen, con comparativa.',
    requisitos: const ['RF-25'],
    acciones: const [(label: 'Pagar', ruta: Routes.checkout)],
  ),
  _stub(
    Routes.paywall,
    titulo: 'Contenido premium',
    descripcion:
        'Se muestra al agotar las 20 preguntas del día o al abrir un '
        'simulacro completo con plan free.',
    requisitos: const ['RN-03'],
  ),
  _stub(
    Routes.checkout,
    titulo: 'Pago',
    descripcion: 'Checkout con Culqi: tarjeta y Yape/Plin.',
    requisitos: const ['RF-26'],
    acciones: const [(label: 'Pagar con Yape', ruta: Routes.yapePayment)],
  ),
  _stub(
    Routes.yapePayment,
    titulo: 'Pago con Yape',
    descripcion:
        'QR e instrucciones. La activación es manual, con estado "esperando '
        'verificación".',
    requisitos: const ['RF-28'],
  ),
  _stub(
    Routes.mySubscription,
    titulo: 'Mi suscripción',
    descripcion:
        'Plan actual, expiración, periodo de gracia de 3 días y cancelación.',
    requisitos: const ['RF-27', 'RN-07'],
  ),

  // ==================== OFFLINE ====================
  _stub(
    Routes.downloads,
    titulo: 'Descargas',
    descripcion:
        'Gestor de paquetes por área: tamaño, progreso y disponibles sin '
        'conexión. Solo premium.',
    requisitos: const ['RF-30'],
    acciones: const [(label: 'Sincronización', ruta: Routes.syncStatus)],
  ),
  _stub(
    Routes.syncStatus,
    titulo: 'Sincronización',
    descripcion: 'Respuestas encoladas y última sincronización.',
    requisitos: const ['RF-32'],
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
  _stub(
    Routes.profile,
    titulo: 'Perfil',
    descripcion: 'Datos, universidad, condición, fecha objetivo y progreso.',
    requisitos: const ['RF-04'],
    acciones: const [
      (label: 'Editar', ruta: Routes.editProfile),
      (label: 'Cambiar contraseña', ruta: Routes.changePassword),
      (label: 'Mi suscripción', ruta: Routes.mySubscription),
    ],
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
  _stub(
    Routes.settings,
    titulo: 'Ajustes',
    descripcion: 'Tema, notificaciones, descargas y cuenta.',
    acciones: const [
      (label: 'Perfil', ruta: Routes.profile),
      (label: 'Recordatorios', ruta: Routes.reminders),
      (label: 'Eliminar cuenta', ruta: Routes.deleteAccount),
      (label: 'Ayuda', ruta: Routes.help),
      (label: 'Términos', ruta: Routes.terms),
    ],
  ),
  _stub(
    Routes.reminders,
    titulo: 'Recordatorios',
    descripcion:
        'Hora del recordatorio diario y avisos de simulacro nacional y '
        'resultados.',
    requisitos: const ['RF-34'],
  ),
  _stub(
    Routes.deleteAccount,
    titulo: 'Eliminar cuenta',
    descripcion:
        'Qué se borra y confirmación explícita. Derecho de eliminación de la '
        'Ley 29733.',
    requisitos: const ['RNF-06'],
  ),
  _stub(
    Routes.help,
    titulo: 'Ayuda',
    descripcion: 'Preguntas frecuentes y contacto de soporte.',
  ),
  _stub(
    Routes.terms,
    titulo: 'Términos y privacidad',
    descripcion: 'Términos de uso y política de datos personales.',
    requisitos: const ['RNF-06'],
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
