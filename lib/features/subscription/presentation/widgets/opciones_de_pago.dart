import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

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
/// - **iOS** — la compra dentro de la app, con App Store. La nota del sitio
///   va debajo y sin precios. Al tocarla, el sistema muestra su propio aviso de
///   que el pago no pasa por la App Store, y el navegador abre
///   `/activar?origen=ios` **en frío**, sin saber quién llega; por eso esa
///   pantalla pregunta a qué viene en vez de suponerlo.
///
/// Ninguna de las dos variantes enseña un precio fuera de StoreKit.

/// Si toca la variante de App Store.
///
/// Se puede forzar con `--dart-define=TIENDA=apple|android` para revisar las
/// dos sin cambiar de dispositivo.
bool get enTiendaApple => switch (AppConfig.tiendaForzada) {
  'apple' => true,
  'android' => false,
  _ => !kIsWeb && Platform.isIOS,
};

/// Las opciones de pago que corresponden a esta tienda.
class OpcionesDePago extends StatelessWidget {
  const OpcionesDePago({super.key, this.etiquetaWhatsApp});

  /// Texto del botón de WhatsApp en iOS. En el bloqueo es «Activar por
  /// WhatsApp»; en «Mi suscripción» quien llega ya es cliente y el texto tiene
  /// que cambiar. En Android el botón es siempre de ayuda.
  final String? etiquetaWhatsApp;

  @override
  Widget build(BuildContext context) {
    final etiqueta = etiquetaWhatsApp;

    if (enTiendaApple) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // El cobro dentro de la app va PRIMERO. Es lo que Apple exige —su
          // sistema de pago no puede quedar por detrás de otra vía— y además es
          // lo más cómodo: se paga con el Face ID y sin salir de aquí.
          const PlanesDeApple(),
          const SizedBox(height: DesignTokens.space4),

          // La nota del sitio se queda, pero debajo y sin precios: no es un
          // camino de compra alternativo, es dónde gestionar la cuenta.
          const _NotaDelSitio(),
          const SizedBox(height: DesignTokens.space3),
          BotonWhatsApp(label: etiqueta ?? 'Escríbenos si necesitas ayuda'),
        ],
      );
    }

    // Android: ni botón, ni enlace, ni precio. Solo lo que es verdad para
    // cualquiera: Premium va con la cuenta.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const PremiumConTuCuenta(),
        const SizedBox(height: DesignTokens.space4),
        BotonWhatsApp(
          label: 'Escríbenos si necesitas ayuda',
          enlace: Contacto.soporte(
            mensaje: 'hola, necesito ayuda con mi cuenta de ENAM Prep',
          ),
        ),
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

/// Lo que se ve en iOS.
///
/// Sin precio, sin botón de pago y sin prometer nada: solo la dirección del
/// sitio. Al tocarla, el sistema muestra su propio aviso de que el pago no pasa
/// por Apple antes de abrir el navegador.
class _NotaDelSitio extends StatelessWidget {
  const _NotaDelSitio();

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;

    // Se enseña el dominio a secas —sin la ruta ni los parámetros— porque es lo
    // que la persona tiene que reconocer; pero se ABRE la pantalla de
    // activación, que es la que sabe recibir a alguien que llega sin sesión.
    // Abrir la raíz dejaba al usuario en el splash y de ahí en el login, sin
    // ninguna pista de a qué había ido.
    final destino = Uri.parse(AppConfig.urlActivar);

    return InkWell(
      onTap: () => launchUrl(destino, mode: LaunchMode.externalApplication),
      borderRadius: BorderRadius.circular(DesignTokens.radiusLg + 2),
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.space4),
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg + 2),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gestiona tu cuenta de ENAM Prep y mucho más',
              style: context.texts.bodyLarge?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                height: 1.3,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: DesignTokens.space2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    destino.host,
                    style: context.texts.bodyMedium?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: context.states.info.onTint,
                    ),
                  ),
                ),
                Icon(
                  Symbols.open_in_new,
                  size: 18,
                  color: context.states.info.onTint,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Abre WhatsApp con el mensaje ya escrito (M10).
///
/// No es una integración: es un enlace `wa.me`, igual que en la app hermana.
class BotonWhatsApp extends StatelessWidget {
  const BotonWhatsApp({
    super.key,
    this.label = 'Activar por WhatsApp',
    this.enlace,
  });

  final String label;

  /// A qué chat y con qué mensaje. Por defecto, el de activar el plan.
  final Uri? enlace;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;

    return OutlinedButton.icon(
      onPressed: () async {
        final abierto = await Contacto.abrir(enlace ?? Contacto.activarPlan());
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
      label: Text(label),
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
