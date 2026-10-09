import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/config/contacto.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/state_colors.dart';
import 'planes_de_apple.dart';

/// Cómo se vuelve a tener acceso, según la tienda.
///
/// **Este archivo es el único sitio donde vive esa diferencia.** Estaba resuelta
/// con cuidado en la pantalla de bloqueo y en ningún sitio más, así que desde
/// Ajustes → Mi suscripción se llegaba igual a los precios y al formulario de
/// tarjeta, en iPhone incluido. Una regla que hay que recordar aplicar en cada
/// pantalla nueva es una regla que se rompe; por eso ahora es un widget y no un
/// `if` repetido.
///
/// ---
///
/// Ni App Store ni Google Play dejan cobrar dentro de una app sin llevarse su
/// comisión, ni llevar a pagar fuera de ellas. Los dos caminos:
///
/// - **Android** — **ningún camino de compra.** Google Play no deja enlazar ni
///   mandar a pagar fuera de Play Billing, y la app no tiene Play Billing. Antes
///   había un botón que abría la web ya identificado, un enlace por correo y un
///   «Activar por WhatsApp»: los tres eran llevar a pagar fuera de Play. Ahora
///   solo se dice que Premium va con la cuenta, sin dónde ni cómo, y quien ya
///   es Premium entra con su cuenta y lo tiene todo.
/// - **iOS** — la compra dentro de la app, con App Store, y nada más (guía
///   3.1.1). Había una nota con la dirección del sitio que abría `/activar` en
///   la web y un «Activar por WhatsApp» con «quiero activar mi cuenta»: las dos
///   eran ofrecer un medio de pago que no es App Store.
///
/// En las dos, WhatsApp queda solo como ayuda. Ninguna enseña un precio fuera
/// de StoreKit.

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
    if (enTiendaApple) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // El cobro dentro de la app va PRIMERO. Es lo que Apple exige —su
          // sistema de pago no puede quedar por detrás de otra vía— y además es
          // lo más cómodo: se paga con el Face ID y sin salir de aquí.
          PlanesDeApple(),
          SizedBox(height: DesignTokens.space4),
          BotonWhatsApp(),
        ],
      );
    }

    // Android: ni botón, ni enlace, ni precio. Solo lo que es verdad para
    // cualquiera: Premium va con la cuenta.
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PremiumConTuCuenta(),
        SizedBox(height: DesignTokens.space4),
        BotonWhatsApp(),
      ],
    );
  }
}

/// En Android, en lugar de un camino de compra: Premium va con la cuenta.
///
/// Sin decir dónde ni cómo se compra, sin enlace y sin precio (política de
/// pagos de Google Play).
class PremiumConTuCuenta extends StatelessWidget {
  const PremiumConTuCuenta({super.key});

  @override
  Widget build(BuildContext context) {
    final info = context.states.info;
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space4),
      decoration: BoxDecoration(
        color: info.tint,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg + 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Symbols.workspace_premium,
            size: 22,
            fill: 1,
            color: info.onTint,
          ),
          const SizedBox(width: DesignTokens.space3),
          Expanded(
            child: Text(
              'Tu acceso Premium se activa con tu cuenta de ENAM Prep.',
              style: context.texts.bodyMedium?.copyWith(
                height: 1.5,
                fontWeight: FontWeight.w700,
                color: info.onTint,
              ),
            ),
          ),
        ],
      ),
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
      icon: const Icon(Symbols.chat, size: 20, fill: 1),
      label: const Text('Escríbenos si necesitas ayuda'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        foregroundColor: scheme.onSurface,
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        ),
      ),
    );
  }
}
