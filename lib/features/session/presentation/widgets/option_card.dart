import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/motion.dart';
import '../../../../core/theme/state_colors.dart';
import '../../domain/session_models.dart';

/// Cómo se pinta una alternativa según el momento de la sesión.
enum OptionVisual {
  /// Sin responder, sin seleccionar.
  normal,

  /// Seleccionada pero sin confirmar.
  seleccionada,

  /// Ya respondida: esta era la correcta.
  correcta,

  /// Ya respondida: el usuario eligió esta y estaba mal.
  incorrecta,

  /// Ya respondida: ni elegida ni correcta.
  descartada,
}

/// Una alternativa de la pregunta.
///
/// La letra va en un círculo a la izquierda, como en el examen impreso. El área
/// táctil es de toda la tarjeta y nunca baja de 48 px de alto.
class OptionCard extends StatelessWidget {
  const OptionCard({
    required this.opcion,
    required this.letra,
    required this.visual,
    required this.onTap,
    super.key,
  });

  final QuestionOption opcion;
  final String letra;
  final OptionVisual visual;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final states = context.states;

    final (fondo, borde, anchoBorde, colorLetra, fondoLetra) = switch (visual) {
      OptionVisual.normal => (
        scheme.surface,
        scheme.outline,
        1.0,
        scheme.onSurfaceVariant,
        null,
      ),
      OptionVisual.seleccionada => (
        states.info.tint,
        scheme.primary,
        2.0,
        Colors.white,
        scheme.primary,
      ),
      OptionVisual.correcta => (
        states.success.tint,
        states.success.base,
        2.0,
        Colors.white,
        states.success.base,
      ),
      OptionVisual.incorrecta => (
        states.error.tint,
        states.error.base,
        2.0,
        Colors.white,
        states.error.base,
      ),
      OptionVisual.descartada => (
        scheme.surface,
        scheme.outlineVariant,
        1.0,
        scheme.onSurfaceVariant,
        null,
      ),
    };

    final etiqueta = switch (visual) {
      OptionVisual.correcta => 'CORRECTA',
      OptionVisual.incorrecta => 'TU RESPUESTA',
      _ => null,
    };

    final icono = switch (visual) {
      OptionVisual.correcta => Symbols.check,
      OptionVisual.incorrecta => Symbols.close,
      _ => null,
    };

    return AnimatedContainer(
      duration: Motion.duration(context, Motion.fast),
      curve: Motion.standard,
      decoration: BoxDecoration(
        color: fondo,
        border: Border.all(color: borde, width: anchoBorde),
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        child: Padding(
          // Mínimo 48 de alto con el padding: una alternativa de una línea no
          // puede quedar más chica que el área táctil.
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space4,
            vertical: DesignTokens.space3 + 3,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: fondoLetra,
                  shape: BoxShape.circle,
                  border: fondoLetra == null
                      ? Border.all(color: borde, width: 1.5)
                      : null,
                ),
                child: icono != null
                    ? Icon(icono, size: 17, color: colorLetra)
                    : Text(
                        letra,
                        style: context.texts.bodySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colorLetra,
                        ),
                      ),
              ),
              const SizedBox(width: DesignTokens.space3),
              Expanded(
                child: Text(
                  opcion.texto,
                  style: context.texts.bodyLarge?.copyWith(
                    fontSize: 14.5,
                    height: 1.5,
                    fontWeight: visual == OptionVisual.normal ||
                            visual == OptionVisual.descartada
                        ? FontWeight.w400
                        : FontWeight.w700,
                  ),
                ),
              ),
              if (etiqueta != null) ...[
                const SizedBox(width: DesignTokens.space2),
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    etiqueta,
                    style: context.texts.bodySmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: visual == OptionVisual.correcta
                          ? states.success.onTint
                          : states.error.onTint,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
