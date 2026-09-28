import 'package:flutter/material.dart';

/// Curvas y duraciones del movimiento de la app, en un solo sitio.
///
/// **Regla de accesibilidad:** todo lo de aquí respeta `disableAnimations` del
/// sistema. Si el usuario pidió reducir el movimiento, las animaciones no se
/// acortan: se anulan. Hay gente a la que el movimiento le produce mareo, y en
/// una app que se usa cansado eso importa más que el lucimiento.
abstract final class Motion {
  // ==================== DURACIONES ====================

  // Los mismos valores que la web (docs/TOKENS.md, plan §8).

  /// Micro-reacciones: una opción que se selecciona, un icono que cambia.
  static const fast = Duration(milliseconds: 140);

  /// Un panel que entra: la explicación, una hoja, un aviso.
  static const normal = Duration(milliseconds: 220);

  /// Navegación habitual entre pantallas.
  static const navigation = Duration(milliseconds: 200);

  /// Un resultado o resumen que aparece. Una vez por resultado.
  static const slow = Duration(milliseconds: 350);

  /// Barras y anillos que crecen hasta su valor. Igual que [slow]: la cifra
  /// que acompañan se lee correcta desde el primer fotograma, la barra solo
  /// la subraya.
  static const counter = slow;

  /// Retraso entre bloques de una entrada escalonada.
  static const stagger = Duration(milliseconds: 30);

  /// Tope del escalonado: a partir del quinto bloque todos entran juntos. Con
  /// 30 ms y 220 ms de entrada, la pantalla está completa en unos 340 ms y
  /// nadie espera a que termine una coreografía para leer.
  static const maxStaggerIndex = 4;

  // ==================== CURVAS ====================

  /// Entradas: rápido al principio, se asienta al final.
  static const enter = Curves.easeOutCubic;

  /// Salidas: arranca suave y acelera.
  static const exit = Curves.easeInCubic;

  /// Cambios de estado dentro de un elemento que ya está en pantalla.
  static const standard = Curves.easeInOut;

  /// Para lo que debe sentirse con peso: un resultado que aterriza. Sin
  /// rebote: un número que se pasa de su valor y vuelve se lee mal.
  static const emphasized = Curves.easeOutQuart;

  /// Si el sistema pidió reducir el movimiento.
  static bool reduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);

  /// Devuelve la duración, o cero si hay que reducir el movimiento.
  static Duration duration(BuildContext context, Duration d) =>
      reduced(context) ? Duration.zero : d;
}
