import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/domain/hora_peru.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/motion.dart';
import '../../../../core/theme/state_colors.dart';

/// Racha de días seguidos practicando.
///
/// El número manda: es el dato que la persona viene a mirar y el que duele
/// perder. Debajo, la semana completa con la inicial de cada día — ver seis
/// días llenos y un hueco al final pide cerrarlo mucho más que siete puntos
/// sin contexto, que era lo que había antes y no significaba nada.
///
/// La llama late con halo solo si el sistema permite movimiento. Es decoración:
/// la primera que sobra cuando alguien pidió reducirlo.
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
    final scheme = context.scheme;
    final sinRacha = dias == 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space4,
          vertical: DesignTokens.space4,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _Llama(activa: !sinRacha),
                const SizedBox(width: DesignTokens.space3 + 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // El número, grande. Es lo que se viene a mirar.
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$dias',
                            style: context.texts.displaySmall?.copyWith(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              height: 1,
                              color: sinRacha
                                  ? scheme.onSurfaceVariant
                                  : states.warning.onTint,
                            ),
                          ),
                          const SizedBox(width: DesignTokens.space1 + 2),
                          Text(
                            dias == 1 ? 'día' : 'días',
                            style: context.texts.bodyLarge?.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: sinRacha
                                  ? scheme.onSurfaceVariant
                                  : states.warning.onTint,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sinRacha
                            ? 'Empieza tu racha hoy'
                            : practicoHoy
                            ? 'Ya practicaste hoy'
                            : 'Practica hoy para mantenerla',
                        style: context.texts.bodySmall?.copyWith(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.space4),
            _Semana(dias: diasDeLaSemana),
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
      builder: (context, child) {
        // Halo que se expande y se apaga, acompañando al latido.
        final halo = apagada
            ? const <BoxShadow>[]
            : [
                BoxShadow(
                  color: states.warning.base.withValues(
                    alpha: 0.35 * (1 - _c.value),
                  ),
                  spreadRadius: _c.value * 12,
                ),
              ];

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            boxShadow: halo,
          ),
          child: Transform.scale(
            scale: 1 + _c.value * 0.1,
            child: child,
          ),
        );
      },
      child: Container(
        width: 58,
        height: 58,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: apagada
              ? context.scheme.surfaceContainerHighest
              : states.warning.tint,
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        ),
        child: Icon(
          Symbols.local_fire_department,
          size: 34,
          fill: apagada ? 0 : 1,
          color: apagada
              ? context.scheme.onSurfaceVariant
              : states.warning.onTint,
        ),
      ),
    );
  }
}

/// La semana con la inicial de cada día.
///
/// Las iniciales importan: un punto suelto no dice nada, pero ver que el hueco
/// es **hoy** —y que los seis anteriores están llenos— es lo que empuja a
/// abrir una sesión.
class _Semana extends StatefulWidget {
  const _Semana({required this.dias});

  /// Últimos 7 días; el último es hoy.
  final List<bool> dias;

  @override
  State<_Semana> createState() => _SemanaState();
}

class _SemanaState extends State<_Semana> with TickerProviderStateMixin {
  /// Separación entre la entrada de un día y la del siguiente.
  static const _escalon = Duration(milliseconds: 70);
  static const _pop = Duration(milliseconds: 400);

  late final AnimationController _entrada = AnimationController(
    vsync: this,
    duration: _pop + _escalon * widget.dias.length,
  );

  late final AnimationController _hoy = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Motion.reduced(context)) {
      _entrada.value = 1;
      if (_hoy.isAnimating) _hoy.stop();
    } else {
      if (!_entrada.isAnimating && _entrada.value == 0) _entrada.forward();
      if (!_hoy.isAnimating) _hoy.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _entrada.dispose();
    _hoy.dispose();
    super.dispose();
  }

  Animation<double> _curva(int i) {
    final total = _entrada.duration!.inMilliseconds;
    final inicio = (_escalon * i).inMilliseconds / total;
    final fin = inicio + _pop.inMilliseconds / total;
    return CurvedAnimation(
      parent: _entrada,
      curve: Interval(inicio, fin.clamp(0.0, 1.0), curve: Curves.easeOutBack),
    );
  }

  /// Inicial del día que ocupa la posición [i], contando hacia atrás desde hoy.
  ///
  /// En hora de PERÚ, no la del dispositivo: el servidor arma esta semana con
  /// el calendario peruano, y etiquetarla con otro reloj desplazaría las letras
  /// un día respecto a los círculos. Ver `core/domain/hora_peru.dart`.
  static String _inicial(int i, int total) {
    const iniciales = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    return iniciales[diaDeLaSemanaEnPeru(total - 1 - i) - 1];
  }

  @override
  Widget build(BuildContext context) {
    final states = context.states;
    final scheme = context.scheme;
    final dias = widget.dias;

    return Semantics(
      label: '${dias.where((d) => d).length} de ${dias.length} días '
          'practicados esta semana',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var i = 0; i < dias.length; i++)
            _Dia(
              inicial: _inicial(i, dias.length),
              cumplido: dias[i],
              esHoy: i == dias.length - 1,
              entrada: _curva(i),
              latido: _hoy,
              colorCumplido: states.success.base,
              colorHoy: states.warning.onTint,
              scheme: scheme,
            ),
        ],
      ),
    );
  }
}

class _Dia extends StatelessWidget {
  const _Dia({
    required this.inicial,
    required this.cumplido,
    required this.esHoy,
    required this.entrada,
    required this.latido,
    required this.colorCumplido,
    required this.colorHoy,
    required this.scheme,
  });

  final String inicial;
  final bool cumplido;
  final bool esHoy;
  final Animation<double> entrada;
  final Animation<double> latido;
  final Color colorCumplido;
  final Color colorHoy;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    // Hoy sin cumplir: aro que late. El hueco pide cerrarse.
    final pendienteHoy = esHoy && !cumplido;

    Widget circulo = Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cumplido ? colorCumplido : Colors.transparent,
        border: cumplido
            ? null
            : Border.all(
                color: pendienteHoy ? colorHoy : scheme.outlineVariant,
                width: 2,
              ),
      ),
      child: cumplido
          ? const Icon(Symbols.check, size: 17, fill: 1, color: Colors.white)
          : null,
    );

    if (pendienteHoy) {
      circulo = AnimatedBuilder(
        animation: latido,
        builder: (context, child) =>
            Transform.scale(scale: 1 + latido.value * 0.12, child: child),
        child: circulo,
      );
    }

    return Column(
      children: [
        Text(
          inicial,
          style: context.texts.bodySmall?.copyWith(
            fontSize: 12,
            fontWeight: esHoy ? FontWeight.w800 : FontWeight.w600,
            color: esHoy ? scheme.onSurface : scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: DesignTokens.space1 + 2),
        ScaleTransition(scale: entrada, child: circulo),
      ],
    );
  }
}
