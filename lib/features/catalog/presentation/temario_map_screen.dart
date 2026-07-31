import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/domain/taxonomy.dart';
import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/state_colors.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/state_banner.dart';
import '../domain/catalog_models.dart';
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
      backgroundColor: context.scheme.surfaceContainerLowest,
      body: Column(
        children: [
          const _CabeceraTemario(),
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

/// Cabecera en degradado con el buscador dentro, como en el diseño.
///
/// El buscador va aquí y no detrás de un icono de lupa: es la vía rápida para
/// quien ya sabe qué busca, y esconderlo lo vuelve invisible.
class _CabeceraTemario extends StatelessWidget {
  const _CabeceraTemario();

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(-0.26, -1),
          end: const Alignment(0.26, 1),
          colors: oscuro
              ? DesignTokens.headerGradientDark
              : DesignTokens.headerGradientLight,
          stops: DesignTokens.headerGradientStops,
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(DesignTokens.radiusXl),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned(
            top: -70,
            right: -70,
            child: _CirculoDecorativo(tamano: 190, opacidad: 0.10),
          ),
          const Positioned(
            bottom: -60,
            left: -50,
            child: _CirculoDecorativo(tamano: 140, opacidad: 0.07),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.space5,
                DesignTokens.space1,
                DesignTokens.space5,
                DesignTokens.space3,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Temario oficial',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.space2),
                  _BuscadorFalso(
                    onTap: () => context.push(Routes.temarioSearch),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CirculoDecorativo extends StatelessWidget {
  const _CirculoDecorativo({required this.tamano, required this.opacidad});

  final double tamano;
  final double opacidad;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: tamano,
        height: tamano,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: opacidad),
        ),
      ),
    );
  }
}

/// Campo de búsqueda que no acepta texto: al tocarlo abre la pantalla 3.6.
///
/// Escribir aquí y luego perder lo escrito al navegar sería peor que no
/// dejar escribir: así el foco y el teclado aparecen ya en la pantalla final.
class _BuscadorFalso extends StatelessWidget {
  const _BuscadorFalso({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Buscar en el temario',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(21),
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(21),
          ),
          child: Row(
            children: [
              const Icon(Symbols.search, size: 21, color: Colors.white),
              const SizedBox(width: DesignTokens.space2 + 2),
              // Expanded y no un Text suelto: a 360 px con la fuente del
              // sistema ampliada, la pista se sale de la píldora.
              Expanded(
                child: Text(
                  'Busca: "glaucoma", "parto"…',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapaContenido extends ConsumerWidget {
  const _MapaContenido();

  /// Umbral para agrupar áreas en la lista compacta.
  static const _pesoCompacto = 15;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final porGrupo = ref.watch(areasPorGrupoProvider);
    if (porGrupo == null) return const SizedBox.shrink();

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(catalogProvider),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          DesignTokens.space5,
          DesignTokens.space2,
          DesignTokens.space5,
          DesignTokens.space8,
        ),
        children: [
          const _Curiosidad(),
          for (final grupo in AreaGroup.values) ...[
            const SizedBox(height: DesignTokens.space2),
            _GrupoHeader(grupo: grupo),
            const SizedBox(height: DesignTokens.space2),
            ..._areasDelGrupo(context, porGrupo[grupo]!),
          ],
        ],
      ),
    );
  }

  /// Reparte las áreas del grupo entre tarjetas propias y la lista compacta.
  ///
  /// El corte no es estético: cuatro áreas de 2 a 14 preguntas con tarjeta
  /// propia ocuparían más pantalla que Medicina, que vale veinte veces más, y
  /// el mapa dejaría de decir dónde está el examen.
  List<Widget> _areasDelGrupo(BuildContext context, List<CatalogNode> areas) {
    final grandes = areas.where((a) => (a.peso ?? 0) >= _pesoCompacto).toList();
    final compactas = areas
        .where((a) => (a.peso ?? 0) < _pesoCompacto)
        .toList();

    return [
      for (var i = 0; i < grandes.length; i++) ...[
        if (i > 0) const SizedBox(height: DesignTokens.space2),
        AreaCard(
          nodo: grandes[i],
          index: i,
          onTap: () => context.push(Routes.temarioAreaOf(grandes[i].id)),
        ),
      ],
      if (compactas.isNotEmpty) ...[
        if (grandes.isNotEmpty) const SizedBox(height: DesignTokens.space2),
        GroupedCard(
          index: grandes.length,
          children: [
            for (var i = 0; i < compactas.length; i++)
              AreaCompactRow(
                nodo: compactas[i],
                ultima: i == compactas.length - 1,
                // Ciencias Básicas rinde cuatro veces más por tema que
                // Medicina. Es el dato menos evidente del temario y el que más
                // cambia dónde conviene estudiar.
                destacado: compactas[i].id == 'ciencias-basicas'
                    ? 'Rinde 4×'
                    : null,
                onTap: () =>
                    context.push(Routes.temarioAreaOf(compactas[i].id)),
              ),
          ],
        ),
      ],
    ];
  }
}

/// Dato del temario que cambia dónde conviene estudiar.
///
/// Está arriba del todo porque es lo que alguien no descubre solo mirando la
/// lista: que un tema de Ciencias Básicas rinda cuatro veces más que uno de
/// Medicina no se ve en ninguna parte del documento oficial.
class _Curiosidad extends ConsumerWidget {
  const _Curiosidad();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final states = context.states;

    return FadeUp(
      child: InkWell(
        onTap: () => context.push(Routes.studyPriority),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd + 2),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space3,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: states.info.tint,
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd + 2),
          ),
          child: Row(
            children: [
              Icon(Symbols.bolt, size: 22, fill: 1, color: states.info.onTint),
              const SizedBox(width: DesignTokens.space2 + 2),
              Expanded(
                child: Text(
                  'Un tema de Ciencias Básicas rinde 4 veces más que uno de '
                  'Medicina.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                    color: context.scheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: DesignTokens.space2),
              Icon(Symbols.chevron_right, size: 20, color: states.info.onTint),
            ],
          ),
        ),
      ),
    );
  }
}

class _GrupoHeader extends ConsumerWidget {
  const _GrupoHeader({required this.grupo});

  final AreaGroup grupo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Las cifras salen del árbol que mandó el servidor, no del enum local: si
    // cambia un peso en la base de datos, la cabecera cambia con él.
    final totales = ref.watch(totalesPorGrupoProvider)?[grupo];
    if (totales == null) return const SizedBox.shrink();

    return FadeUp(
      child: Text(
        '${grupo.label.toUpperCase()} · ${totales.preguntas} PREGUNTAS · '
        '${(totales.porcentaje * 100).round()} %',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.77,
          color: context.scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _MapaCargando extends StatelessWidget {
  const _MapaCargando();

  @override
  Widget build(BuildContext context) {
    // Los esqueletos repiten los tres tamaños reales: si todos midieran igual,
    // el salto al cargar movería media pantalla.
    const altos = [44.0, 20.0, 92.0, 92.0, 58.0, 20.0, 58.0, 58.0];

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.space5,
        DesignTokens.space2,
        DesignTokens.space5,
        DesignTokens.space8,
      ),
      children: [
        for (final alto in altos)
          Padding(
            padding: const EdgeInsets.only(bottom: DesignTokens.space2),
            child: SkeletonBox(
              height: alto,
              width: alto == 20 ? 180 : null,
              radius: alto == 20 ? 6 : 16,
            ),
          ),
      ],
    );
  }
}
