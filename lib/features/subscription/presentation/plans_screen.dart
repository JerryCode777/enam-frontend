import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/domain/blueprint.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/state_colors.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/enam_button.dart';
import '../domain/subscription_models.dart';

/// Planes disponibles. Vienen del admin (RF-25); estos son los del rango que
/// sugiere el SSD (S/ 39-59 mensual, S/ 149-199 intensivo).
///
/// Faltan `GET /plans` conectado: hoy son fijos.
final plansProvider = Provider<List<Plan>>((ref) {
  return const [
    Plan(
      id: 'mensual',
      nombre: 'Premium mensual',
      precioCentimos: 4900,
      duracionDias: 30,
      beneficios: [
        'Banco completo y práctica ilimitada',
        'Simulacros de 180 y nacionales con ranking',
        'Estadísticas completas y nota proyectada',
        'Modo offline por áreas',
      ],
    ),
    Plan(
      id: 'intensivo',
      nombre: 'Intensivo pre-examen',
      precioCentimos: 16900,
      duracionDias: 90,
      beneficios: [
        'Todo lo del mensual',
        'Pago único, no se renueva solo',
      ],
    ),
  ];
});

/// Pantalla 7.1 — planes (RF-25).
///
/// La transparencia de precios es un diferenciador: el análisis competitivo del
/// SSD señala precios opacos en la competencia. Se muestra el precio en soles,
/// sin letra chica, y se dice qué sigue siendo gratis.
class PlansScreen extends ConsumerWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planes = ref.watch(plansProvider);
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isLight
                    ? DesignTokens.headerGradientLight
                    : DesignTokens.headerGradientDark,
                stops: DesignTokens.headerGradientStops,
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(DesignTokens.radiusXl),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.space5,
                  DesignTokens.space2,
                  DesignTokens.space5,
                  DesignTokens.space5,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: const Icon(Symbols.close, color: Colors.white),
                      tooltip: 'Cerrar',
                      // Cerrar devuelve donde estaba: nunca atrapa al usuario.
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(height: DesignTokens.space2),
                    Text(
                      'Prepárate sin límites',
                      style: context.texts.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        height: DesignTokens.lineHeightTight,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space2),
                    Text(
                      'Precios claros, en soles, sin sorpresas. Cancela cuando '
                      'quieras.',
                      style: context.texts.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.space5,
                DesignTokens.space4,
                DesignTokens.space5,
                DesignTokens.space8,
              ),
              children: [
                for (var i = 0; i < planes.length; i++) ...[
                  if (i > 0) const SizedBox(height: DesignTokens.space3 + 2),
                  _TarjetaPlan(
                    plan: planes[i],
                    destacado: i == 0,
                    index: i,
                  ),
                ],
                const SizedBox(height: DesignTokens.space4),
                const _PlanGratis(),
                const SizedBox(height: DesignTokens.space4),
                const _MediosDePago(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaPlan extends StatelessWidget {
  const _TarjetaPlan({
    required this.plan,
    required this.destacado,
    required this.index,
  });

  final Plan plan;
  final bool destacado;
  final int index;

  @override
  Widget build(BuildContext context) {
    final states = context.states;

    return FadeUp(
      index: index,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusXl - 4),
              side: BorderSide(
                color: destacado
                    ? context.scheme.primary
                    : context.scheme.outlineVariant,
                width: destacado ? 2 : 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(DesignTokens.space4 + 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          plan.nombre,
                          style: context.texts.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        'S/ ${plan.precio.toStringAsFixed(0)}',
                        style: context.texts.headlineMedium?.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: destacado
                              ? states.info.onTint
                              : context.scheme.onSurface,
                        ),
                      ),
                      Text(
                        plan.duracionDias <= 31
                            ? '/mes'
                            : ' · ${plan.duracionDias ~/ 30} meses',
                        style: context.texts.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (plan.duracionDias > 31) ...[
                    const SizedBox(height: DesignTokens.space1),
                    Text(
                      // El precio por mes hace comparable la oferta.
                      'Sale a S/ ${(plan.precio / (plan.duracionDias / 30)).round()} '
                      'al mes',
                      style: context.texts.bodySmall,
                    ),
                  ],
                  const SizedBox(height: DesignTokens.space3),
                  for (final b in plan.beneficios)
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: DesignTokens.space2,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Symbols.check,
                            size: 17,
                            color: states.success.onTint,
                          ),
                          const SizedBox(width: DesignTokens.space2),
                          Expanded(
                            child: Text(
                              b,
                              style: context.texts.bodyMedium?.copyWith(
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: DesignTokens.space3),
                  if (destacado)
                    EnamButton(
                      label: 'Elegir ${plan.nombre.split(" ").last}',
                      onPressed: () =>
                          context.push('${Routes.checkout}?plan=${plan.id}'),
                    )
                  else
                    EnamOutlinedButton(
                      label: 'Elegir ${plan.nombre.split(" ").first}',
                      height: 48,
                      onPressed: () =>
                          context.push('${Routes.checkout}?plan=${plan.id}'),
                    ),
                ],
              ),
            ),
          ),
          if (destacado)
            Positioned(
              top: -11,
              left: DesignTokens.space4 + 2,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.space2 + 2,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: DesignTokens.buttonGradient,
                  ),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSm + 1),
                ),
                child: Text(
                  'MÁS ELEGIDO',
                  style: context.texts.bodySmall?.copyWith(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Lo que el usuario conserva sin pagar. Evita el tono de castigo.
class _PlanGratis extends StatelessWidget {
  const _PlanGratis();

  @override
  Widget build(BuildContext context) {
    return FadeUp(
      index: 2,
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.space4),
        decoration: BoxDecoration(
          color: context.scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        ),
        child: Text.rich(
          TextSpan(
            style: context.texts.bodyMedium?.copyWith(height: 1.5),
            children: [
              const TextSpan(
                text: 'Tu plan gratis se mantiene: ',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const TextSpan(
                text:
                    '${Blueprint.freeDailyQuestionLimit} preguntas diarias y un '
                    'simulacro de muestra de '
                    '${Blueprint.sampleExamQuestions}, para siempre.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MediosDePago extends StatelessWidget {
  const _MediosDePago();

  @override
  Widget build(BuildContext context) {
    return FadeUp(
      index: 3,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Pagas con ',
            style: context.texts.bodySmall?.copyWith(fontSize: 11),
          ),
          Text(
            'Tarjeta · Yape · Plin',
            style: context.texts.bodySmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: context.scheme.onSurface,
            ),
          ),
          const SizedBox(width: DesignTokens.space2),
          Icon(
            Symbols.lock,
            size: 15,
            color: context.scheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
