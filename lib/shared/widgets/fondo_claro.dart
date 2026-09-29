import 'package:flutter/material.dart';

import '../../core/theme/design_tokens.dart';

/// El fondo de las pantallas de acceso: el fondo claro de la app con dos halos
/// suaves del azul de marca.
///
/// Sustituye al degradado azul marino a pantalla completa. La presentación y
/// el acceso son la primera impresión, y el producto pidió que se vieran en el
/// tema claro de la app, igual que en la web (`--enam-bg` con
/// `rgb(46 155 208 / .16)` arriba a la izquierda y `/ .12` abajo a la
/// derecha). Estas pantallas van siempre en claro (`SiempreClaro`), así que el
/// color es fijo.
class FondoClaro extends StatelessWidget {
  const FondoClaro({required this.child, super.key});

  final Widget child;

  static const _halo = Color(0xFF2E9BD0);

  @override
  Widget build(BuildContext context) {
    // `SizedBox.expand`: sin él, en las pantallas cuyo contenido no llega
    // abajo el fondo se cortaría y quedaría una franja del Scaffold.
    return SizedBox.expand(
      child: ColoredBox(
        color: DesignTokens.backgroundLight,
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(-1.1, -1.05),
                      radius: 1.1,
                      colors: [
                        _halo.withValues(alpha: 0.16),
                        _halo.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(1.15, 1.1),
                      radius: 1.0,
                      colors: [
                        _halo.withValues(alpha: 0.12),
                        _halo.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}
