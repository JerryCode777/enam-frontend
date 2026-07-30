import 'package:flutter/material.dart';

import '../../core/theme/design_tokens.dart';

/// Fondo de marca a pantalla completa, con las formas orgánicas del diseño.
///
/// Lo usan el splash (1.1) y el onboarding (1.2), que son las dos pantallas
/// que ocupan el degradado entero en vez de solo la cabecera.
///
/// Las formas van detrás del contenido y no reciben toques: son decoración, y
/// si interceptaran gestos se comerían los del PageView del onboarding.
class BrandGradient extends StatelessWidget {
  const BrandGradient({
    required this.child,
    this.formaInferior = true,
    this.circuloSecundarioArriba = true,
    super.key,
  });

  final Widget child;

  /// La mancha grande de abajo a la derecha. El onboarding no la lleva.
  final bool formaInferior;

  /// El segundo círculo va arriba en el splash y abajo en el onboarding.
  final bool circuloSecundarioArriba;

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;

    // `SizedBox.expand` no es decorativo: el `Stack` se ajusta a su hijo más
    // grande, así que en las pantallas donde el contenido no llega abajo el
    // degradado se cortaba y quedaba una franja del color del Scaffold.
    return SizedBox.expand(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            // 165° en CSS: baja casi en vertical, inclinado a la derecha.
            begin: const Alignment(-0.26, -1),
            end: const Alignment(0.26, 1),
            colors: oscuro
                ? DesignTokens.headerGradientDark
                : DesignTokens.headerGradientLight,
            stops: DesignTokens.headerGradientStops,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: Stack(
                  children: [
                    const Positioned(
                      top: -90,
                      right: -100,
                      child: _Circulo(tamano: 280, opacidad: 0.09),
                    ),
                    if (circuloSecundarioArriba)
                      const Positioned(
                        top: 150,
                        left: -80,
                        child: _Circulo(tamano: 200, opacidad: 0.06),
                      )
                    else
                      const Positioned(
                        bottom: 180,
                        left: -90,
                        child: _Circulo(tamano: 200, opacidad: 0.06),
                      ),
                    if (formaInferior)
                      const Positioned(
                        bottom: -70,
                        right: -50,
                        child: _Mancha(),
                      ),
                  ],
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

class _Circulo extends StatelessWidget {
  const _Circulo({required this.tamano, required this.opacidad});

  final double tamano;
  final double opacidad;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacidad),
      ),
    );
  }
}

/// La forma orgánica de abajo a la derecha: un círculo deformado.
class _Mancha extends StatelessWidget {
  const _Mancha();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 220,
      child: CustomPaint(painter: _ManchaPainter()),
    );
  }
}

class _ManchaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 260;
    final sy = size.height / 220;

    // Misma curva que el `path` del diseño, sobre un lienzo de 260 × 220.
    final path = Path()
      ..moveTo(130 * sx, 0)
      ..cubicTo(200 * sx, 0, 260 * sx, 45 * sy, 260 * sx, 110 * sy)
      ..cubicTo(260 * sx, 175 * sy, 215 * sx, 220 * sy, 140 * sx, 220 * sy)
      ..cubicTo(65 * sx, 220 * sy, 0, 185 * sy, 0, 120 * sy)
      ..cubicTo(0, 55 * sy, 60 * sx, 0, 130 * sx, 0)
      ..close();

    canvas.drawPath(
      path,
      Paint()..color = Colors.white.withValues(alpha: 0.08),
    );
  }

  @override
  bool shouldRepaint(_ManchaPainter old) => false;
}
