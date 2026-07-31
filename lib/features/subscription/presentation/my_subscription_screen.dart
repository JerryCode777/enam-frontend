import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/error/failure.dart';
import '../../../core/providers.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/state_colors.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../../shared/widgets/state_banner.dart';
import '../domain/subscription_models.dart';
import 'widgets/opciones_de_pago.dart';

/// Pantalla 7.4 — mi suscripción (RF-27, RN-07).
///
/// Responde a tres preguntas y a ninguna más: **qué tengo**, **hasta cuándo** y
/// **cómo lo dejo o lo recupero**.
///
/// Lo que ya no hace, y es lo que importa:
///
/// - **No enseña el precio ni lleva a un formulario de pago.** Llevaba a `/pago`
///   desde tres sitios, sin mirar la tienda, así que en un iPhone se llegaba a
///   una pantalla con precios y campos de tarjeta. Esa es la guideline 3.1.1 de
///   App Store, que es motivo de rechazo, y era además el único punto donde el
///   reparto por tienda de la pantalla de bloqueo se saltaba entero.
/// - **Cancelar cancela.** Antes solo sacaba un mensaje de «renovación
///   cancelada» sin llamar a nada: se podía cancelar diez veces y la suscripción
///   seguía viva. Decirle a alguien que canceló algo que no se canceló es peor
///   que no ofrecer el botón.
///
/// Lo que hay en su lugar es [OpcionesDePago], que sabe qué se puede ofrecer en
/// cada tienda.
class MySubscriptionScreen extends ConsumerWidget {
  const MySubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sub = ref.watch(subscriptionProvider).value;

    return Scaffold(
      body: Column(
        children: [
          const GradientHeader(titulo: 'Mi suscripción'),
          Expanded(
            child: sub == null
                ? const _SinSuscripcion()
                : _Contenido(sub: sub),
          ),
        ],
      ),
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({required this.sub});

  final Subscription sub;

  @override
  Widget build(BuildContext context) {
    final enGracia = sub.estado == SubscriptionStatus.enGracia;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.space4,
        DesignTokens.space4,
        DesignTokens.space4,
        DesignTokens.space8,
      ),
      children: [
        if (enGracia) ...[
          FadeUp(
            child: StateBanner(
              kind: BannerKind.warning,
              icon: Symbols.error,
              // Sin botón de "actualizar medio de pago": ese botón llevaba al
              // checkout. Quien tenga que cambiar la tarjeta lo hace en la web
              // o por WhatsApp, y las dos salidas están más abajo.
              message:
                  'No pudimos cobrar tu renovación. Reintentamos '
                  'automáticamente; tienes acceso hasta el '
                  '${_fechaLarga(sub.expira)}.',
            ),
          ),
          const SizedBox(height: DesignTokens.space4),
        ],
        FadeUp(index: 1, child: _TarjetaPlan(sub: sub)),
        const SizedBox(height: DesignTokens.space4),
        FadeUp(index: 2, child: _Acciones(sub: sub)),
        const SizedBox(height: DesignTokens.space4),
        FadeUp(
          index: 3,
          child: Text(
            // RN-07: hay que decirlo antes de que cancele, no después.
            'Si cancelas, mantienes tu acceso hasta el fin del periodo pagado. '
            'Tu historial y tus estadísticas nunca se borran.',
            style: context.texts.bodySmall?.copyWith(height: 1.55),
          ),
        ),
      ],
    );
  }
}

class _TarjetaPlan extends StatelessWidget {
  const _TarjetaPlan({required this.sub});

  final Subscription sub;

  @override
  Widget build(BuildContext context) {
    final states = context.states;
    final (etiqueta, color) = switch (sub.estado) {
      SubscriptionStatus.pruebaSinIniciar => ('PRUEBA', states.info),
      SubscriptionStatus.prueba => ('EN PRUEBA', states.info),
      SubscriptionStatus.activa => ('ACTIVO', states.success),
      SubscriptionStatus.enGracia => ('EN GRACIA', states.warning),
      SubscriptionStatus.expirada => ('EXPIRADO', states.error),
      SubscriptionStatus.cancelada => ('CANCELADO', states.warning),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    sub.plan.nombre,
                    style: context.texts.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.space2 + 2,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color.tint,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusSm + 2),
                  ),
                  child: Text(
                    etiqueta,
                    style: context.texts.bodySmall?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: color.onTint,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.space3),
            _Fila(
              etiqueta: 'Vigente hasta',
              // La prueba sin empezar no tiene fecha: el reloj arranca en la
              // primera práctica (D-02). Poner "hoy" ahí sería inventar.
              valor: sub.expira == null
                  ? 'Empieza con tu primera práctica'
                  : DateFormat('d MMM yyyy', 'es').format(sub.expira!),
            ),
            // Sin fila de precio ni de medio de pago. Un importe dentro de la
            // app es justo lo que las tiendas no admiten, y además el dato no
            // le dice nada a quien ya pagó: lo que quiere saber es hasta cuándo
            // le vale y cómo se renueva.
            _Fila(
              etiqueta: 'Renovación',
              valor: switch (sub.estado) {
                SubscriptionStatus.cancelada => 'Cancelada',
                SubscriptionStatus.activa || SubscriptionStatus.enGracia =>
                  sub.origen == SubscriptionOrigin.culqi
                      ? 'Automática'
                      : 'Manual',
                _ => 'Sin renovación',
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Fecha larga en español, o el aviso de que la prueba aún no empezó (D-02).
String _fechaLarga(DateTime? fecha) => fecha == null
    ? 'que empieces tu primera práctica'
    : DateFormat("d 'de' MMMM", 'es').format(fecha);

class _Fila extends StatelessWidget {
  const _Fila({required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space2),
      child: Row(
        children: [
          Expanded(child: Text(etiqueta, style: context.texts.bodyMedium)),
          Text(
            valor,
            style: context.texts.bodyMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: context.scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _Acciones extends ConsumerStatefulWidget {
  const _Acciones({required this.sub});

  final Subscription sub;

  @override
  ConsumerState<_Acciones> createState() => _AccionesState();
}

class _AccionesState extends ConsumerState<_Acciones> {
  bool _cancelando = false;

  bool get _puedeCancelar =>
      widget.sub.estado == SubscriptionStatus.activa ||
      widget.sub.estado == SubscriptionStatus.enGracia;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Cómo seguir teniendo acceso, según la tienda. Es lo mismo que ve
        // quien se quedó sin acceso, y a propósito: la regla vive en un solo
        // sitio para que no se olvide al añadir una pantalla.
        const OpcionesDePago(etiquetaWhatsApp: 'Escríbenos si necesitas ayuda'),

        if (_puedeCancelar) ...[
          const SizedBox(height: DesignTokens.space4),
          Center(
            child: TextButton(
              onPressed: _cancelando ? null : _confirmarCancelacion,
              child: Text(
                _cancelando ? 'Cancelando…' : 'Cancelar renovación',
                style: TextStyle(color: context.scheme.onSurfaceVariant),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _confirmarCancelacion() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogo) => AlertDialog(
        title: const Text('¿Cancelar la renovación?'),
        content: Text(
          'Mantienes tu acceso hasta el ${_fechaLarga(widget.sub.expira)}. '
          // No hay plan gratis al que volver (SSD-ENAM-002 §1). Decir que lo
          // hay sería vender una red de seguridad que no existe.
          'Después pierdes el acceso hasta que vuelvas a activar un plan.\n\n'
          // Lo que NO se pierde, que es la duda real de quien cancela (RN-07).
          'Tu historial, tus estadísticas y tus preguntas marcadas se '
          'conservan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogo).pop(false),
            child: const Text('Seguir con mi plan'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogo).pop(true),
            child: const Text('Cancelar renovación'),
          ),
        ],
      ),
    );

    if (confirmado != true || !mounted) return;

    setState(() => _cancelando = true);
    try {
      await ref.read(subscriptionRepositoryProvider).cancelar();
      // Sin esto la pantalla seguiría diciendo "ACTIVO" después de cancelar.
      ref.invalidate(subscriptionProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tu suscripción no se renovará.')),
        );
      }
    } on Failure catch (e) {
      // Un fallo aquí NO se puede tragar: quien se quede creyendo que canceló
      // se encuentra el cobro el mes siguiente.
      if (mounted) showErrorSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _cancelando = false);
    }
  }
}

class _SinSuscripcion extends StatelessWidget {
  const _SinSuscripcion();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.space6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: DesignTokens.space6),
          Icon(
            Symbols.workspace_premium,
            size: 40,
            color: context.scheme.onSurfaceVariant,
          ),
          const SizedBox(height: DesignTokens.space4),
          Text(
            'No tienes un plan activo',
            style: context.texts.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: DesignTokens.space3),
          Text(
            // RN-07 antes que la oferta: es la duda real de quien llega aquí.
            'Tu historial y tus estadísticas siguen guardados.',
            textAlign: TextAlign.center,
            style: context.texts.bodyMedium,
          ),
          const SizedBox(height: DesignTokens.space5),
          const OpcionesDePago(),
        ],
      ),
    );
  }
}
