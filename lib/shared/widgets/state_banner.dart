import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/design_tokens.dart';
import '../../core/theme/state_colors.dart';

enum BannerKind { info, success, warning, error }

/// Banner de estado: fondo tenue, icono y texto.
///
/// Usa las tres piezas del color de estado — `tint` de fondo, `base` del icono y
/// `onTint` del texto — así que cumple contraste en ambos temas.
class StateBanner extends StatelessWidget {
  const StateBanner({
    required this.message,
    this.kind = BannerKind.info,
    this.icon,
    this.action,
    super.key,
  });

  final String message;
  final BannerKind kind;
  final IconData? icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final states = context.states;
    final colors = switch (kind) {
      BannerKind.info => states.info,
      BannerKind.success => states.success,
      BannerKind.warning => states.warning,
      BannerKind.error => states.error,
    };
    final defaultIcon = switch (kind) {
      BannerKind.info => Symbols.info,
      BannerKind.success => Symbols.check_circle,
      BannerKind.warning => Symbols.warning,
      BannerKind.error => Symbols.error,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space3 + 2,
        vertical: DesignTokens.space3,
      ),
      decoration: BoxDecoration(
        color: colors.tint,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd + 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? defaultIcon, size: 20, color: colors.base),
          const SizedBox(width: DesignTokens.space2 + 2),
          Expanded(
            child: Text(
              message,
              style: context.texts.bodyMedium?.copyWith(color: colors.onTint),
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: DesignTokens.space2),
            action!,
          ],
        ],
      ),
    );
  }
}

/// Muestra un mensaje de error como snackbar, con el tono de la app.
void showErrorSnack(BuildContext context, String message) {
  final states = context.states;
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        backgroundColor: states.error.tint,
        content: Row(
          children: [
            Icon(Symbols.error, size: 20, color: states.error.base),
            const SizedBox(width: DesignTokens.space2 + 2),
            Expanded(
              child: Text(
                message,
                style: context.texts.bodyMedium?.copyWith(
                  color: states.error.onTint,
                ),
              ),
            ),
          ],
        ),
      ),
    );
}
