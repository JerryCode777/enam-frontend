import 'package:flutter/material.dart';

import '../../core/theme/design_tokens.dart';

/// Botón principal de la app: 56 px de alto, radio completo, con degradado.
///
/// El degradado es del diseño. Se pinta con un `Ink` bajo el botón en vez de un
/// `Container` encima, para que el efecto de toque de Material siga viéndose.
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

    final habilitado = onPressed != null && !loading;
    final radio = BorderRadius.circular(DesignTokens.radiusXl + 4);

    final button = FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        // El ancho completo lo da el SizedBox de abajo cuando expanded es
        // true; aquí solo se fija la altura, con un mínimo finito.
        minimumSize: const Size(64, 56),
        shape: RoundedRectangleBorder(borderRadius: radio),
        // Transparente para dejar ver el degradado del Ink de abajo. Cuando
        // está deshabilitado se deja el color del tema, que ya lo atenúa.
        backgroundColor: habilitado ? Colors.transparent : null,
        shadowColor: Colors.transparent,
        foregroundColor: habilitado ? Colors.white : null,
      ).copyWith(
        elevation: const WidgetStatePropertyAll(0),
        // Sin esto, el relleno transparente deja ver el fondo al presionar.
        overlayColor: WidgetStatePropertyAll(
          Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: child,
    );

    // El degradado va en un Material propio y no en un `Ink` suelto.
    //
    // `Ink` pinta su decoración sobre el Material más cercano hacia arriba, así
    // que si el botón vive dentro de un Container con fondo —como las barras de
    // acción de abajo— ese fondo se dibuja encima y el degradado desaparece: el
    // botón queda invisible. Con un Material propio, la decoración se pinta en
    // él y siempre queda por delante.
    final conDegradado = habilitado
        ? Material(
            type: MaterialType.transparency,
            child: Ink(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: DesignTokens.buttonGradient,
                ),
                borderRadius: radio,
              ),
              child: button,
            ),
          )
        : button;

    return expanded
        ? SizedBox(width: double.infinity, child: conDegradado)
        : conDegradado;
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
