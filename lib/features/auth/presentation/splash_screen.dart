import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/motion.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/brand_gradient.dart';

/// Pantalla 1.1 — carga inicial.
///
/// El router decide a dónde ir cuando el arranque se resuelve; esta pantalla
/// solo espera y no navega por su cuenta.
///
/// Tiene un tiempo mínimo en pantalla (`StartupNotifier.minimoEnSplash`). Sin
/// él la lectura del storage tarda ~200 ms y esto era un parpadeo: la animación
/// no llegaba a verse nunca.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BrandGradient(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _LogoConPulso(),
                      const SizedBox(height: DesignTokens.space4 + 2),
                      const FadeUp(
                        child: Text(
                          'ENAM Prep',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: DesignTokens.space4 + 2),
                      const _EcgAnimado(),
                      const SizedBox(height: DesignTokens.space4 + 2),
                      FadeUp(
                        delay: const Duration(milliseconds: 250),
                        child: Text(
                          'Tu preparación para el ENAM',
                          style: TextStyle(
                            fontSize: 13.5,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: DesignTokens.space12 + 8),
                child: _BarraIndeterminada(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// El logo en "vidrio", latiendo con un halo que se expande y se desvanece.
class _LogoConPulso extends StatefulWidget {
  const _LogoConPulso();

  @override
  State<_LogoConPulso> createState() => _LogoConPulsoState();
}

class _LogoConPulsoState extends State<_LogoConPulso>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
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
    const caja = SizedBox(
      width: 104,
      height: 104,
      child: Center(
        child: Icon(Symbols.stethoscope, size: 54, fill: 1, color: Colors.white),
      ),
    );

    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        // Un solo ciclo: crece hasta la mitad y vuelve.
        final t = _c.value;
        final vaiven = (t < 0.5 ? t : 1 - t) * 2;
        final escala = 1 + 0.05 * vaiven;

        return Transform.scale(
          scale: escala,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                // El halo crece de 0 a 16 px mientras se desvanece.
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.3 * (1 - vaiven)),
                  spreadRadius: 16 * vaiven,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: caja,
    );
  }
}

/// El electrocardiograma, con un segmento que recorre el trazo en bucle.
class _EcgAnimado extends StatefulWidget {
  const _EcgAnimado();

  @override
  State<_EcgAnimado> createState() => _EcgAnimadoState();
}

class _EcgAnimadoState extends State<_EcgAnimado>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
      width: 220,
      height: 30,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => CustomPaint(
          painter: _EcgPainter(
            avance: _c.value,
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
  const _EcgPainter({required this.avance, required this.estatico});

  final double avance;
  final bool estatico;

  /// Trazo del diseño, sobre un lienzo de 220 × 30.
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
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (estatico) {
      canvas.drawPath(trazo, pincel);
      return;
    }

    // Un segmento de 70 px que recorre el trazo, como el `stroke-dasharray`
    // del diseño. `PathMetrics` da la longitud real para poder extraerlo.
    final metrica = trazo.computeMetrics().first;
    const largoSegmento = 70.0;
    final recorrido = metrica.length + largoSegmento;
    final fin = avance * recorrido;
    final inicio = fin - largoSegmento;

    canvas.drawPath(
      metrica.extractPath(inicio.clamp(0, metrica.length), fin.clamp(0, metrica.length)),
      pincel,
    );
  }

  @override
  bool shouldRepaint(_EcgPainter old) =>
      old.avance != avance || old.estatico != estatico;
}

/// Barra de progreso indeterminada: un bloque que cruza de lado a lado.
class _BarraIndeterminada extends StatefulWidget {
  const _BarraIndeterminada();

  @override
  State<_BarraIndeterminada> createState() => _BarraIndeterminadaState();
}

class _BarraIndeterminadaState extends State<_BarraIndeterminada>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!Motion.reduced(context) && !_c.isAnimating) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const ancho = 130.0;
    const anchoBloque = ancho * 0.45;

    return SizedBox(
      width: ancho,
      height: 4,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: ColoredBox(
          color: Colors.white.withValues(alpha: 0.25),
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, child) {
              final t = Curves.easeInOut.transform(_c.value);
              return Transform.translate(
                // De fuera por la izquierda a fuera por la derecha.
                offset: Offset(-anchoBloque + t * (ancho + anchoBloque), 0),
                child: child,
              );
            },
            child: Container(
              width: anchoBloque,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
