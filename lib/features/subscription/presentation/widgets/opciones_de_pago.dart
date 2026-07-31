import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/config/contacto.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/state_colors.dart';
import '../../../../shared/widgets/enam_button.dart';
import '../../../../shared/widgets/state_banner.dart';

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
/// comisión. La salida que usan Netflix y Spotify es la misma: **la app no
/// cobra ni enseña precios**, y el pago ocurre en el navegador. Los dos caminos
/// no son intercambiables:
///
/// - **Android** — se manda un enlace al correo de la cuenta. Al pulsarlo, el
///   navegador abre `/activar?token=…` con la sesión ya resuelta y el usuario
///   elige plan sin escribir una contraseña en el teclado del móvil. Es el
///   mejor de los dos y por eso es el que se ofrece donde se puede.
/// - **iOS** — Apple es más estricta: ni correo ni botón de pago. Solo una nota
///   discreta con la dirección del sitio. Al tocarla, el sistema muestra su
///   propio aviso de que el pago no pasa por la App Store, y el navegador abre
///   `/activar?origen=ios` **en frío**, sin saber quién llega; por eso esa
///   pantalla pregunta a qué viene en vez de suponerlo.
///
/// Ninguna de las dos variantes enseña un precio. Los precios viven en la web y
/// en el correo, que además es donde pueden cambiar sin publicar una versión.

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
class OpcionesDePago extends ConsumerStatefulWidget {
  const OpcionesDePago({super.key, this.etiquetaWhatsApp});

  /// Texto del botón de WhatsApp. En el bloqueo es «Activar por WhatsApp»; en
  /// «Mi suscripción» quien llega ya es cliente y el texto tiene que cambiar.
  final String? etiquetaWhatsApp;

  @override
  ConsumerState<OpcionesDePago> createState() => _OpcionesDePagoState();
}

class _OpcionesDePagoState extends ConsumerState<OpcionesDePago> {
  bool _enviando = false;
  bool _enviado = false;

  Future<void> _enviarEnlace() async {
    if (_enviando) return;

    final correo = ref.read(currentUserProvider)?.email;
    if (correo == null) return;

    setState(() => _enviando = true);
    try {
      await ref
          .read(subscriptionRepositoryProvider)
          .enviarEnlaceDeSuscripcion(correo);
      if (mounted) setState(() => _enviado = true);
    } on Failure catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  /// Abre la app de correo del dispositivo.
  ///
  /// `mailto:` sin destinatario es lo que el sistema entiende como "abre el
  /// buzón": no redacta nada, solo lleva a la bandeja.
  Future<void> _abrirBuzon() async {
    final abierto = await launchUrl(
      Uri(scheme: 'mailto'),
      mode: LaunchMode.externalApplication,
    ).catchError((_) => false);

    if (!abierto && mounted) {
      showErrorSnack(context, 'No encontramos una app de correo en el equipo.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final etiqueta = widget.etiquetaWhatsApp;

    if (enTiendaApple) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _NotaDelSitio(),
          const SizedBox(height: DesignTokens.space3),
          BotonWhatsApp(label: etiqueta ?? 'Escríbenos si necesitas ayuda'),
        ],
      );
    }

    if (_enviado) {
      return _EnlaceEnviado(
        correo: ref.watch(currentUserProvider)?.email ?? '',
        onAbrirBuzon: _abrirBuzon,
        onReenviar: _enviarEnlace,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EnamButton(
          label: 'Continuar por correo',
          loading: _enviando,
          onPressed: _enviarEnlace,
        ),
        const SizedBox(height: DesignTokens.space3),
        BotonWhatsApp(label: etiqueta ?? 'Activar por WhatsApp'),
      ],
    );
  }
}

/// Lo que se ve en Android tras pedir el enlace.
///
/// El correo va grande y visible: si la persona no reconoce esa dirección, el
/// enlace no le va a llegar nunca y hay que dejar que se dé cuenta aquí.
class _EnlaceEnviado extends StatelessWidget {
  const _EnlaceEnviado({
    required this.correo,
    required this.onAbrirBuzon,
    required this.onReenviar,
  });

  final String correo;
  final VoidCallback onAbrirBuzon;
  final VoidCallback onReenviar;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final states = context.states;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(DesignTokens.space4),
          decoration: BoxDecoration(
            color: states.info.tint,
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg + 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Symbols.mark_email_unread,
                    size: 22,
                    fill: 1,
                    color: states.info.onTint,
                  ),
                  const SizedBox(width: DesignTokens.space2 + 2),
                  Expanded(
                    child: Text(
                      'Pulsa el enlace del correo',
                      style: context.texts.bodyLarge?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: states.info.onTint,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.space2),
              Text(
                'Te enviamos un enlace de suscripción al siguiente correo. '
                'Solo tienes que pulsarlo para completar la suscripción. '
                'Vence en 15 minutos.',
                style: context.texts.bodyMedium?.copyWith(
                  fontSize: 13,
                  height: 1.45,
                  color: states.info.onTint,
                ),
              ),
              const SizedBox(height: DesignTokens.space3),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.space3,
                  vertical: DesignTokens.space2 + 2,
                ),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Text(
                  correo,
                  textAlign: TextAlign.center,
                  style: context.texts.bodyLarge?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: DesignTokens.space4),
        EnamButton(label: 'Ir al buzón de correo', onPressed: onAbrirBuzon),
        const SizedBox(height: DesignTokens.space2),
        Center(
          child: TextButton(
            onPressed: onReenviar,
            child: const Text('No me llegó, reenviar'),
          ),
        ),
      ],
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
  const BotonWhatsApp({super.key, this.label = 'Activar por WhatsApp'});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;

    return OutlinedButton.icon(
      onPressed: () async {
        final abierto = await Contacto.abrir(Contacto.activarPlan());
        if (!abierto && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No pudimos abrir WhatsApp. Escríbenos al '
                '${Contacto.botVisible}.',
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
