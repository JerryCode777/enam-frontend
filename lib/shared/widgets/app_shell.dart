import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/providers.dart';
import '../../core/router/routes.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/state_colors.dart';
import '../../features/offline/presentation/offline_providers.dart';

/// Los cuatro destinos fijos de la barra inferior.
enum ShellTab {
  inicio('Inicio', Symbols.home, Routes.home),
  temario('Temario', Symbols.account_tree, Routes.temario),
  simulacros('Simulacros', Symbols.timer, Routes.simulacroSelection),
  progreso('Progreso', Symbols.monitoring, Routes.stats);

  const ShellTab(this.label, this.icon, this.route);

  final String label;
  final IconData icon;
  final String route;
}

/// Contenedor de las secciones principales, con la barra inferior persistente.
///
/// Se monta como `StatefulShellRoute` para que cada pestaña conserve su propia
/// pila de navegación: si el usuario entra a un área del temario, cambia a
/// Simulacros y vuelve, sigue donde estaba.
///
/// Además es el sitio donde vive la sincronización del modo sin conexión. Aquí
/// y no en la pantalla de descargas: lo respondido en el bus tiene que salir en
/// cuanto vuelva la señal, esté el usuario donde esté.
class AppShell extends ConsumerWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Basta con observarlo: al construirse queda atento a la vuelta de la red.
    ref.watch(sincronizacionProvider);
    final hayRed = ref.watch(hayRedProvider).value ?? true;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!hayRed) const _SinConexion(),
          NavigationBar(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (index) => navigationShell.goBranch(
              index,
              // Tocar la pestaña activa vuelve a su raíz, como espera Android.
              initialLocation: index == navigationShell.currentIndex,
            ),
            destinations: [
              for (final tab in ShellTab.values)
                NavigationDestination(
                  icon: Icon(tab.icon),
                  selectedIcon: Icon(tab.icon, fill: 1),
                  label: tab.label,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Una franja fina, no un cartel.
///
/// Estar sin señal no es un error del que haya que rescatar a nadie: con áreas
/// descargadas se puede seguir practicando. Solo hace falta que quede claro por
/// qué algunas cosas no responden.
class _SinConexion extends StatelessWidget {
  const _SinConexion();

  @override
  Widget build(BuildContext context) {
    final aviso = context.states.warning;

    return Material(
      color: aviso.tint,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space4,
            vertical: DesignTokens.space2,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Symbols.wifi_off, size: 17, fill: 1, color: aviso.onTint),
              const SizedBox(width: DesignTokens.space2),
              Flexible(
                child: Text(
                  'Sin conexión · practicas con lo descargado',
                  style: context.texts.bodySmall?.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: aviso.onTint,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
