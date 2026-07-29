import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/placeholder_screen.dart';
import '../providers.dart';
import 'routes.dart';

/// Router de la app.
///
/// Sustituye al patrón de la app hermana (un `StatefulWidget` con un `String
/// _currentStep` y `setState`), que no daba deep links, ni botón atrás correcto,
/// ni rutas nombradas.
///
/// Las guardas de navegación viven en [_redirect], en un solo lugar: ninguna
/// pantalla decide por su cuenta si el usuario puede estar ahí.
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ValueNotifier(0);

  // Cualquier cambio de auth revalúa el redirect.
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

/// Decide a dónde mandar al usuario. Devuelve `null` para dejarlo pasar.
String? _redirect(Ref ref, GoRouterState state) {
  final auth = ref.read(authControllerProvider);
  final here = state.matchedLocation;

  // Aún leyendo el storage: quedarse en splash y no parpadear al login.
  if (auth.isLoading || !auth.hasValue) {
    return here == Routes.splash ? null : Routes.splash;
  }

  final authState = auth.requireValue;

  return switch (authState) {
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

      // Con sesión válida, las pantallas de acceso no tienen sentido.
      _
          when user.perfilCompleto &&
              (here == Routes.splash ||
                  here == Routes.login ||
                  here == Routes.register ||
                  here == Routes.onboarding ||
                  here == Routes.verifyEmail ||
                  here == Routes.completeProfile) =>
        Routes.home,

      _ => null,
    },
  };
}

/// Atajo para declarar una pantalla de andamiaje.
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

final List<RouteBase> _routes = [
  // ==================== ARRANQUE ====================
  _stub(
    Routes.splash,
    titulo: 'Splash',
    descripcion: 'Carga inicial: revisa sesión guardada y estado del servicio.',
  ),
  _stub(
    Routes.onboarding,
    titulo: 'Onboarding',
    descripcion: 'Tres pasos: qué es la app, blueprint oficial y simulacros.',
    acciones: const [(label: 'Iniciar sesión', ruta: Routes.login)],
  ),

  // ==================== AUTENTICACIÓN (Módulo 1) ====================
  _stub(
    Routes.login,
    titulo: 'Iniciar sesión',
    descripcion: 'Correo y contraseña. Sin proveedores sociales.',
    requisitos: const ['RF-02'],
    acciones: const [
      (label: 'Crear cuenta', ruta: Routes.register),
      (label: 'Olvidé mi contraseña', ruta: Routes.forgotPassword),
    ],
  ),
  _stub(
    Routes.register,
    titulo: 'Crear cuenta',
    descripcion: 'Correo, contraseña y aceptación de términos (Ley 29733).',
    requisitos: const ['RF-01', 'RNF-06'],
  ),
  _stub(
    Routes.verifyEmail,
    titulo: 'Verifica tu correo',
    descripcion: 'Espera de verificación por enlace, con opción de reenviar.',
    requisitos: const ['RF-01'],
  ),
  _stub(
    Routes.forgotPassword,
    titulo: 'Recuperar contraseña',
    descripcion: 'Solicitud del enlace de recuperación.',
    requisitos: const ['RF-03'],
  ),
  _stub(
    Routes.resetPassword,
    titulo: 'Nueva contraseña',
    descripcion: 'Definir contraseña nueva desde el enlace del correo.',
    requisitos: const ['RF-03'],
  ),
  _stub(
    Routes.completeProfile,
    titulo: 'Completar perfil',
    descripcion:
        'Nombre, universidad, condición y fecha objetivo de examen. '
        'La fecha alimenta la cuenta regresiva del inicio.',
    requisitos: const ['RF-04'],
  ),

  // ==================== NÚCLEO ====================
  _stub(
    Routes.home,
    titulo: 'Inicio',
    descripcion:
        'Cuenta regresiva, nota proyectada, sesión a reanudar, accesos '
        'rápidos y límite diario si el plan es free.',
    requisitos: const ['RF-21', 'RN-03', 'RN-04'],
    acciones: const [
      (label: 'Configurar práctica', ruta: Routes.practiceConfig),
      (label: 'Simulacros', ruta: Routes.simulacroSelection),
      (label: 'Estadísticas', ruta: Routes.stats),
      (label: 'Ranking', ruta: Routes.ranking),
      (label: 'Perfil', ruta: Routes.profile),
      (label: 'Ajustes', ruta: Routes.settings),
      (label: 'Planes', ruta: Routes.plans),
      (label: 'Descargas offline', ruta: Routes.downloads),
    ],
  ),
  _stub(
    Routes.stats,
    titulo: 'Estadísticas',
    descripcion:
        'Acierto por área contra el peso del blueprint, evolución temporal '
        'y desglose de la nota proyectada.',
    requisitos: const ['RF-21', 'RN-04'],
  ),

  // ==================== PRÁCTICA (Módulo 3) ====================
  _stub(
    Routes.practiceConfig,
    titulo: 'Configurar práctica',
    descripcion:
        'Áreas, subtemas, cantidad (10-50) y origen: todas / no vistas / '
        'falladas.',
    requisitos: const ['RF-12'],
    acciones: const [
      (label: 'Elegir áreas', ruta: Routes.practiceAreas),
      (label: 'Sesión de ejemplo', ruta: '/practica/sesion/demo'),
    ],
  ),
  _stub(
    Routes.practiceAreas,
    titulo: 'Áreas y subtemas',
    descripcion: 'Navegación de las 10 áreas con el progreso del usuario.',
    requisitos: const ['RF-06'],
  ),
  _stub(
    Routes.markedQuestions,
    titulo: 'Preguntas marcadas',
    descripcion: 'Las guardadas para repasar después.',
    requisitos: const ['RF-14'],
  ),
  _stub(
    Routes.practiceSession,
    titulo: 'Práctica en curso',
    descripcion:
        'Enunciado clínico, 4 alternativas, marca de agua si es premium, '
        'y retroalimentación inmediata al responder.',
    requisitos: const ['RF-13', 'RF-14', 'RNF-05'],
    acciones: const [(label: 'Ver resultados', ruta: '/practica/resultados/demo')],
  ),
  _stub(
    Routes.practiceResults,
    titulo: 'Resultados de práctica',
    descripcion: 'Aciertos, errores, tiempo y desglose por subtema.',
  ),

  // ==================== SIMULACROS (Módulo 4) ====================
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
        '180 preguntas, 3 horas, sin retroalimentación, sin puntaje en '
        'contra y envío automático al agotarse el tiempo. No se puede pausar.',
    requisitos: const ['RF-16', 'RN-01'],
    acciones: const [(label: 'Comenzar', ruta: '/simulacro/sesion/demo')],
  ),
  _stub(
    Routes.simulacroSession,
    titulo: 'Simulacro en curso',
    descripcion:
        'Cronómetro de cuenta regresiva siempre visible, sin feedback. '
        'Autoguardado cada 30 s.',
    requisitos: const ['RF-16'],
    acciones: const [
      (label: 'Grilla de navegación', ruta: '/simulacro/sesion/demo/navegacion'),
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
        'Nota vigesimal (aprueba con 11.00), desglose por área y tiempo.',
    requisitos: const ['RF-18', 'RN-01'],
    acciones: const [(label: 'Revisar preguntas', ruta: '/simulacro/revision/demo')],
  ),
  _stub(
    Routes.simulacroReview,
    titulo: 'Revisión',
    descripcion:
        'Recorrido pregunta por pregunta con tu respuesta, la correcta y la '
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
        'Inscripción, sala de espera con cuenta regresiva y resultados con '
        'ranking. Requiere conexión.',
    requisitos: const ['RF-19', 'RF-33'],
  ),
  _stub(
    Routes.ranking,
    titulo: 'Ranking',
    descripcion:
        'General por promedio y por simulacro nacional. Con opción de '
        'ocultarse del ranking público.',
    requisitos: const ['RF-22', 'RN-05'],
  ),

  // ==================== SUSCRIPCIÓN (Módulo 6) ====================
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
        'QR e instrucciones. La activación es manual, con estado '
        '"esperando verificación".',
    requisitos: const ['RF-28'],
  ),
  _stub(
    Routes.mySubscription,
    titulo: 'Mi suscripción',
    descripcion:
        'Plan actual, expiración, periodo de gracia de 3 días y cancelación.',
    requisitos: const ['RF-27', 'RN-07'],
  ),

  // ==================== OFFLINE (Módulo 7) ====================
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
        'Qué sigue funcionando y qué no. Los simulacros nacionales '
        'requieren conexión.',
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
        'Qué se borra y confirmación explícita. Derecho de eliminación de '
        'la Ley 29733.',
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
