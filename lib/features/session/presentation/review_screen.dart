import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/state_colors.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../domain/session_models.dart';
import 'session_controller.dart';
import 'widgets/option_card.dart';

/// Qué preguntas mostrar en la revisión.
enum ReviewFilter {
  todas('Todas'),
  falladas('Falladas'),
  marcadas('Marcadas'),
  enBlanco('En blanco');

  const ReviewFilter(this.label);
  final String label;
}

/// Pantalla 5.7 — revisión pregunta por pregunta (RF-18).
///
/// Después de un simulacro de 180, recorrerlas todas en orden es inviable. Los
/// filtros son la pantalla: lo que sirve es ver **las que fallaste**.
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({required this.sessionId, super.key});

  final String sessionId;

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  ReviewFilter _filtro = ReviewFilter.falladas;

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(sessionControllerProvider(widget.sessionId));

    return Scaffold(
      body: estado.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('No pudimos cargar.')),
        data: (s) => _construir(s.session),
      ),
    );
  }

  Widget _construir(StudySession session) {
    final visibles = _filtrar(session);
    final conteos = {
      for (final f in ReviewFilter.values) f: _filtrar(session, f).length,
    };

    return Column(
      children: [
        const GradientHeader(titulo: 'Revisión'),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.space4,
            DesignTokens.space3,
            DesignTokens.space4,
            DesignTokens.space1,
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final f in ReviewFilter.values) ...[
                  if (f != ReviewFilter.values.first)
                    const SizedBox(width: DesignTokens.space2),
                  FilterChip(
                    label: Text('${f.label} · ${conteos[f]}'),
                    selected: _filtro == f,
                    // Sin elementos no tiene sentido poder elegirlo.
                    onSelected: conteos[f] == 0
                        ? null
                        : (_) => setState(() => _filtro = f),
                  ),
                ],
              ],
            ),
          ),
        ),
        Expanded(
          child: visibles.isEmpty
              ? _Vacio(filtro: _filtro)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    DesignTokens.space4,
                    DesignTokens.space3,
                    DesignTokens.space4,
                    DesignTokens.space8,
                  ),
                  itemCount: visibles.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: DesignTokens.space3),
                    child: _TarjetaRevision(
                      numero: session.preguntas.indexOf(visibles[i]) + 1,
                      pregunta: visibles[i],
                      respuesta: session.respuestas[visibles[i].id],
                      index: i,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  List<Question> _filtrar(StudySession session, [ReviewFilter? filtro]) {
    final f = filtro ?? _filtro;
    return session.preguntas.where((q) {
      final r = session.respuestas[q.id];
      return switch (f) {
        ReviewFilter.todas => true,
        ReviewFilter.falladas => r?.esCorrecta == false && r?.optionId != null,
        ReviewFilter.marcadas => r?.marcada == true,
        ReviewFilter.enBlanco => r?.optionId == null,
      };
    }).toList();
  }
}

/// Una pregunta en la revisión, colapsada hasta que se abre.
///
/// Colapsada a propósito: 180 tarjetas expandidas son inmanejables. Se muestra
/// el extracto y el veredicto, y se abre la que interesa.
class _TarjetaRevision extends StatefulWidget {
  const _TarjetaRevision({
    required this.numero,
    required this.pregunta,
    required this.respuesta,
    required this.index,
  });

  final int numero;
  final Question pregunta;
  final Answer? respuesta;
  final int index;

  @override
  State<_TarjetaRevision> createState() => _TarjetaRevisionState();
}

class _TarjetaRevisionState extends State<_TarjetaRevision> {
  bool _abierta = false;

  static const _letras = ['A', 'B', 'C', 'D'];

  @override
  Widget build(BuildContext context) {
    final states = context.states;
    final r = widget.respuesta;
    final enBlanco = r?.optionId == null;
    final acerto = r?.esCorrecta == true;

    final (icono, color, etiqueta) = enBlanco
        ? (Symbols.remove, context.scheme.onSurfaceVariant, 'En blanco')
        : acerto
        ? (Symbols.check, states.success.base, 'Correcta')
        : (Symbols.close, states.error.base, 'Fallada');

    return FadeUp(
      index: widget.index,
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () => setState(() => _abierta = !_abierta),
              borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
              child: Padding(
                padding: const EdgeInsets.all(DesignTokens.space4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icono, size: 16, color: color),
                    ),
                    const SizedBox(width: DesignTokens.space3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${widget.numero}',
                                style: context.texts.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: DesignTokens.space2),
                              Text(
                                etiqueta,
                                style: context.texts.bodySmall?.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: color,
                                ),
                              ),
                              if (r?.marcada == true) ...[
                                const SizedBox(width: DesignTokens.space2),
                                Icon(
                                  Symbols.bookmark,
                                  size: 14,
                                  fill: 1,
                                  color: states.warning.onTint,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: DesignTokens.space1),
                          Text(
                            widget.pregunta.enunciado,
                            maxLines: _abierta ? null : 2,
                            overflow: _abierta ? null : TextOverflow.ellipsis,
                            style: context.texts.bodyMedium?.copyWith(
                              height: _abierta
                                  ? DesignTokens.lineHeightRelaxed
                                  : 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _abierta ? Symbols.expand_less : Symbols.expand_more,
                      size: 20,
                      color: context.scheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            if (_abierta) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.space4,
                  0,
                  DesignTokens.space4,
                  DesignTokens.space4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < widget.pregunta.opciones.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: DesignTokens.space2,
                        ),
                        child: OptionCard(
                          opcion: widget.pregunta.opciones[i],
                          letra: _letras[i],
                          visual: _visual(widget.pregunta.opciones[i], r),
                          onTap: null,
                        ),
                      ),
                    if (widget.pregunta.explicacion != null) ...[
                      const SizedBox(height: DesignTokens.space2),
                      Container(
                        padding: const EdgeInsets.all(DesignTokens.space3 + 1),
                        decoration: BoxDecoration(
                          color: context.scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(
                            DesignTokens.radiusMd,
                          ),
                        ),
                        child: Text(
                          widget.pregunta.explicacion!,
                          style: context.texts.bodySmall?.copyWith(
                            height: DesignTokens.lineHeightRelaxed,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  OptionVisual _visual(QuestionOption o, Answer? r) {
    if (o.esCorrecta == true) return OptionVisual.correcta;
    if (r?.optionId == o.id) return OptionVisual.incorrecta;
    return OptionVisual.descartada;
  }
}

class _Vacio extends StatelessWidget {
  const _Vacio({required this.filtro});

  final ReviewFilter filtro;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Symbols.check_circle,
              size: 40,
              fill: 1,
              color: context.states.success.onTint,
            ),
            const SizedBox(height: DesignTokens.space4),
            Text(
              switch (filtro) {
                ReviewFilter.falladas => 'No fallaste ninguna',
                ReviewFilter.marcadas => 'No marcaste ninguna',
                ReviewFilter.enBlanco => 'Respondiste todas',
                ReviewFilter.todas => 'No hay preguntas',
              },
              textAlign: TextAlign.center,
              style: context.texts.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
