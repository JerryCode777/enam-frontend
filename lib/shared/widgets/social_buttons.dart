/// Botones de proveedores externos del login: Google y Apple.
///
/// Cada uno tiene condiciones de marca propias y no negociables, y por eso no
/// comparten un widget genérico: el de Google exige fondo claro y logo a todo
/// color, y el de Apple exige negro o blanco con su manzana.
library;

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

/// Botón de "Continuar con Apple".
///
/// Las reglas de marca de Apple son estrictas y su revisión las mira: el botón
/// va en negro (o blanco), con su logo a la izquierda, el texto en el idioma
/// del sistema y sin nada más dentro. Alto mínimo 44 y el logo ocupa alrededor
/// de un tercio del alto.
///
/// Se dibuja a mano y no con el widget del paquete para que comparta la altura
/// y el radio del resto de botones de la pantalla; los tamaños relativos que
/// Apple exige se respetan igual.
class AppleButton extends StatelessWidget {
  const AppleButton({
    required this.onPressed,
    this.loading = false,
    this.label = 'Apple',
    super.key,
  });

  final VoidCallback? onPressed;
  final bool loading;
  final String label;

  @override
  Widget build(BuildContext context) {
    // En tema oscuro el botón va blanco: negro sobre fondo oscuro desaparece,
    // y Apple permite las dos variantes justamente para esto.
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final fondo = oscuro ? Colors.white : Colors.black;
    final tinta = oscuro ? Colors.black : Colors.white;

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 54),
          backgroundColor: fondo,
          foregroundColor: tinta,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(27),
          ),
        ),
        child: loading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: tinta),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/images/apple_logo.svg',
                    height: 20,
                    colorFilter: ColorFilter.mode(tinta, BlendMode.srcIn),
                  ),
                  const SizedBox(width: DesignTokens.space2 + 2),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: tinta,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // La manzana va como asset y no como glifo de `cupertino_icons`: ese paquete
  // ni siquiera está en el pubspec, así que el icono salía como un cuadrado
  // vacío. Y aun estando, apoyar un logo de marca en un punto de código de uso
  // privado de una fuente de iconos es frágil.
}
