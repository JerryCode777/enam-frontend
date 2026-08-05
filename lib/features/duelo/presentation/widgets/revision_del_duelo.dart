import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/state_colors.dart';
import '../../../session/domain/session_models.dart';
import '../../../session/presentation/widgets/option_card.dart';
import '../../domain/duelo_models.dart';

/// Las diez, destapadas y con lo que hizo cada uno.
///
/// Aquí sí se cuenta la respuesta del rival: el duelo terminó, ya no hay nada
/// que proteger, y comparar pregunta por pregunta es media gracia de haber
/// jugado.
class RevisionDelDuelo extends StatelessWidget {
  const RevisionDelDuelo({
    required this.preguntas,
    required this.rival,
    super.key,
  });

  final List<PreguntaRevisada> preguntas;
  final String rival;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return ListView.separated(
      padding: const EdgeInsets.all(DesignTokens.space4),
      itemCount: preguntas.length,
      separatorBuilder: (_, _) => const SizedBox(height: DesignTokens.space5),
      itemBuilder: (context, i) {
        final p = preguntas[i];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'PREGUNTA ${p.orden}',
                  style: texto.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(width: DesignTokens.space2),
                _Marca(estado: p.tuEstado, quien: 'Tú'),
                const SizedBox(width: DesignTokens.space1),
                _Marca(estado: p.rivalEstado, quien: rival),
              ],
            ),
            const SizedBox(height: DesignTokens.space2),
            Text(p.enunciado, style: texto.bodyLarge?.copyWith(height: 1.4)),
            const SizedBox(height: DesignTokens.space3),
            for (var j = 0; j < p.opciones.length; j++) ...[
              OptionCard(
                opcion: QuestionOption(
                  id: p.opciones[j].id,
                  texto: p.opciones[j].texto,
                  esCorrecta: p.opciones[j].esCorrecta,
                ),
                letra: String.fromCharCode(65 + j),
                visual: p.opciones[j].esCorrecta
                    ? OptionVisual.correcta
                    : p.opciones[j].id == p.tuOpcionId
                    ? OptionVisual.incorrecta
                    : OptionVisual.descartada,
                onTap: null,
              ),
              const SizedBox(height: DesignTokens.space2),
            ],
            if (p.explicacion.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(DesignTokens.space3),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                ),
                child: Text(
                  p.explicacion,
                  style: texto.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Cómo le fue a alguien con una pregunta: acierto, fallo o **en blanco**.
///
/// El tercero no es un adorno. Cuando alguien abandona, la partida se corta y
/// las preguntas que quedan no llegan a abrirse; con solo dos estados salían
/// todas en rojo, para los dos, y parecía que se habían fallado siete preguntas
/// que nadie vio.
class _Marca extends StatelessWidget {
  const _Marca({required this.estado, required this.quien});

  final EstadoDeRespuesta estado;
  final String quien;

  @override
  Widget build(BuildContext context) {
    final estados = context.states;
    final scheme = Theme.of(context).colorScheme;

    final (fondo, tinta, dice) = switch (estado) {
      EstadoDeRespuesta.acierto => (
        estados.success.tint,
        estados.success.onTint,
        'acertó',
      ),
      EstadoDeRespuesta.fallo => (
        estados.error.tint,
        estados.error.onTint,
        'falló',
      ),
      EstadoDeRespuesta.enBlanco => (
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
        'no respondió',
      ),
    };

    return Semantics(
      label: '$quien: $dice',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: fondo,
          borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
        ),
        child: Text(
          quien,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: tinta,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
