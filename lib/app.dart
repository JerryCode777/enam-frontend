import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/analitica/analitica.dart';
import 'core/config/app_config.dart';
import 'core/providers.dart';
import 'core/router/app_router.dart';
import 'core/router/navegar.dart';
import 'core/router/routes.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/design_tokens.dart';
import 'features/system/data/actualizador.dart';
import 'features/system/domain/actualizacion.dart';
import 'features/recordatorios/presentation/recordatorios_controller.dart';
import 'features/subscription/presentation/widgets/opciones_de_pago.dart'
    show enTiendaApple;

class EnamApp extends ConsumerStatefulWidget {
  const EnamApp({super.key});

  @override
  ConsumerState<EnamApp> createState() => _EnamAppState();
}

class _EnamAppState extends ConsumerState<EnamApp> with WidgetsBindingObserver {
  /// Para avisar desde aquí, fuera de cualquier pantalla, que la versión
  /// nueva ya se descargó.
  final _mensajero = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Una vez por arranque: si Play tiene una versión nueva, la ofrece y la
    // descarga mientras se estudia (la flexible). No cuando la instalada ya
    // está por debajo de la mínima: de eso se encarga «Actualiza para
    // continuar», con la inmediata.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(_ofrecerVersionNueva()),
    );

    // El número de atención lo dice el servidor. Se pide aquí, sin esperarlo y
    // sin bloquear nada: si no llega, la app arranca igual con el compilado,
    // que es un número que funciona. Nadie debería quedarse fuera de estudiar
    // porque una preferencia no se pudo leer.
    unawaited(ref.read(configuracionRemotaProvider).cargar());

    // Recordatorios locales: el plugin, el aviso que abrió la app (si fue
    // uno) y la semana de avisos con los datos de hoy.
    unawaited(_iniciarRecordatorios());
    ref.listenManual(avisoTocadoProvider, (_, _) => _atenderAviso());
    ref.listenManual(
      currentUserProvider.select((u) => u?.perfilCompleto),
      (_, _) => _atenderAviso(),
    );
    // La racha llega con el dashboard, después de arrancar: el texto de
    // «no pierdas tu racha» la necesita.
    ref.listenManual(
      dashboardProvider.select((d) => d.value?.racha?.dias),
      (_, _) =>
          unawaited(ref.read(recordatoriosProvider.notifier).reprogramar()),
    );

    // Los eventos que quedaron en la cola de la vez anterior, y cada vez que
    // vuelve la red: sin señal se guardan hasta siete días.
    unawaited(ref.read(analiticaProvider).enviarPendientes());
    ref.listenManual(hayRedProvider, (_, red) {
      if (red.value == true) {
        unawaited(ref.read(analiticaProvider).enviarPendientes());
      }
    });

    // Android: al abrir con sesión, o al iniciarla, se vuelve a mandar al
    // servidor lo que se compró en Play y quedó sin registrar (pagó y se cerró
    // la app, sin red, otro teléfono). Es idempotente en el servidor.
    ref.listenManual(currentUserProvider.select((u) => u?.id), (_, id) {
      if (id != null && !enTiendaApple && !kIsWeb) {
        unawaited(
          ref.read(comprasGooglePlayControllerProvider).restaurarEnSilencio(),
        );
      }
      // iPhone: escuchar ya al arrancar. StoreKit entrega entonces lo que
      // quedó sin completar (pagó y se cerró la app) y se registra solo; hasta
      // la 1.1.9 eso esperaba a que la persona volviera a abrir Planes.
      if (id != null && enTiendaApple && !kIsWeb) {
        ref.read(comprasAppleControllerProvider).escuchar();
      }
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _iniciarRecordatorios() async {
    final notificador = ref.read(notificadorProvider);
    final tocado = ref.read(avisoTocadoProvider.notifier);
    try {
      await notificador.iniciar(alTocar: tocado.tocado);
      if (await notificador.payloadDeArranque() case final p?) tocado.tocado(p);
      await ref.read(recordatoriosProvider.notifier).reprogramar();
    } catch (_) {
      // Sin recordatorios la app sigue igual: no es motivo para no arrancar.
    }
  }

  /// Un aviso tocado lleva a practicar, pero solo con la sesión lista: si no,
  /// espera a que la persona entre (y complete su perfil).
  void _atenderAviso() {
    final payload = ref.read(avisoTocadoProvider);
    final user = ref.read(currentUserProvider);
    if (payload == null || user == null || !user.perfilCompleto) return;
    ref.read(avisoTocadoProvider.notifier).atendido();
    if (propiedadesDeAbierta(payload) case final propiedades?) {
      ref
          .read(analiticaProvider)
          .registrar(Evento.notifAbierta, propiedades: propiedades);
    }
    // Tras el cuadro: el router puede estar todavía saliendo del splash. Con
    // `irA`, que decide si apilar o cambiar de pestaña.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final contexto = ref
          .read(routerProvider)
          .routerDelegate
          .navigatorKey
          .currentContext;
      if (mounted && contexto != null) contexto.irA(Routes.practiceConfig);
    });
  }

  Future<void> _ofrecerVersionNueva() async {
    if (kIsWeb || enTiendaApple) return;
    if (ref.read(actualizacionObligatoriaProvider)) return;
    final actualizador = ref.read(actualizadorProvider);
    if (!await actualizador.descargarSiHayNueva() || !mounted) return;
    _mensajero.currentState?.showSnackBar(
      SnackBar(
        // Se queda hasta que la toque: reiniciar a mitad de una pregunta sin
        // que lo pida sería perderle el hilo.
        duration: const Duration(days: 1),
        content: const Text('La nueva versión de ENAM Prep está lista.'),
        action: SnackBarAction(
          label: 'Reiniciar',
          onPressed: () => unawaited(actualizador.instalarDescargada()),
        ),
      ),
    );
  }

  /// Al volver de segundo plano se vuelve a preguntar por la suscripción.
  ///
  /// La prueba dura 24 h y el cron del servidor corre cada hora, así que puede
  /// vencer con la app cerrada. Sin esto, quien deja la app abierta de un día
  /// para otro sigue navegando con el estado que leyó ayer, hasta que el
  /// servidor le responda un 403 en medio de algo.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(subscriptionProvider);

      // Y de paso el número de atención: así un cambio de línea llega a las
      // apps ya instaladas sin esperar a que alguien las cierre del todo.
      unawaited(ref.read(configuracionRemotaProvider).cargar());
      unawaited(ref.read(analiticaProvider).enviarPendientes());
      // Por si apagó las notificaciones en el teléfono, o cambió el día.
      unawaited(ref.read(recordatoriosProvider.notifier).reprogramar());
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'ENAM Prep',
      scaffoldMessengerKey: _mensajero,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      builder: (context, child) {
        // Topa el escalado de texto del sistema. Sin esto, un usuario con la
        // fuente al máximo rompe la grilla de 180 casillas del simulacro; sin
        // límite inferior, el texto quedaría más chico de lo diseñado.
        final media = MediaQuery.of(context);
        final contenido = MediaQuery(
          data: media.copyWith(
            textScaler: media.textScaler.clamp(
              minScaleFactor: 1,
              maxScaleFactor: 1.4,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );

        // Con datos falsos, que se vea. Media hora depurando un número que no
        // cuadra para descubrir que venía de un mock es un rato perdido que se
        // evita con una cinta en la esquina. En release no existe: `useMocks`
        // es const y el compilador se lleva la rama entera.
        if (!AppConfig.useMocks) return contenido;
        return Banner(
          message: 'DATOS FALSOS',
          location: BannerLocation.topEnd,
          color: DesignTokens.warning,
          child: contenido,
        );
      },
    );
  }
}

/// Fondo de arranque mientras se resuelve la sesión.
class AppSplash extends StatelessWidget {
  const AppSplash({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: SizedBox(
          width: DesignTokens.space8,
          height: DesignTokens.space8,
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}
