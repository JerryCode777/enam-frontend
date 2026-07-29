import 'package:flutter/material.dart';

import '../../core/theme/design_tokens.dart';
import '../../core/theme/state_colors.dart';

/// Pie de las pantallas de acceso: "¿Ya tienes cuenta? **Ingresa**".
///
/// Usa `Wrap` y no `Row`: a 360 px, o con la fuente del sistema ampliada, el
/// texto y el enlace no entran en una sola línea y tienen que poder bajar.
class AuthFooter extends StatelessWidget {
  const AuthFooter({
    required this.pregunta,
    required this.accion,
    required this.onTap,
    super.key,
  });

  final String pregunta;
  final String accion;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(pregunta, style: context.texts.bodyMedium),
        const SizedBox(width: DesignTokens.space1),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.space1,
              vertical: DesignTokens.space2,
            ),
            child: Text(
              accion,
              style: context.texts.bodyMedium?.copyWith(
                color: context.states.info.onTint,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
