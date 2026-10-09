import 'dart:math';

import 'package:flutter/painting.dart';

/// Relación de contraste de WCAG 2.2 entre dos colores opacos.
///
/// Se calcula aquí y no con `Color.computeLuminance` a secas para que la
/// fórmula completa quede a la vista: es la que usa la tabla de
/// diseno/TOKENS.md y la misma que aplica la web.
double contraste(Color a, Color b) {
  final la = _luminancia(a);
  final lb = _luminancia(b);
  return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
}

double _luminancia(Color c) {
  double canal(double v) =>
      v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * canal(c.r) + 0.7152 * canal(c.g) + 0.0722 * canal(c.b);
}
