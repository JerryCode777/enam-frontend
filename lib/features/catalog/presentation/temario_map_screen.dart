import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/domain/blueprint.dart';
import '../../../core/domain/taxonomy.dart';
import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/state_colors.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../../shared/widgets/state_banner.dart';
import 'catalog_providers.dart';
import 'widgets/node_card.dart';

/// Pantalla 3.1 — mapa del temario (RF-36).
///
/// Las 10 áreas agrupadas en los tres grupos oficiales. El peso de cada área es
/// visible porque es la información que hace falta para decidir: 40 preguntas y
/// 2 preguntas no pueden verse igual.
class TemarioMapScreen extends ConsumerWidget {
  const TemarioMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arbol = ref.watch(catalogProvider);

    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            titulo: 'Temario',
            subtitulo: 'Tabla de Especificaciones de ASPEFAM',
            mostrarVolver: false,
            acciones: [
              IconButton(
                icon: const Icon(Symbols.search, color: Colors.white),
                tooltip: 'Buscar en el temario',
                onPressed: () => context.push(Routes.temarioSearch),
              ),
            ],
          ),
          Expanded(
            child: arbol.when(
              loading: () => const _MapaCargando(),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(DesignTokens.space4),
                  child: StateBanner(
                    kind: BannerKind.error,
                    message: 'No pudimos cargar el temario.',
                    action: TextButton(
                      onPressed: () => ref.invalidate(catalogProvider),
                      child: const Text('Reintentar'),
                    ),
                  ),
                ),
              ),
              data: (_) => const _MapaContenido(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapaContenido extends ConsumerWidget {
  const _MapaContenido();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final porGrupo = ref.watch(areasPorGrupoProvider);
    if (porGrupo == null) return const SizedBox.shrink();

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(catalogProvider),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          DesignTokens.space4,
          DesignTokens.space4,
          DesignTokens.space4,
          DesignTokens.space8,
        ),
        children: [
          const _ResumenExamen(),
          const SizedBox(height: DesignTokens.space5),
          for (final grupo in AreaGroup.values) ...[
            _GrupoHeader(grupo: grupo),
            const SizedBox(height: DesignTokens.space3),
            for (var i = 0; i < porGrupo[grupo]!.length; i++) ...[
              if (i > 0) const SizedBox(height: DesignTokens.space3),
              NodeCard(
                nodo: porGrupo[grupo]![i],
                index: i,
                // Escala contra Medicina, el área más grande: así el ancho de
                // cada barra comunica el peso relativo real.
                pesoMaximo: 40,
                onTap: () => context.push(
                  Routes.temarioAreaOf(porGrupo[grupo]![i].id),
                ),
                onPracticar: () => context.push(
                  '${Routes.practiceConfig}?nodo=${porGrupo[grupo]![i].id}',
                ),
              ),
            ],
            const SizedBox(height: DesignTokens.space6),
          ],
        ],
      ),
    );
  }
}

/// Recordatorio de la estructura del examen. Ancla lo que se está viendo.
class _ResumenExamen extends StatelessWidget {
  const _ResumenExamen();

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
        child: Row(
          children: [
            Icon(Symbols.school, size: 24, fill: 1, color: states.info.onTint),
            const SizedBox(width: DesignTokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${Blueprint.totalQuestions} preguntas · '
                    '${Blueprint.examDuration.inHours} horas',
                    style: context.texts.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: context.scheme.onSurface,
                    ),
                  ),
                  Text(
                    'Se aprueba con ${Blueprint.passingGrade.toStringAsFixed(2)}. '
                    'Sin puntaje en contra.',
                    style: context.texts.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GrupoHeader extends StatelessWidget {
  const _GrupoHeader({required this.grupo});

  final AreaGroup grupo;

  @override
  Widget build(BuildContext context) {
    return FadeUp(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              grupo.label.toUpperCase(),
              style: context.texts.bodySmall?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: context.scheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            '${grupo.preguntas} preguntas · '
            '${(grupo.porcentaje * 100).round()} %',
            style: context.texts.bodySmall?.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _MapaCargando extends StatelessWidget {
  const _MapaCargando();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(DesignTokens.space4),
      children: [
        const SkeletonBox(height: 76, radius: DesignTokens.radiusLg),
        const SizedBox(height: DesignTokens.space5),
        for (var i = 0; i < 5; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: DesignTokens.space3),
            child: SkeletonBox(
              height: i == 0 ? 20 : 132,
              width: i == 0 ? 140 : null,
              radius: i == 0 ? 6 : DesignTokens.radiusLg,
            ),
          ),
      ],
    );
  }
}
