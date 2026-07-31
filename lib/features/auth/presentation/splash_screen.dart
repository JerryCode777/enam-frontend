import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/motion.dart';
import '../../../shared/widgets/brand_mark.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/brand_gradient.dart';
import '../../../shared/widgets/ecg_line.dart';

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
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: DesignTokens.space4 + 2),
                      const EcgLine(),
                      const SizedBox(height: DesignTokens.space4 + 2),
                      FadeUp(
                        delay: const Duration(milliseconds: 250),
                        child: Text(
                          'Tu preparación para el ENAM',
                          style: TextStyle(
                            fontSize: 15,
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
      child: Center(child: BrandMark(size: 60)),
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
