import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/motion.dart';
import '../../../../core/theme/state_colors.dart';

/// Racha de días seguidos practicando.
///
/// Los siete puntos son la semana: los cumplidos van llenos y **hoy va con
/// borde**, sin rellenar. Es una invitación silenciosa —el hueco pide cerrarse—
/// y a la vez informa sin depender del color.
///
/// La llama late solo si el sistema permite movimiento. Es decoración pura: la
/// primera que sobra cuando alguien pidió reducirlo.
class StreakCard extends StatelessWidget {
  const StreakCard({
    required this.dias,
    required this.diasDeLaSemana,
    this.practicoHoy = false,
    super.key,
  });

  /// Días seguidos, en total.
  final int dias;

  /// Cuáles de los últimos 7 tuvieron práctica. El último es hoy.
  final List<bool> diasDeLaSemana;

  final bool practicoHoy;

  @override
  Widget build(BuildContext context) {
    final states = context.states;
    final sinRacha = dias == 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space4,
          vertical: DesignTokens.space3 + 1,
        ),
        child: Row(
          children: [
            _Llama(activa: !sinRacha),
            const SizedBox(width: DesignTokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sinRacha
                        ? 'Empieza tu racha hoy'
                        : 'Racha de $dias ${dias == 1 ? "día" : "días"}',
                    style: context.texts.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: context.scheme.onSurface,
                    ),
                  ),
                  Text(
                    sinRacha
                        ? 'Una sesión corta ya cuenta'
                        : practicoHoy
                        ? 'Ya practicaste hoy'
                        : 'Practica hoy para mantenerla',
                    style: context.texts.bodySmall?.copyWith(fontSize: 11.5),
                  ),
                ],
              ),
            ),
            const SizedBox(width: DesignTokens.space2),
            _Puntos(dias: diasDeLaSemana, color: states.success.base),
          ],
        ),
      ),
    );
  }
}

class _Llama extends StatefulWidget {
  const _Llama({required this.activa});

  final bool activa;

  @override
  State<_Llama> createState() => _LlamaState();
}

class _LlamaState extends State<_Llama> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context) || !widget.activa) {
      if (_c.isAnimating) _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final states = context.states;
    final apagada = !widget.activa;

    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Transform.scale(
        // Late suave: entre 1.0 y 1.16, como en el diseño.
        scale: 1 + _c.value * 0.16,
        child: Transform.rotate(angle: (_c.value - 0.5) * 0.07, child: child),
      ),
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.space2 + 1),
        decoration: BoxDecoration(
          color: apagada
              ? context.scheme.surfaceContainerHighest
              : states.warning.tint,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd + 1),
        ),
        child: Icon(
          Symbols.local_fire_department,
          size: 23,
          fill: apagada ? 0 : 1,
          color: apagada
              ? context.scheme.onSurfaceVariant
              : states.warning.onTint,
        ),
      ),
    );
  }
}

class _Puntos extends StatelessWidget {
  const _Puntos({required this.dias, required this.color});

  final List<bool> dias;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final states = context.states;

    return Semantics(
      label: '${dias.where((d) => d).length} de ${dias.length} días '
          'practicados esta semana',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < dias.length; i++) ...[
            if (i > 0) const SizedBox(width: 5),
            if (i == dias.length - 1 && !dias[i])
              // Hoy sin practicar: aro vacío. El hueco pide cerrarse.
              Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: states.warning.onTint, width: 2),
                ),
              )
            else
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dias[i] ? color : context.scheme.outlineVariant,
                ),
              ),
          ],
        ],
      ),
    );
  }
}
