import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/motion.dart';

/// Transiciones de ruta de la app.
///
/// Se usan `CustomTransitionPage` en vez de la transición por defecto de
/// Material porque el diseño pide un desplazamiento más corto y suave. Todas
/// respetan `disableAnimations`: si el usuario pidió reducir el movimiento, la
/// pantalla aparece sin transición.

/// Entra desde la derecha. Es la transición normal al profundizar en una
/// jerarquía: área → sub área → tema.
CustomTransitionPage<T> slidePage<T>({
  required Widget child,
  required GoRouterState state,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: Motion.normal,
    reverseTransitionDuration: Motion.fast,
    transitionsBuilder: (context, animation, secondary, child) {
      if (Motion.reduced(context)) return child;

      final entrada = CurvedAnimation(parent: animation, curve: Motion.enter);

      return SlideTransition(
        position: Tween(
          // Un cuarto de pantalla, no una pantalla entera: se siente más rápido
          // sin perder la sensación de dirección.
          begin: const Offset(0.25, 0),
          end: Offset.zero,
        ).animate(entrada),
        child: FadeTransition(opacity: entrada, child: child),
      );
    },
  );
}

/// Sube desde abajo. Para lo que interrumpe: paywall, checkout, visor de imagen.
CustomTransitionPage<T> modalPage<T>({
  required Widget child,
  required GoRouterState state,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: Motion.slow,
    reverseTransitionDuration: Motion.normal,
    transitionsBuilder: (context, animation, secondary, child) {
      if (Motion.reduced(context)) return child;

      final entrada = CurvedAnimation(parent: animation, curve: Motion.enter);

      return SlideTransition(
        position: Tween(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(entrada),
        child: child,
      );
    },
  );
}

/// Solo desvanece. Para cambios donde el desplazamiento confundiría la
/// jerarquía: entrar a una sesión de práctica, o los estados de sistema.
CustomTransitionPage<T> fadePage<T>({
  required Widget child,
  required GoRouterState state,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: Motion.normal,
    reverseTransitionDuration: Motion.fast,
    transitionsBuilder: (context, animation, secondary, child) {
      if (Motion.reduced(context)) return child;
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Motion.enter),
        child: child,
      );
    },
  );
}

/// Sin transición. Para las pestañas de la barra inferior: cambiar de sección
/// con un desplazamiento lateral sugeriría una jerarquía que no existe.
NoTransitionPage<T> instantPage<T>({
  required Widget child,
  required GoRouterState state,
}) {
  return NoTransitionPage<T>(key: state.pageKey, child: child);
}
