import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/mock/mock_data.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/area_colors.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/state_colors.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/enam_button.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../catalog/presentation/catalog_providers.dart';

/// Una pregunta marcada, con lo mínimo para reconocerla en una lista.
typedef PreguntaMarcada = ({
  String questionId,
  String extracto,
  String areaId,
  String? subtemaNombre,
  bool acertada,
});

/// Las preguntas que el usuario marcó para repaso (RF-14).
///
/// Hoy sale del mock. El contrato no tiene endpoint para listarlas todavía:
/// hace falta un `GET /me/marked` que devuelva las marcadas de todas las
/// sesiones, no solo de la actual.
final marcadasProvider = Provider<List<PreguntaMarcada>>((ref) {
  final preguntas = MockData.questions(cantidad: 12, conRespuestas: true);
  return [
    for (var i = 0; i < preguntas.length; i++)
      (
        questionId: preguntas[i].id,
        extracto: _extracto(preguntas[i].enunciado),
        areaId: preguntas[i].areaId ?? 'medicina',
        subtemaNombre: preguntas[i].subtemaId,
        acertada: i.isEven,
      ),
  ];
});

/// Primeras palabras del enunciado. Un caso clínico completo no cabe en una fila.
String _extracto(String enunciado) {
  const largo = 78;
  if (enunciado.length <= largo) return enunciado;
  return '${enunciado.substring(0, largo).trimRight()}…';
}

/// Pantalla 4.5 — marcadas para repaso.
class MarkedQuestionsScreen extends ConsumerStatefulWidget {
  const MarkedQuestionsScreen({super.key});

  @override
  ConsumerState<MarkedQuestionsScreen> createState() =>
      _MarkedQuestionsScreenState();
}

class _MarkedQuestionsScreenState extends ConsumerState<MarkedQuestionsScreen> {
  String? _filtroArea;

  @override
  Widget build(BuildContext context) {
    final todas = ref.watch(marcadasProvider);
    final visibles = _filtroArea == null
        ? todas
        : todas.where((m) => m.areaId == _filtroArea).toList();

    // Áreas presentes, con su conteo, para los chips de filtro.
    final porArea = <String, int>{};
    for (final m in todas) {
      porArea[m.areaId] = (porArea[m.areaId] ?? 0) + 1;
    }

    return Scaffold(
      body: Column(
        children: [
          const GradientHeader(titulo: 'Marcadas para repaso'),
          Expanded(
            child: todas.isEmpty
                ? const _Vacio()
                : Column(
                    children: [
                      _Filtros(
                        total: todas.length,
                        porArea: porArea,
                        seleccionada: _filtroArea,
                        onSeleccionar: (id) =>
                            setState(() => _filtroArea = id),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(
                            DesignTokens.space4,
                            DesignTokens.space2,
                            DesignTokens.space4,
                            DesignTokens.space16,
                          ),
                          itemCount: visibles.length,
                          itemBuilder: (context, i) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: DesignTokens.space2 + 2,
                            ),
                            child: _FilaMarcada(
                              marcada: visibles[i],
                              index: i,
                              onDesmarcar: () => _desmarcar(visibles[i]),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
      bottomNavigationBar: todas.isEmpty
          ? null
          : Container(
              padding: EdgeInsets.fromLTRB(
                DesignTokens.space4,
                DesignTokens.space3,
                DesignTokens.space4,
                DesignTokens.space3 + MediaQuery.paddingOf(context).bottom,
              ),
              decoration: BoxDecoration(
                color: context.scheme.surface,
                border: Border(
                  top: BorderSide(color: context.scheme.outlineVariant),
                ),
              ),
              child: EnamButton(
                label: 'Practicar las ${visibles.length} marcadas',
                icon: Symbols.play_arrow,
                onPressed: () => context.push(
                  '${Routes.practiceConfig}?origen=marcadas',
                ),
              ),
            ),
    );
  }

  void _desmarcar(PreguntaMarcada m) {
    // Con deshacer: desmarcar por error obligaría a buscar la pregunta de nuevo.
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: const Text('Quitada de marcadas'),
          action: SnackBarAction(label: 'Deshacer', onPressed: () {}),
        ),
      );
  }
}

class _Filtros extends ConsumerWidget {
  const _Filtros({
    required this.total,
    required this.porArea,
    required this.seleccionada,
    required this.onSeleccionar,
  });

  final int total;
  final Map<String, int> porArea;
  final String? seleccionada;
  final ValueChanged<String?> onSeleccionar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.space4,
        DesignTokens.space3,
        DesignTokens.space4,
        DesignTokens.space1,
      ),
      child: Row(
        children: [
          FilterChip(
            label: Text('Todas · $total'),
            selected: seleccionada == null,
            onSelected: (_) => onSeleccionar(null),
          ),
          for (final entry in porArea.entries) ...[
            const SizedBox(width: DesignTokens.space2),
            FilterChip(
              avatar: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AreaColors.of(
                    entry.key,
                    Theme.of(context).brightness,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              label: Text(
                '${ref.watch(nodoProvider(entry.key))?.nodo.nombre ?? entry.key}'
                ' · ${entry.value}',
              ),
              selected: seleccionada == entry.key,
              onSelected: (_) => onSeleccionar(entry.key),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilaMarcada extends StatelessWidget {
  const _FilaMarcada({
    required this.marcada,
    required this.index,
    required this.onDesmarcar,
  });

  final PreguntaMarcada marcada;
  final int index;
  final VoidCallback onDesmarcar;

  @override
  Widget build(BuildContext context) {
    final states = context.states;
    final color = AreaColors.of(marcada.areaId, Theme.of(context).brightness);

    return FadeUp(
      index: index,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.space4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: Icon(
                  Symbols.bookmark,
                  fill: 1,
                  size: 20,
                  color: states.info.onTint,
                ),
                tooltip: 'Quitar de marcadas',
                onPressed: onDesmarcar,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      marcada.extracto,
                      style: context.texts.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space1 + 2),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: DesignTokens.space1 + 1,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Text(
                          marcada.subtemaNombre ?? marcada.areaId,
                          style: context.texts.bodySmall?.copyWith(
                            fontSize: 11.5,
                          ),
                        ),
                        Text(
                          '· ${marcada.acertada ? "acertada" : "fallada"}',
                          style: context.texts.bodySmall?.copyWith(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: marcada.acertada
                                ? states.success.onTint
                                : states.error.onTint,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Vacio extends StatelessWidget {
  const _Vacio();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Symbols.bookmark,
              size: 40,
              color: context.scheme.onSurfaceVariant,
            ),
            const SizedBox(height: DesignTokens.space4),
            Text(
              'Nada por aquí todavía',
              style: context.texts.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: DesignTokens.space3),
            Text(
              'Marca preguntas mientras practicas y aparecerán aquí.',
              textAlign: TextAlign.center,
              style: context.texts.bodyMedium?.copyWith(height: 1.55),
            ),
          ],
        ),
      ),
    );
  }
}
