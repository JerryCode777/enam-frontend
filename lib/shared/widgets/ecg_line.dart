import 'package:flutter/material.dart';

import '../../core/theme/motion.dart';

/// La línea de electrocardiograma de la marca, con un segmento que la recorre.
///
/// Está en un solo sitio porque aparece en tres pantallas —splash, login y el
/// hero del Home— y llegó a tener tres copias del mismo trazo con coordenadas
/// ligeramente distintas.
///
/// Se detiene si el sistema pidió reducir el movimiento: es decorativa y no
/// aporta información, así que es la primera que sobra.
class EcgLine extends StatefulWidget {
  const EcgLine({
    this.width = 220,
    this.height = 30,
    this.color = Colors.white,
    this.opacity = 0.9,
    this.strokeWidth = 2.5,
    this.duration = const Duration(milliseconds: 2200),
    super.key,
  });

  final double width;
  final double height;
  final Color color;
  final double opacity;
  final double strokeWidth;
  final Duration duration;

  @override
  State<EcgLine> createState() => _EcgLineState();
}

class _EcgLineState extends State<EcgLine> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // El arranque va aquí y no en initState: con el movimiento reducido no se
    // programa ningún ticker, en vez de programarlo y luego ignorarlo.
    if (!Motion.reduced(context) && !_c.isAnimating) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          painter: _EcgPainter(
            avance: _c.value,
            color: widget.color.withValues(alpha: widget.opacity),
            grosor: widget.strokeWidth,
            // Con movimiento reducido el trazo se pinta entero y quieto: se ve
            // el mismo dibujo, sin nada moviéndose.
            estatico: Motion.reduced(context),
          ),
        ),
      ),
    );
  }
}

class _EcgPainter extends CustomPainter {
  const _EcgPainter({
    required this.avance,
    required this.color,
    required this.grosor,
    required this.estatico,
  });

  final double avance;
  final Color color;
  final double grosor;
  final bool estatico;

  /// Trazo del diseño, sobre un lienzo de 220 × 30. Se escala a cualquier
  /// tamaño, así que las tres pantallas dibujan exactamente la misma curva.
  static const _puntos = <Offset>[
    Offset(0, 15),
    Offset(50, 15),
    Offset(62, 15),
    Offset(69, 4),
    Offset(78, 26),
    Offset(85, 10),
    Offset(92, 15),
    Offset(130, 15),
    Offset(142, 15),
    Offset(149, 6),
    Offset(157, 23),
    Offset(164, 15),
    Offset(220, 15),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 220;
    final sy = size.height / 30;

    final trazo = Path();
    for (var i = 0; i < _puntos.length; i++) {
      final p = Offset(_puntos[i].dx * sx, _puntos[i].dy * sy);
      i == 0 ? trazo.moveTo(p.dx, p.dy) : trazo.lineTo(p.dx, p.dy);
    }

    final pincel = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = grosor
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (estatico) {
      canvas.drawPath(trazo, pincel);
      return;
    }

    // Un segmento que recorre el trazo, como el `stroke-dasharray` del diseño.
    // `PathMetrics` da la longitud real para poder extraerlo.
    final metrica = trazo.computeMetrics().first;
    final largoSegmento = metrica.length * 0.3;
    final recorrido = metrica.length + largoSegmento;
    final fin = avance * recorrido;
    final inicio = fin - largoSegmento;

    canvas.drawPath(
      metrica.extractPath(
        inicio.clamp(0, metrica.length),
        fin.clamp(0, metrica.length),
      ),
      pincel,
    );
  }

  @override
  bool shouldRepaint(_EcgPainter old) =>
      old.avance != avance ||
      old.estatico != estatico ||
      old.color != color ||
      old.grosor != grosor;
}
