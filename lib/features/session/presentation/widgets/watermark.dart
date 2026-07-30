import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Marca de agua anti-scraping sobre el contenido premium (RNF-05).
///
/// El banco de preguntas es el activo del negocio y el SSD lo lista como riesgo
/// alto. Esto no impide copiar: **disuade**. El caso que ataca no es el scraping
/// masivo por API —eso lo frena el rate limiting— sino al suscriptor que hace una
/// captura y la comparte en un grupo. Con su id encima, el filtrado deja de ser
/// anónimo.
///
/// Opacidad muy baja a propósito. La legibilidad del enunciado clínico es la
/// tarea principal de la pantalla; una marca que estorbe la lectura cuesta más de
/// lo que protege.
class Watermark extends StatelessWidget {
  const Watermark({
    required this.child,
    required this.texto,
    this.opacidad = 0.055,
    super.key,
  });

  final Widget child;

  /// Identificador del usuario. Lo que hace rastreable la captura.
  final String texto;

  final double opacidad;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        // No intercepta toques: el usuario tiene que poder seleccionar el texto
        // del enunciado y tocar las alternativas.
        Positioned.fill(
          child: IgnorePointer(
            child: ClipRect(
              child: CustomPaint(
                painter: _WatermarkPainter(
                  texto: '$texto · ',
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: opacidad),
                  textScaler: MediaQuery.textScalerOf(context),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WatermarkPainter extends CustomPainter {
  _WatermarkPainter({
    required this.texto,
    required this.color,
    required this.textScaler,
  });

  final String texto;
  final Color color;
  final TextScaler textScaler;

  static const _anguloGrados = -22.0;
  static const _separacionFilas = 64.0;

  @override
  void paint(Canvas canvas, Size size) {
    const radianes = _anguloGrados * math.pi / 180;

    final painter = TextPainter(
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
      text: TextSpan(
        // Repetido para cubrir el ancho girado sin medir cada vez.
        text: texto * 6,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 2.6,
          color: color,
        ),
      ),
    )..layout();

    canvas.save();
    // Se gira alrededor del centro y se dibuja de más para cubrir las esquinas
    // que el giro deja fuera.
    canvas
      ..translate(size.width / 2, size.height / 2)
      ..rotate(radianes)
      ..translate(-size.width / 2, -size.height / 2);

    final filas = (size.height / _separacionFilas).ceil() + 2;
    for (var i = -1; i < filas; i++) {
      // Filas alternas desfasadas: sin el desfase se forman columnas verticales
      // que se leen como un patrón y distraen más.
      final dx = i.isEven ? -80.0 : -140.0;
      painter.paint(canvas, Offset(dx, i * _separacionFilas));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WatermarkPainter old) =>
      old.texto != texto || old.color != color;
}
