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
import '../../features/profile/presentation/change_password_screen.dart';
import '../../features/profile/presentation/delete_account_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/profile/presentation/help_screen.dart';
import '../../features/profile/presentation/legal_screen.dart';
import '../../features/profile/presentation/settings_screen.dart';
import '../../features/session/presentation/area_picker_screen.dart';
import '../../features/session/presentation/marked_questions_screen.dart';
import '../../features/session/presentation/national_mock_screen.dart';
import '../../features/session/presentation/past_exams_screen.dart';
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
import '../../features/subscription/domain/subscription_models.dart';
import '../../features/subscription/presentation/access_ended_screen.dart';
import '../../features/subscription/presentation/my_subscription_screen.dart';
import '../../features/system/presentation/system_screens.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/placeholder_screen.dart';
import '../../features/duelo/presentation/duelo_partida_screen.dart';
import '../../features/duelo/presentation/elegir_oponente_screen.dart';
import '../../features/duelo/presentation/tengo_un_codigo_screen.dart';
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

  // Sin escuchar también el arranque, la app se quedaría en el splash para
  // siempre: al resolverse no habría nada que dispare un nuevo redirect.
  ref.listen(authControllerProvider, (_, _) => notifier.value++);
  ref.listen(startupProvider, (_, _) => notifier.value++);
  // Sin esto el bloqueo por acceso llegaría tarde: la suscripción se resuelve
  // después del login, y nada dispararía un nuevo redirect.
  ref.listen(subscriptionProvider, (_, _) => notifier.value++);
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

  // Verificar el correo va aquí porque el registro **no abre sesión**:
  // `POST /auth/register` devuelve un mensaje, y la sesión llega después de
  // meter el código. Sin esta ruta abierta, quien acaba de registrarse rebota
  // al login y no ve nunca la pantalla donde escribir el código que le acaba de
  // llegar: la cuenta queda creada y sin forma de activarla.
  //
  // Estuvo fuera y ese fue exactamente el fallo. Con sesión ya iniciada la
  // rama de abajo se encarga de mandar aquí a quien no ha verificado.
  Routes.verifyEmail,

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

/// Lo que sigue alcanzable sin acceso (D-01).
///
/// La decisión del cliente fue **nada**: la app queda bloqueada tras la
/// pantalla de pago, sin temario ni estadísticas. Lo que queda aquí es solo lo
/// necesario para poder pagar, entender qué se cobra o irse — negarle a alguien
/// el camino de vuelta a su propio dinero, o los términos que aceptó, no es
/// bloquear el producto, es atraparlo.
///
/// Queda anotado que D-01 es **mejorable**: dejar ver el temario y el propio
/// avance daría una razón concreta para volver, y el temario no es el activo
/// del negocio — las preguntas sí. Revisar tras los primeros datos de
/// conversión.
/// Público para que un test lo pueda fijar: es una lista que crece sola en
/// cuanto alguien añade una pantalla "que también debería verse sin plan", y
/// cada entrada de más es contenido de pago regalado.
const rutasSinAcceso = {
  Routes.accessEnded,
  Routes.mySubscription,
  Routes.help,
  Routes.terms,
};

/// Prefijo de la partida de duelo, que lleva un id y no cabe en la lista.
const _prefijoPartidaDeDuelo = '/duelo/partida/';

/// Si esta ruta se puede pintar sin acceso.
///
/// Es una función y no solo [rutasSinAcceso] porque la partida del duelo lleva
/// un id en la URL, y comparar cadenas enteras nunca la encontraría.
///
/// # Por qué la partida entra y `/duelo` no
///
/// Quien juega con el pase diario (RF-65) va DIRECTO de la pantalla de cobro a
/// su partida: el botón crea el duelo y navega. Nunca pasa por «elegir
/// oponente», y dejarlo entrar ahí sería enseñarle dos opciones —el enlace de
/// retador y el PIN— que el servidor le va a rechazar.
///
/// # Y por qué esto no abre ningún agujero
///
/// Porque la ruta no es el permiso. Para ver algo de una partida hay que ser
/// uno de sus dos participantes: el servidor resuelve el lado del usuario al
/// abrir la sala y, si no juega ahí, no hay nada que enseñar (RNF-04).
bool alcanzableSinAcceso(String ruta) =>
    rutasSinAcceso.contains(ruta) || ruta.startsWith(_prefijoPartidaDeDuelo);

String? _redirect(Ref ref, GoRouterState state) => decidirDestino(
  auth: ref.read(authControllerProvider),
  startup: ref.read(startupProvider),
  suscripcion: ref.read(subscriptionProvider),
  here: state.matchedLocation,
);

/// Decide a dónde mandar al usuario. `null` lo deja pasar.
///
/// Función pura sobre los dos estados que importan, en vez de leer del `Ref`
/// directamente: así el recorrido de arranque —que es donde estaba el fallo del
/// onboarding inalcanzable— se puede probar sin montar un router.
@visibleForTesting
String? decidirDestino({
  required AsyncValue<AuthState> auth,
  required AsyncValue<Startup> startup,
  required AsyncValue<Subscription> suscripcion,
  required String here,
}) {
  // Aún leyendo el storage, o el splash no ha cumplido su tiempo mínimo:
  // quedarse en splash y no parpadear al login.
  //
  // Se mira `hasValue` y **no** `isLoading`: en cuanto se sabe si hay sesión o
  // no, una recarga posterior no debe mover al usuario de donde está. Con
  // `isLoading` aquí, cualquier operación que tocara el estado de auth mandaba
  // al splash y destruía la pantalla de turno — por eso un login fallido
  // devolvía un formulario en blanco, sin el error.
  if (!auth.hasValue || !startup.hasValue) {
    return here == Routes.splash ? null : Routes.splash;
  }

  return switch (auth.requireValue) {
    AuthLoading() => Routes.splash,

    // Sin sesión: el onboarding la primera vez, el login a partir de ahí.
    //
    // Antes esto mandaba siempre al login, así que el onboarding no era
    // alcanzable por ninguna ruta: existía el archivo y nadie lo veía nunca.
    AuthSignedOut() => switch (here) {
      _ when here == Routes.splash =>
        startup.requireValue.onboardingVisto ? Routes.login : Routes.onboarding,

      // Si ya se vio, volver a entrar por onboarding no tiene sentido.
      _ when here == Routes.onboarding && startup.requireValue.onboardingVisto =>
        Routes.login,

      _ when _publicRoutes.contains(here) => null,

      _ => Routes.login,
    },

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

      // RN-03 v2: sin acceso, la app queda tras la pantalla de pago (D-01).
      //
      // Se bloquea solo con un valor cargado que dice que no hay acceso. Con la
      // suscripción todavía cargando —o si falló la petición— se deja pasar: la
      // pantalla de pago parpadeando en cada arranque sería peor que dejar ver
      // una pantalla de más, y de todas formas el contenido lo protege el
      // servidor (RNF-04), no este redirect.
      _
          when suscripcion.value?.sinAcceso == true &&
              !rutasSinAcceso.contains(here) =>
        Routes.accessEnded,

      // Con acceso, la pantalla de bloqueo no tiene por qué seguir en pie: es
      // a donde vuelve alguien que acaba de pagar.
      _
          when here == Routes.accessEnded &&
              suscripcion.value?.daAcceso != false =>
        Routes.home,

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
    // El correo viaja desde el login: quien ya lo escribió no debería tener
    // que volver a escribirlo, y menos si lo que pasó es que no recuerda algo.
    builder: (context, state) =>
        ForgotPasswordScreen(email: state.extra as String?),
  ),
  GoRoute(
    path: Routes.resetPassword,
    // El correo llega desde la pantalla anterior; el código lo escribe el
    // usuario. Se acepta también por query para poder abrir la pantalla desde
    // un enlace de soporte.
    builder: (context, state) => ResetPasswordScreen(
      email: (state.extra as String?) ?? state.uri.queryParameters['email'],
    ),
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
    path: Routes.pastExams,
    pageBuilder: (context, state) =>
        slidePage(child: const PastExamsScreen(), state: state),
  ),
  // ---------- Modo duelo (M11) ----------
  //
  // Fuera del shell con barra inferior, como la práctica y el simulacro:
  // mientras dura una sesión no hay a dónde ir. En el duelo eso además es
  // literal — **salir de un duelo es perderlo** (RN-11): volviendo dentro de
  // 60 s se recupera y pasado ese margen ya no, así que la barra ofrecería
  // cuatro formas de perder una partida sin avisar de nada.
  //
  // El ORDEN importa: la ruta estática va antes que el comodín, para que
  // `/duelo/partida/xxx` no se lea como un código de retador.
  GoRoute(
    path: Routes.duelo,
    pageBuilder: (context, state) =>
        slidePage(child: const ElegirOponenteScreen(), state: state),
  ),
  GoRoute(
    path: Routes.dueloCodigoManual,
    pageBuilder: (context, state) =>
        slidePage(child: const TengoUnCodigoScreen(), state: state),
  ),
  GoRoute(
    path: Routes.dueloPartida,
    pageBuilder: (context, state) => fadePage(
      child: DueloPartidaScreen(dueloId: state.pathParameters['id']!),
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
  // Fuera del shell, como el configurador: abrir `/temario` con `push` desde
  // aquí montaría una segunda copia del shell y su Navigator, con la misma
  // GlobalKey que el ya montado, y la app muere con pantalla roja.
  GoRoute(
    path: Routes.practiceAreas,
    pageBuilder: (context, state) =>
        modalPage(child: const AreaPickerScreen(), state: state),
  ),
  GoRoute(
    path: Routes.markedQuestions,
    pageBuilder: (context, state) =>
        slidePage(child: const MarkedQuestionsScreen(), state: state),
  ),

  // ==================== SUSCRIPCIÓN (Módulo 6) ====================
  GoRoute(
    path: Routes.accessEnded,
    // Sin transición de entrada: no es una pantalla que el usuario abrió, es
    // donde lo dejó el router. Deslizarla la haría parecer navegación suya.
    pageBuilder: (context, state) =>
        fadePage(child: const AccessEndedScreen(), state: state),
  ),
  // No hay rutas de planes, pago ni resultado de pago, y no es un olvido.
  //
  // Ni App Store ni Google Play dejan cobrar dentro de la app sin llevarse su
  // comisión, así que el cobro ocurre en la web (modelo Netflix). Estas tres
  // pantallas existieron y se quitaron: enseñaban precios en iOS —motivo de
  // rechazo por la guideline 3.1.1— y el checkout, además, no llamaba a ningún
  // endpoint: validaba el formato de la tarjeta, esperaba 900 ms y anunciaba
  // "pago exitoso" pasara lo que pasara.
  //
  // Volver a añadirlas es volver a los dos problemas. Lo que las sustituye está
  // en features/subscription/presentation/widgets/opciones_de_pago.dart.
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
  GoRoute(
    path: Routes.offline,
    pageBuilder: (context, state) =>
        fadePage(child: const OfflineScreen(), state: state),
  ),

  // ==================== PERFIL Y AJUSTES ====================
  GoRoute(
    path: Routes.settings,
    pageBuilder: (context, state) =>
        slidePage(child: const SettingsScreen(), state: state),
  ),
  GoRoute(
    path: Routes.editProfile,
    pageBuilder: (context, state) =>
        slidePage(child: const EditProfileScreen(), state: state),
  ),
  GoRoute(
    path: Routes.changePassword,
    pageBuilder: (context, state) =>
        slidePage(child: const ChangePasswordScreen(), state: state),
  ),

  GoRoute(
    path: Routes.deleteAccount,
    pageBuilder: (context, state) =>
        slidePage(child: const DeleteAccountScreen(), state: state),
  ),
  GoRoute(
    path: Routes.help,
    pageBuilder: (context, state) =>
        slidePage(child: const HelpScreen(), state: state),
  ),
  GoRoute(
    path: Routes.terms,
    pageBuilder: (context, state) =>
        slidePage(child: const LegalScreen(), state: state),
  ),
  _stub(
    Routes.reminders,
    titulo: 'Recordatorios',
    descripcion: 'Se configuran desde Ajustes; esta ruta queda por deep link.',
    requisitos: const ['RF-34'],
  ),

  // ==================== SISTEMA ====================
  GoRoute(
    path: Routes.maintenance,
    pageBuilder: (context, state) => fadePage(
      child: MaintenanceScreen(hasta: state.uri.queryParameters['hasta']),
      state: state,
    ),
  ),
  GoRoute(
    path: Routes.updateRequired,
    pageBuilder: (context, state) =>
        fadePage(child: const UpdateRequiredScreen(), state: state),
  ),
];
