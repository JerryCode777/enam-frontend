import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/config/contacto.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/state_colors.dart';
import 'planes_de_apple.dart';
import 'planes_de_google_play.dart';

/// Cómo se vuelve a tener acceso, según la tienda.
///
/// **Este archivo es el único sitio donde vive esa diferencia.** Una regla que
/// hay que recordar aplicar en cada pantalla nueva es una regla que se rompe;
/// por eso es un widget y no un `if` repetido.
///
/// ---
///
/// Ni App Store ni Google Play dejan cobrar contenido digital dentro de una app
/// con otro sistema de pago, ni mandar a pagar fuera de ellas. Cada tienda,
/// con el suyo y nada más:
///
/// - **iOS** — App Store (guía 3.1.1): `PlanesDeApple`.
/// - **Android** — Google Play Billing: `PlanesDeGooglePlay`. Hasta la 1.1.2
///   Android no tenía ningún camino de compra (se había quitado el pago por la
///   web, que Play prohíbe) y la pantalla solo decía que Premium iba con la
///   cuenta: nadie podía comprar desde Android.
///
/// En las dos, WhatsApp queda solo como ayuda. Ninguna enseña un precio que
/// no venga de la tienda, ni un enlace para pagar en la web.

/// Si toca la variante de App Store.
///
/// Se puede forzar con `--dart-define=TIENDA=apple|android` para revisar las
/// dos sin cambiar de dispositivo.
bool get enTiendaApple => switch (AppConfig.tiendaForzada) {
  'apple' => true,
  'android' => false,
  // `defaultTargetPlatform` y no `Platform.isIOS`: en el teléfono dicen lo
  // mismo, pero este se puede simular en las pruebas, que es donde se
  // comprueba qué ofrece cada tienda.
  _ => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS,
};

/// Las opciones de pago que corresponden a esta tienda.
class OpcionesDePago extends StatelessWidget {
  const OpcionesDePago({super.key});

  @override
  Widget build(BuildContext context) {
    // La ayuda va arriba (pedido de Jerry, 05/11/2026): no es otra vía de pago,
    // y la única forma de pagar sigue siendo la tienda.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const BotonWhatsApp(),
        const SizedBox(height: DesignTokens.space3),
        if (enTiendaApple)
          const PlanesDeApple()
        else
          const PlanesDeGooglePlay(),
      ],
    );
  }
}

/// Abre el WhatsApp de soporte con un pedido de ayuda ya escrito (M10).
///
/// No es una integración: es un enlace `wa.me`, igual que en la app hermana.
/// Y no es un medio de pago, en ninguna tienda: ver [OpcionesDePago].
class BotonWhatsApp extends StatelessWidget {
  const BotonWhatsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;

    return OutlinedButton.icon(
      onPressed: () async {
        final abierto = await Contacto.abrir(
          Contacto.soporte(
            mensaje: 'hola, necesito ayuda con mi cuenta de ENAM Prep',
          ),
        );
        if (!abierto && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'No pudimos abrir WhatsApp. Escríbenos al '
                '${Contacto.soporteVisible}.',
              ),
            ),
          );
        }
      },
      icon: SvgPicture.asset(
        'assets/images/whatsapp_logo.svg',
        width: 20,
        height: 20,
        excludeFromSemantics: true,
      ),
      label: const Text('Escríbenos si necesitas ayuda'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(44),
        foregroundColor: scheme.onSurface,
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        ),
      ),
    );
  }
}
