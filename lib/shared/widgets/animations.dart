import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/motion.dart';

/// Aparece desvaneciéndose y subiendo unos pixeles.
///
/// Es la entrada por defecto de la app. Con [index] se escalona dentro de una
/// lista: cada elemento entra un poco después del anterior, hasta el tope de
/// [Motion.maxStaggerIndex] para que una lista de 120 temas no tarde segundos.
class FadeUp extends StatefulWidget {
  const FadeUp({
    required this.child,
    this.index = 0,
    this.delay = Duration.zero,
    this.offset = 10,
    super.key,
  });

  final Widget child;
  final int index;
  final Duration delay;

  /// Cuántos pixeles sube al entrar.
  final double offset;

  @override
  State<FadeUp> createState() => _FadeUpState();
}

class _FadeUpState extends State<FadeUp> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Motion.normal,
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _c,
    curve: Motion.enter,
  );

  bool _arrancado = false;
  Timer? _timer;

  // Se arranca aquí y no en initState porque hace falta el contexto para saber
  // si el sistema pidió reducir el movimiento.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_arrancado) return;
    _arrancado = true;

    // Con reduce-motion no se programa nada: ni temporizador ni ticker. Dejar
    // uno corriendo para después descartar su resultado gasta batería a cambio
    // de nada.
    if (Motion.reduced(context)) {
      _c.value = 1;
      return;
    }

    final escalon =
        Motion.stagger * widget.index.clamp(0, Motion.maxStaggerIndex);
    final espera = widget.delay + escalon;

    if (espera == Duration.zero) {
      unawaited(_c.forward());
    } else {
      _timer = Timer(espera, () {
        if (mounted) unawaited(_c.forward());
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Motion.reduced(context)) return widget.child;

    return AnimatedBuilder(
      animation: _fade,
      builder: (context, child) => Opacity(
        opacity: _fade.value,
        child: Transform.translate(
          offset: Offset(0, widget.offset * (1 - _fade.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// Envuelve los hijos de una lista con [FadeUp] escalonado.
///
/// Evita tener que llevar el índice a mano en cada `for`.
class StaggeredColumn extends StatelessWidget {
  const StaggeredColumn({
    required this.children,
    this.spacing = 0,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    super.key,
  });

  final List<Widget> children;
  final double spacing;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0 && spacing > 0) SizedBox(height: spacing),
          FadeUp(index: i, child: children[i]),
        ],
      ],
    );
  }
}

/// Un número que cuenta hasta su valor en vez de aparecer de golpe.
///
/// Se usa en la nota proyectada y en los resultados: ver el número subir
/// comunica progreso mejor que verlo ya puesto.
class AnimatedNumber extends StatelessWidget {
  const AnimatedNumber({
    required this.value,
    this.decimals = 2,
    this.suffix = '',
    this.style,
    this.duration,
    super.key,
  });

  final double value;
  final int decimals;
  final String suffix;
  final TextStyle? style;
  final Duration? duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: Motion.duration(context, duration ?? Motion.counter),
      curve: Motion.enter,
      builder: (context, v, _) => Text(
        '${v.toStringAsFixed(decimals)}$suffix',
        style: style,
      ),
    );
  }
}

/// Barra de progreso que crece hasta su valor al entrar.
class AnimatedBar extends StatelessWidget {
  const AnimatedBar({
    required this.value,
    required this.color,
    this.height = 10,
    this.background,
    this.duration,
    super.key,
  });

  /// De 0.0 a 1.0.
  final double value;
  final Color color;
  final double height;
  final Color? background;
  final Duration? duration;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
        duration: Motion.duration(context, duration ?? Motion.counter),
        curve: Motion.enter,
        builder: (context, v, _) => LinearProgressIndicator(
          value: v,
          minHeight: height,
          backgroundColor: background ?? Theme.of(context).colorScheme.outlineVariant,
          valueColor: AlwaysStoppedAnimation(color),
        ),
      ),
    );
  }
}

/// Anillo de progreso que se dibuja al entrar.
class AnimatedRing extends StatelessWidget {
  const AnimatedRing({
    required this.value,
    required this.color,
    required this.child,
    this.size = 64,
    this.stroke = 6,
    super.key,
  });

  /// De 0.0 a 1.0.
  final double value;
  final Color color;
  final Widget child;
  final double size;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
              duration: Motion.duration(context, Motion.counter),
              curve: Motion.enter,
              builder: (context, v, _) => CircularProgressIndicator(
                value: v,
                strokeWidth: stroke,
                strokeCap: StrokeCap.round,
                backgroundColor: Theme.of(context).colorScheme.outlineVariant,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// Efecto de brillo que recorre un bloque gris. Para los estados de carga.
///
/// Se detiene solo si el sistema pidió reducir el movimiento: en ese caso queda
/// el bloque gris, que sigue comunicando "cargando" sin animación.
class Shimmer extends StatefulWidget {
  const Shimmer({required this.child, super.key});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  // El ticker se arranca aquí, no en el inicializador del campo: con
  // reduce-motion no debe correr nunca. Un shimmer que repite indefinidamente
  // sin pintarse es el peor caso de gasto de batería.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) {
      if (_c.isAnimating) _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Motion.reduced(context)) return widget.child;

    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    final brillo = Theme.of(context).brightness == Brightness.light
        ? Colors.white.withValues(alpha: 0.55)
        : Colors.white.withValues(alpha: 0.06);

    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [base, brillo, base],
          // El punto de brillo recorre de izquierda a derecha y vuelve a entrar.
          stops: [
            (_c.value - 0.3).clamp(0.0, 1.0),
            _c.value.clamp(0.0, 1.0),
            (_c.value + 0.3).clamp(0.0, 1.0),
          ],
        ).createShader(bounds),
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// Bloque gris con shimmer, del tamaño que se le pida. Para armar esqueletos.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    this.width,
    this.height = 16,
    this.radius = 12,
    super.key,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

/// Rebote corto. Para confirmar una acción sin sacar al usuario de contexto:
/// marcar una pregunta, acertar una respuesta.
class Pop extends StatefulWidget {
  const Pop({required this.child, required this.trigger, super.key});

  final Widget child;

  /// Cada vez que este valor cambia, el rebote se dispara.
  final Object? trigger;

  @override
  State<Pop> createState() => _PopState();
}

class _PopState extends State<Pop> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Motion.fast,
    lowerBound: 0,
    upperBound: 0.18,
  );

  @override
  void didUpdateWidget(Pop old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger && !Motion.reduced(context)) {
      unawaited(_c.forward().then((_) => _c.reverse()));
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) =>
          Transform.scale(scale: 1 + _c.value, child: child),
      child: widget.child,
    );
  }
}
