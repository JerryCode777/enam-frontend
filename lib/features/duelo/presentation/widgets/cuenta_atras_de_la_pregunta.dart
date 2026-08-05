import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/state_colors.dart';

/// El cronómetro de la pregunta.
///
/// # Por qué cuenta contra una fecha y no resta de un total
///
/// El servidor manda la **hora exacta de cierre**, no «te quedan 20 segundos».
/// Con los segundos restantes, el retraso de la red se convertiría en ventaja
/// para quien tenga mejor conexión: el que recibe el mensaje 300 ms más tarde
/// empezaría a contar 300 ms más tarde y jugaría con más tiempo.
///
/// Contra una fecha absoluta, los dos cuentan hacia el mismo instante y la red
/// deja de importar. Lo que se pinta aquí es un dibujo; la verdad la tiene el
/// servidor, que cierra la pregunta cuando toca pase lo que pase.
class CuentaAtrasDeLaPregunta extends StatefulWidget {
  const CuentaAtrasDeLaPregunta({
    required this.cierraEn,
    required this.segundos,
    super.key,
  });

  final DateTime cierraEn;

  /// Los segundos que daba esta pregunta, para pintar la barra completa.
  final int segundos;

  @override
  State<CuentaAtrasDeLaPregunta> createState() =>
      _CuentaAtrasDeLaPreguntaState();
}

class _CuentaAtrasDeLaPreguntaState extends State<CuentaAtrasDeLaPregunta> {
  Timer? _reloj;
  Duration _restante = Duration.zero;

  @override
  void initState() {
    super.initState();
    _recalcular();
    // Diez veces por segundo: la barra se mueve suave y el número no salta.
    _reloj = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => _recalcular(),
    );
  }

  @override
  void didUpdateWidget(covariant CuentaAtrasDeLaPregunta anterior) {
    super.didUpdateWidget(anterior);
    // Pregunta nueva: el reloj tiene que saltar al instante, sin esperar al
    // siguiente tic.
    if (anterior.cierraEn != widget.cierraEn) _recalcular();
  }

  void _recalcular() {
    final falta = widget.cierraEn.difference(DateTime.now().toUtc());
    final acotado = falta.isNegative ? Duration.zero : falta;
    if (!mounted) return;
    if (acotado != _restante) setState(() => _restante = acotado);
  }

  @override
  void dispose() {
    _reloj?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final segundos = (_restante.inMilliseconds / 1000).ceil();

    // Los últimos cinco en rojo. Es el aviso que se ve sin leer el número, y
    // llega a tiempo de cambiar una respuesta.
    final apremia = segundos <= 5;
    final color = apremia ? context.states.error.base : scheme.primary;

    final proporcion = widget.segundos <= 0
        ? 0.0
        : (_restante.inMilliseconds / (widget.segundos * 1000)).clamp(0.0, 1.0);

    return Semantics(
      liveRegion: apremia,
      label: 'Quedan $segundos segundos',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$segundos',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: DesignTokens.space1),
              Text(
                's',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space2),
          ClipRRect(
            borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
            child: LinearProgressIndicator(
              value: proporcion,
              minHeight: 6,
              backgroundColor: scheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}
