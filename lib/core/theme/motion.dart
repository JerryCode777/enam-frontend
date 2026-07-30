import 'package:flutter/material.dart';

/// Curvas y duraciones del movimiento de la app, en un solo sitio.
///
/// **Regla de accesibilidad:** todo lo de aquí respeta `disableAnimations` del
/// sistema. Si el usuario pidió reducir el movimiento, las animaciones no se
/// acortan: se anulan. Hay gente a la que el movimiento le produce mareo, y en
/// una app que se usa cansado eso importa más que el lucimiento.
abstract final class Motion {
  // ==================== DURACIONES ====================

  /// Micro-reacciones: un chip que se marca, un icono que cambia.
  static const fast = Duration(milliseconds: 150);

  /// El caso normal: aparecer, desplazar, expandir.
  static const normal = Duration(milliseconds: 250);

  /// Transiciones de pantalla y paneles que entran.
  static const slow = Duration(milliseconds: 400);

  /// Contadores y barras que cuentan hacia su valor.
  static const counter = Duration(milliseconds: 900);

  /// Retraso entre elementos de una lista escalonada.
  static const stagger = Duration(milliseconds: 45);

  /// Tope del escalonado: con listas largas, a partir de cierto punto todos
  /// entran juntos. Sin esto, el elemento 120 tardaría 5 segundos en aparecer.
  static const maxStaggerIndex = 8;

  // ==================== CURVAS ====================

  /// Entradas: rápido al principio, se asienta al final.
  static const enter = Curves.easeOutCubic;

  /// Salidas: arranca suave y acelera.
  static const exit = Curves.easeInCubic;

  /// Cambios de estado dentro de un elemento que ya está en pantalla.
  static const standard = Curves.easeInOut;

  /// Para lo que debe sentirse con peso: un resultado que aterriza.
  static const emphasized = Curves.easeOutBack;

  /// Si el sistema pidió reducir el movimiento.
  static bool reduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);

  /// Devuelve la duración, o cero si hay que reducir el movimiento.
  static Duration duration(BuildContext context, Duration d) =>
      reduced(context) ? Duration.zero : d;
}
