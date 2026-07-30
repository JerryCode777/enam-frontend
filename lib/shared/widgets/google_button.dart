import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/design_tokens.dart';
import '../../core/theme/state_colors.dart';

/// Separador "o continúa con" entre el botón principal y los proveedores.
class SeparadorAuth extends StatelessWidget {
  const SeparadorAuth({this.texto = 'o continúa con', super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(height: 1, color: context.scheme.outlineVariant),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space3),
          child: Text(
            texto,
            style: context.texts.bodySmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: context.scheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Container(height: 1, color: context.scheme.outlineVariant),
        ),
      ],
    );
  }
}

/// Botón de "Continuar con Google".
///
/// Sigue las condiciones de marca de Google: el logo va **a todo color y sin
/// modificar**, sobre fondo blanco o claro, y el texto tiene que nombrar a
/// Google. Recolorear la G o meterla en un botón de marca propia es motivo de
/// rechazo en la revisión de Play Store.
///
/// Por eso el logo es un asset SVG y no un icono de la fuente: los iconos
/// heredan el color del texto, y aquí no se puede.
class GoogleButton extends StatelessWidget {
  const GoogleButton({
    required this.onPressed,
    this.loading = false,
    this.label = 'Google',
    super.key,
  });

  final VoidCallback? onPressed;
  final bool loading;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 54),
          backgroundColor: scheme.surface,
          side: BorderSide(color: scheme.outline, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(27),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/images/google_logo.svg',
                    width: 20,
                    height: 20,
                  ),
                  const SizedBox(width: DesignTokens.space2 + 2),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.bodyLarge?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
