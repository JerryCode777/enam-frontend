import 'package:flutter/material.dart';

import '../../core/theme/design_tokens.dart';

/// Botón principal de la app: 56 px de alto, radio completo (28).
///
/// Cuando [loading] es `true` queda deshabilitado y muestra un spinner, para que
/// no se pueda enviar el mismo formulario dos veces.
class EnamButton extends StatelessWidget {
  const EnamButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.expanded = true,
    super.key,
  });

  final String label;

  /// `null` deja el botón deshabilitado.
  final VoidCallback? onPressed;

  final bool loading;
  final IconData? icon;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Flexible: con la fuente del sistema ampliada o a 360 px, la
              // etiqueta se recorta en vez de desbordar la fila.
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: DesignTokens.space1 + 2),
                Icon(icon, size: 18),
              ],
            ],
          );

    final button = FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        // El ancho completo lo da el SizedBox de abajo cuando expanded es
        // true; aquí solo se fija la altura, con un mínimo finito.
        minimumSize: const Size(64, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusXl + 4),
        ),
      ),
      child: child,
    );

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Variante secundaria: mismo tamaño, con borde en vez de relleno.
class EnamOutlinedButton extends StatelessWidget {
  const EnamOutlinedButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 56,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: Size(64, height),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(height / 2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: DesignTokens.space2),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
