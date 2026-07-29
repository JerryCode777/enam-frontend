import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/state_colors.dart';

/// Pantalla 1.1 — carga inicial.
///
/// El router decide a dónde ir cuando el estado de sesión se resuelve; esta
/// pantalla solo espera. No navega por su cuenta.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final states = context.states;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: states.info.tint,
                        borderRadius: BorderRadius.circular(
                          DesignTokens.radiusXl,
                        ),
                      ),
                      child: Icon(
                        Symbols.stethoscope,
                        size: 44,
                        fill: 1,
                        color: states.info.onTint,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space4),
                    Text(
                      'ENAM Prep',
                      style: context.texts.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.24,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space4),
                    _EcgLine(color: scheme.primary),
                    const SizedBox(height: DesignTokens.space4),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.space8,
                      ),
                      child: Text(
                        'Preparación para el Examen Nacional de Medicina',
                        textAlign: TextAlign.center,
                        style: context.texts.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: DesignTokens.space10),
              child: SizedBox(
                width: 120,
                height: 4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    backgroundColor: scheme.outlineVariant,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// La línea de electrocardiograma del logo.
class _EcgLine extends StatelessWidget {
  const _EcgLine({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 26,
      child: CustomPaint(painter: _EcgPainter(color)),
    );
  }
}

class _EcgPainter extends CustomPainter {
  const _EcgPainter(this.color);

  final Color color;

  // Coordenadas del trazo, sobre un lienzo de 180 × 26.
  static const _points = <Offset>[
    Offset(0, 13),
    Offset(50, 13),
    Offset(56, 3),
    Offset(64, 23),
    Offset(70, 9),
    Offset(76, 13),
    Offset(118, 13),
    Offset(124, 5),
    Offset(132, 21),
    Offset(138, 13),
    Offset(180, 13),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 180;
    final scaleY = size.height / 26;

    final path = Path();
    for (var i = 0; i < _points.length; i++) {
      final p = Offset(_points[i].dx * scaleX, _points[i].dy * scaleY);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_EcgPainter old) => old.color != color;
}
