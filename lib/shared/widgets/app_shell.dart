import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/router/routes.dart';

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
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
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
    );
  }
}
