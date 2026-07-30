import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/domain/blueprint.dart';
import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/state_colors.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../../shared/widgets/paywall_sheet.dart';
import '../../stats/domain/stats_models.dart';

/// Pantallas 5.1 y 5.9 — hub de simulacros e historial.
///
/// Individual autogenerado (RF-16) y nacional programado (RF-19). El de muestra
/// de 40 preguntas es la puerta del plan gratuito (RN-03).
class SimulacroHubScreen extends ConsumerWidget {
  const SimulacroHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardProvider).value;
    final esFree = stats?.esFree ?? true;

    return Scaffold(
      body: Column(
        children: [
          const GradientHeader(
            titulo: 'Simulacros',
            subtitulo: '180 preguntas · 3 horas · como el examen real',
            mostrarVolver: false,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.space4,
                DesignTokens.space4,
                DesignTokens.space4,
                DesignTokens.space8,
              ),
              children: [
                _TarjetaCompleto(esFree: esFree),
                const SizedBox(height: DesignTokens.space3),
                if (esFree) ...[
                  const _TarjetaMuestra(),
                  const SizedBox(height: DesignTokens.space3),
                ],
                const _TarjetaNacional(),
                const SizedBox(height: DesignTokens.space5),
                _Historial(evolucion: stats?.evolucion ?? const []),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaCompleto extends StatelessWidget {
  const _TarjetaCompleto({required this.esFree});

  final bool esFree;

  @override
  Widget build(BuildContext context) {
    final states = context.states;

    return FadeUp(
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          side: BorderSide(color: context.scheme.primary, width: 2),
        ),
        child: InkWell(
          onTap: () => esFree
              ? mostrarPaywall(
                  context,
                  motivo: PaywallMotivo.simulacroCompleto,
                )
              : context.push(Routes.simulacroInstructions),
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.space4 + 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Symbols.timer,
                      size: 26,
                      fill: 1,
                      color: states.info.onTint,
                    ),
                    const SizedBox(width: DesignTokens.space3),
                    Expanded(
                      child: Text(
                        'Simulacro completo',
                        style: context.texts.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (esFree)
                      Icon(
                        Symbols.lock,
                        size: 20,
                        color: context.scheme.onSurfaceVariant,
                      ),
                  ],
                ),
                const SizedBox(height: DesignTokens.space3),
                Text(
                  '${Blueprint.totalQuestions} preguntas con la proporción '
                  'exacta del blueprint oficial, en '
                  '${Blueprint.examDuration.inHours} horas. Calificación '
                  'vigesimal y desglose por área.',
                  style: context.texts.bodyMedium?.copyWith(height: 1.55),
                ),
                // Sin etiqueta "Parte de Premium": el simulacro se ofrece por
                // lo que es, y el límite aparece recién al tocarlo.
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TarjetaMuestra extends ConsumerWidget {
  const _TarjetaMuestra();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FadeUp(
      index: 1,
      child: Card(
        child: InkWell(
          onTap: () => context.push('${Routes.simulacroInstructions}?muestra=1'),
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.space4),
            child: Row(
              children: [
                Icon(
                  Symbols.assignment,
                  size: 24,
                  color: context.scheme.onSurfaceVariant,
                ),
                const SizedBox(width: DesignTokens.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Simulacro de muestra',
                        style: context.texts.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${Blueprint.sampleExamQuestions} preguntas · para '
                        'medirte en poco tiempo',
                        style: context.texts.bodySmall,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Symbols.chevron_right,
                  size: 20,
                  color: context.scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TarjetaNacional extends StatelessWidget {
  const _TarjetaNacional();

  @override
  Widget build(BuildContext context) {
    final states = context.states;

    return FadeUp(
      index: 2,
      child: Card(
        child: InkWell(
          onTap: () => context.push(Routes.nationalMock),
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.space4),
            child: Row(
              children: [
                Icon(
                  Symbols.campaign,
                  size: 24,
                  fill: 1,
                  color: states.warning.onTint,
                ),
                const SizedBox(width: DesignTokens.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Simulacro Nacional',
                        style: context.texts.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'dom 16 ago, 8:00 a.m. · 1,847 participantes',
                        style: context.texts.bodySmall,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Symbols.chevron_right,
                  size: 20,
                  color: context.scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Historial con la evolución de la nota (RF-20).
class _Historial extends StatelessWidget {
  const _Historial({required this.evolucion});

  final List<GradePoint> evolucion;

  @override
  Widget build(BuildContext context) {
    if (evolucion.isEmpty) {
      return FadeUp(
        index: 3,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.space5),
            child: Column(
              children: [
                Icon(
                  Symbols.monitoring,
                  size: 32,
                  color: context.scheme.onSurfaceVariant,
                ),
                const SizedBox(height: DesignTokens.space3),
                Text(
                  'Aún no rindes ningún simulacro',
                  style: context.texts.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: DesignTokens.space2),
                Text(
                  'Tu primera nota aparece aquí y entra al ranking.',
                  textAlign: TextAlign.center,
                  style: context.texts.bodySmall,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return FadeUp(
      index: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'TU HISTORIAL',
            style: context.texts.bodySmall?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: context.scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: DesignTokens.space3),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(DesignTokens.space4),
              child: Column(
                children: [
                  for (var i = evolucion.length - 1; i >= 0; i--)
                    _FilaHistorial(punto: evolucion[i], esUltimo: i == 0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaHistorial extends StatelessWidget {
  const _FilaHistorial({required this.punto, required this.esUltimo});

  final GradePoint punto;
  final bool esUltimo;

  @override
  Widget build(BuildContext context) {
    final states = context.states;
    final nota = punto.nota;
    final fecha = punto.fecha;
    final aprueba = Blueprint.isPassing(nota);

    return Padding(
      padding: EdgeInsets.only(bottom: esUltimo ? 0 : DesignTokens.space3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              DateFormat('d MMM yyyy', 'es').format(fecha),
              style: context.texts.bodyMedium,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.space2 + 1,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: aprueba ? states.success.tint : states.warning.tint,
              borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
            ),
            child: Text(
              // Siempre 2 decimales (RN-01).
              nota.toStringAsFixed(2),
              style: context.texts.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: aprueba ? states.success.onTint : states.warning.onTint,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
