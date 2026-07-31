import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/area_colors.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/state_colors.dart';
import '../../../shared/widgets/animations.dart';
import '../domain/catalog_models.dart';
import 'catalog_providers.dart';
import 'widgets/node_card.dart';

/// Pantalla 3.6 — búsqueda del temario (RF-41).
///
/// El caso que importa: alguien busca "glaucoma" u "oftalmología" y tiene que
/// encontrarlo **dentro de Cirugía**, no como área propia. Por eso cada
/// resultado muestra su ruta completa: sin ella, el hallazgo desorienta más de
/// lo que ayuda.
class TemarioSearchScreen extends ConsumerStatefulWidget {
  const TemarioSearchScreen({super.key});

  @override
  ConsumerState<TemarioSearchScreen> createState() =>
      _TemarioSearchScreenState();
}

class _TemarioSearchScreenState extends ConsumerState<TemarioSearchScreen> {
  final _controller = TextEditingController();

  /// Sugerencias de arranque. Son casos reales donde el temario oficial no está
  /// donde uno lo buscaría.
  static const _sugerencias = [
    'glaucoma',
    'tuberculosis',
    'preeclampsia',
    'shock',
    'otitis',
  ];

  @override
  void initState() {
    super.initState();
    _controller.text = ref.read(catalogSearchProvider);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _buscar(String texto) {
    _controller.text = texto;
    ref.read(catalogSearchProvider.notifier).set(texto);
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(catalogSearchProvider);
    final resultados = ref.watch(catalogSearchResultsProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Buscar tema, sub área o área',
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Symbols.close),
                    tooltip: 'Limpiar',
                    onPressed: () {
                      _controller.clear();
                      ref.read(catalogSearchProvider.notifier).clear();
                    },
                  ),
          ),
          onChanged: ref.read(catalogSearchProvider.notifier).set,
        ),
      ),
      body: switch (query.trim().length) {
        0 => _Sugerencias(sugerencias: _sugerencias, onTap: _buscar),
        1 => const _EscribeMas(),
        _ when resultados.isEmpty => _SinResultados(query: query),
        _ => _Resultados(resultados: resultados),
      },
    );
  }
}

class _Resultados extends StatelessWidget {
  const _Resultados({required this.resultados});

  final List<NodoConRuta> resultados;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(DesignTokens.space4),
      itemCount: resultados.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: DesignTokens.space2),
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: DesignTokens.space2),
            child: Text(
              '${resultados.length} '
              '${resultados.length == 1 ? "resultado" : "resultados"}',
              style: context.texts.bodySmall,
            ),
          );
        }
        final r = resultados[i - 1];
        return _ResultadoTile(resultado: r, index: i - 1);
      },
    );
  }
}

class _ResultadoTile extends StatelessWidget {
  const _ResultadoTile({required this.resultado, required this.index});

  final NodoConRuta resultado;
  final int index;

  @override
  Widget build(BuildContext context) {
    final nodo = resultado.nodo;
    final ruta = resultado.ruta;
    final sinContenido = nodo.estado == NodeState.sinContenido;

    // La ruta sin el propio nodo: "Cirugía › Problemas en oftalmología".
    final migas = ruta.length > 1
        ? ruta.take(ruta.length - 1).map((n) => n.nombre).join(' › ')
        : null;

    final colorArea = ruta.isEmpty
        ? context.scheme.primary
        : AreaColors.of(ruta.first.id, Theme.of(context).brightness);

    return FadeUp(
      index: index,
      child: Card(
        child: InkWell(
          onTap: sinContenido
              ? null
              : () => context.push(
                  nodo.tieneHijos
                      ? Routes.temarioAreaOf(nodo.id)
                      : '${Routes.practiceConfig}?nodo=${nodo.id}',
                ),
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.space4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 5),
                  decoration: BoxDecoration(
                    color: colorArea,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: DesignTokens.space2 + 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nodo.nombre,
                        style: context.texts.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (migas != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          migas,
                          style: context.texts.bodySmall?.copyWith(
                            fontSize: 13,
                          ),
                        ),
                      ],
                      const SizedBox(height: DesignTokens.space2),
                      Row(
                        children: [
                          NodeStateChip(estado: nodo.estado),
                          const SizedBox(width: DesignTokens.space2),
                          Text(
                            _nivelLabel(nodo.nivel),
                            style: context.texts.bodySmall?.copyWith(
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: DesignTokens.space2),
                Icon(
                  nodo.tieneHijos ? Symbols.chevron_right : Symbols.play_arrow,
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

  static String _nivelLabel(String nivel) => switch (nivel) {
    'area' => 'Área',
    'bloque' => 'Bloque',
    'sub_area' => 'Sub área',
    _ => 'Tema',
  };
}

class _Sugerencias extends StatelessWidget {
  const _Sugerencias({required this.sugerencias, required this.onTap});

  final List<String> sugerencias;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(DesignTokens.space4),
      children: [
        FadeUp(
          child: Text(
            'Busca en las 10 áreas, 58 sub áreas y todos los temas del temario '
            'oficial.',
            style: context.texts.bodyMedium,
          ),
        ),
        const SizedBox(height: DesignTokens.space5),
        FadeUp(
          index: 1,
          child: Text(
            'PRUEBA CON',
            style: context.texts.bodySmall?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: context.scheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: DesignTokens.space3),
        FadeUp(
          index: 2,
          child: Wrap(
            spacing: DesignTokens.space2,
            runSpacing: DesignTokens.space2,
            children: [
              for (final s in sugerencias)
                ActionChip(label: Text(s), onPressed: () => onTap(s)),
            ],
          ),
        ),
        const SizedBox(height: DesignTokens.space6),
        FadeUp(
          index: 3,
          child: Container(
            padding: const EdgeInsets.all(DesignTokens.space4),
            decoration: BoxDecoration(
              color: context.states.info.tint,
              borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Symbols.lightbulb,
                  size: 20,
                  fill: 1,
                  color: context.states.info.onTint,
                ),
                const SizedBox(width: DesignTokens.space3),
                Expanded(
                  child: Text(
                    // Dato real del temario, útil justo cuando alguien busca.
                    'Ojo: oftalmología, otorrinolaringología y cirugía '
                    'pediátrica están dentro de Cirugía, no como áreas aparte.',
                    style: context.texts.bodySmall?.copyWith(
                      height: 1.5,
                      color: context.states.info.onTint,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EscribeMas extends StatelessWidget {
  const _EscribeMas();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Escribe al menos dos letras',
        style: context.texts.bodyMedium,
      ),
    );
  }
}

class _SinResultados extends StatelessWidget {
  const _SinResultados({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Symbols.search_off,
              size: 40,
              color: context.scheme.onSurfaceVariant,
            ),
            const SizedBox(height: DesignTokens.space4),
            Text(
              'Nada para "$query"',
              textAlign: TextAlign.center,
              style: context.texts.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: DesignTokens.space3),
            Text(
              'El temario usa los nombres oficiales de ASPEFAM. Prueba con un '
              'término más general.',
              textAlign: TextAlign.center,
              style: context.texts.bodyMedium?.copyWith(height: 1.55),
            ),
          ],
        ),
      ),
    );
  }
}
