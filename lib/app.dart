import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
