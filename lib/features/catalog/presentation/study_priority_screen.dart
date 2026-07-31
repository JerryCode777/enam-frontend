import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/area_colors.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/state_colors.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../domain/catalog_models.dart';
import 'catalog_providers.dart';

/// Pantalla 3.7 — dónde invertir tu tiempo.
///
/// Es el argumento de valor de la app frente a estudiar con un PDF. Cruza tres
/// cosas que por separado engañan:
///
/// - **Peso**: acertar 90 % en Ética (2 preguntas) no mueve la nota
/// - **Brecha**: cuánto le falta al usuario en esa área
/// - **Densidad**: en Ciencias Básicas 7 temas producen 10 preguntas; en
///   Medicina hacen falta 123 para 40. Un tema de Básicas rinde ~4 veces más
///
/// El orden sale de multiplicar los tres, no de mirar solo el acierto.
class StudyPriorityScreen extends ConsumerWidget {
  const StudyPriorityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prioridades = ref.watch(prioridadEstudioProvider);

    return Scaffold(
      body: Column(
        children: [
          const GradientHeader(
            titulo: 'Dónde invertir tu tiempo',
            subtitulo: 'Peso en el examen × lo que te falta × cuánto rinde',
          ),
          Expanded(
            child: prioridades.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      DesignTokens.space4,
                      DesignTokens.space4,
                      DesignTokens.space4,
                      DesignTokens.space8,
                    ),
                    children: [
                      const _Explicacion(),
                      const SizedBox(height: DesignTokens.space5),
                      for (var i = 0; i < prioridades.length; i++) ...[
                        if (i > 0) const SizedBox(height: DesignTokens.space3),
                        _PrioridadCard(
                          area: prioridades[i].area,
                          posicion: i + 1,
                          index: i,
                          esPrimera: i == 0,
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Explicacion extends StatelessWidget {
  const _Explicacion();

  @override
  Widget build(BuildContext context) {
    final states = context.states;

    return FadeUp(
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.space4),
        decoration: BoxDecoration(
          color: states.info.tint,
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Symbols.bolt,
                  size: 22,
                  fill: 1,
                  color: states.info.onTint,
                ),
                const SizedBox(width: DesignTokens.space2 + 2),
                Expanded(
                  child: Text(
                    'No todo el temario rinde igual',
                    style: context.texts.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: context.scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.space3),
            Text(
              // El ejemplo concreto comunica más que la fórmula.
              'Ciencias Básicas tiene 7 temas y aporta 10 preguntas al examen. '
              'Medicina tiene 123 temas y aporta 40. Estudiar un tema de '
              'Básicas rinde unas cuatro veces más que uno de Medicina.',
              style: context.texts.bodyMedium?.copyWith(
                height: 1.55,
                color: states.info.onTint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrioridadCard extends StatelessWidget {
  const _PrioridadCard({
    required this.area,
    required this.posicion,
    required this.index,
    required this.esPrimera,
  });

  final CatalogNode area;
  final int posicion;
  final int index;
  final bool esPrimera;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final states = context.states;
    final color = AreaColors.of(area.id, Theme.of(context).brightness);
    final acierto = area.porcentajeAcierto;
    final densidad = area.temasPorPregunta;

    return FadeUp(
      index: index,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          side: BorderSide(
            // La primera se destaca con borde, no solo con posición.
            color: esPrimera ? scheme.primary : scheme.outlineVariant,
            width: esPrimera ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: () => context.push(Routes.temarioAreaOf(area.id)),
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.space4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$posicion',
                        style: context.texts.bodySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(width: DesignTokens.space3),
                    Expanded(
                      child: Text(
                        area.nombre,
                        style: context.texts.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (esPrimera)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignTokens.space2 + 1,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: states.warning.tint,
                          borderRadius: BorderRadius.circular(
                            DesignTokens.radiusSm + 1,
                          ),
                        ),
                        child: Text(
                          'EMPIEZA AQUÍ',
                          style: context.texts.bodySmall?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: states.warning.onTint,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: DesignTokens.space3),
                AnimatedBar(value: acierto ?? 0, color: color, height: 8),
                const SizedBox(height: DesignTokens.space3),
                Wrap(
                  spacing: DesignTokens.space4,
                  runSpacing: DesignTokens.space1,
                  children: [
                    _Dato(etiqueta: 'pesa', valor: '${area.peso} de 180'),
                    _Dato(
                      etiqueta: 'tu acierto',
                      valor: acierto == null
                          ? 'sin datos'
                          : '${(acierto * 100).round()} %',
                    ),
                    if (densidad != null)
                      _Dato(
                        etiqueta: 'temas por pregunta',
                        valor: densidad.toStringAsFixed(1),
                      ),
                  ],
                ),
                const SizedBox(height: DesignTokens.space3),
                Text(
                  _porQue(area, acierto, densidad),
                  style: context.texts.bodySmall?.copyWith(height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Explica en una frase por qué el área está en esa posición. Sin esto, el
  /// orden se lee como una caja negra.
  static String _porQue(CatalogNode area, double? acierto, double? densidad) {
    final peso = area.peso ?? 0;
    final partes = <String>[];

    if (peso >= 30) {
      partes.add('es de las áreas más grandes del examen');
    } else if (peso <= 2) {
      partes.add('aporta pocas preguntas');
    }

    if (acierto != null && acierto < 0.5) {
      partes.add('vas por debajo del 50 %');
    } else if (acierto != null && acierto >= 0.75) {
      partes.add('ya la manejas bien');
    }

    if (densidad != null && densidad < 1.2) {
      partes.add('y su temario es corto para lo que rinde');
    }

    if (partes.isEmpty) return 'Avance intermedio, sin urgencia.';
    return '${partes.first[0].toUpperCase()}${partes.first.substring(1)}'
        '${partes.length > 1 ? ", ${partes.skip(1).join(", ")}" : ""}.';
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$etiqueta ',
          style: context.texts.bodySmall?.copyWith(fontSize: 13),
        ),
        Text(
          valor,
          style: context.texts.bodySmall?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: context.scheme.onSurface,
          ),
        ),
      ],
    );
  }
}
