import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/analitica/analitica.dart';
import 'core/config/app_config.dart';
import 'core/providers.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/design_tokens.dart';

class EnamApp extends ConsumerStatefulWidget {
  const EnamApp({super.key});

  @override
  ConsumerState<EnamApp> createState() => _EnamAppState();
}

class _EnamAppState extends ConsumerState<EnamApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // El número de atención lo dice el servidor. Se pide aquí, sin esperarlo y
    // sin bloquear nada: si no llega, la app arranca igual con el compilado,
    // que es un número que funciona. Nadie debería quedarse fuera de estudiar
    // porque una preferencia no se pudo leer.
    unawaited(ref.read(configuracionRemotaProvider).cargar());

    // Los eventos que quedaron en la cola de la vez anterior, y cada vez que
    // vuelve la red: sin señal se guardan hasta siete días.
    unawaited(ref.read(analiticaProvider).enviarPendientes());
    ref.listenManual(hayRedProvider, (_, red) {
      if (red.value == true) {
        unawaited(ref.read(analiticaProvider).enviarPendientes());
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'ENAM Prep',
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
