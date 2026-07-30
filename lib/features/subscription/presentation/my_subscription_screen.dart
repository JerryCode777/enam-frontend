import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/state_colors.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../../shared/widgets/state_banner.dart';
import '../domain/subscription_models.dart';
import 'plans_screen.dart';

/// Suscripción del usuario. Falta `GET /subscription` conectado.
final miSuscripcionProvider = Provider<Subscription?>((ref) {
  final plan = ref.watch(plansProvider).first;
  final ahora = DateTime.now();
  return Subscription(
    id: 'sub-1',
    plan: plan,
    // En gracia a propósito, para poder ver el caso de cobro fallido (RF-27).
    estado: SubscriptionStatus.enGracia,
    origen: SubscriptionOrigin.culqi,
    inicia: ahora.subtract(const Duration(days: 30)),
    expira: ahora.add(const Duration(days: 3)),
  );
});

/// Pantalla 7.4 — mi suscripción (RF-27, RN-07).
///
/// Dos cosas que tienen que quedar clarísimas:
/// - Con cobro fallido, **hasta qué fecha exacta** conserva el acceso (3 días de
///   gracia), y qué hacer al respecto
/// - Al cancelar, que **el historial y las estadísticas no se borran** (RN-07)
class MySubscriptionScreen extends ConsumerWidget {
  const MySubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sub = ref.watch(miSuscripcionProvider);

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
              message:
                  'No pudimos cobrar tu renovación. Reintentamos '
                  'automáticamente; tienes acceso hasta el '
                  '${DateFormat("d 'de' MMMM", 'es').format(sub.expira)}.',
              action: TextButton(
                onPressed: () => context.push(Routes.checkout),
                child: const Text('Actualizar'),
              ),
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
            'Si cancelas, mantienes Premium hasta el fin del periodo pagado. Tu '
            'historial y tus estadísticas nunca se borran.',
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
                      fontSize: 10.5,
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
              valor: DateFormat('d MMM yyyy', 'es').format(sub.expira),
            ),
            _Fila(
              etiqueta: 'Renovación',
              valor: sub.origen == SubscriptionOrigin.culqi
                  ? 'Automática · S/ ${sub.plan.precio.toStringAsFixed(0)}'
                  : 'Manual (Yape)',
            ),
            _Fila(
              etiqueta: 'Medio de pago',
              valor: sub.origen == SubscriptionOrigin.culqi
                  ? 'Tarjeta'
                  : 'Yape',
            ),
          ],
        ),
      ),
    );
  }
}

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

class _Acciones extends StatelessWidget {
  const _Acciones({required this.sub});

  final Subscription sub;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Symbols.credit_card),
            title: const Text('Cambiar medio de pago'),
            trailing: const Icon(Symbols.chevron_right, size: 20),
            onTap: () => context.push(Routes.checkout),
          ),
          Divider(height: 1, color: context.scheme.outlineVariant),
          ListTile(
            leading: const Icon(Symbols.receipt_long),
            title: const Text('Historial de pagos'),
            trailing: const Icon(Symbols.chevron_right, size: 20),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Disponible pronto')),
            ),
          ),
          Divider(height: 1, color: context.scheme.outlineVariant),
          ListTile(
            leading: const Icon(Symbols.cancel),
            title: const Text('Cancelar renovación'),
            trailing: const Icon(Symbols.chevron_right, size: 20),
            onTap: () => _confirmarCancelacion(context),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarCancelacion(BuildContext context) async {
    final cancelar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cancelar la renovación?'),
        content: Text(
          'Mantienes Premium hasta el '
          '${DateFormat("d 'de' MMMM", 'es').format(sub.expira)}. Después '
          'vuelves al plan gratis.\n\n'
          // Lo que NO se pierde, que es la duda real de quien cancela.
          'Tu historial, tus estadísticas y tus preguntas marcadas se '
          'conservan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Seguir con Premium'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancelar renovación'),
          ),
        ],
      ),
    );

    if (cancelar == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Renovación cancelada')),
      );
    }
  }
}

class _SinSuscripcion extends StatelessWidget {
  const _SinSuscripcion();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Symbols.workspace_premium,
              size: 40,
              color: context.scheme.onSurfaceVariant,
            ),
            const SizedBox(height: DesignTokens.space4),
            Text(
              'Estás en el plan gratis',
              style: context.texts.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: DesignTokens.space3),
            Text(
              '20 preguntas al día y un simulacro de muestra.',
              textAlign: TextAlign.center,
              style: context.texts.bodyMedium,
            ),
            const SizedBox(height: DesignTokens.space5),
            FilledButton(
              onPressed: () => context.push(Routes.plans),
              child: const Text('Ver los planes'),
            ),
          ],
        ),
      ),
    );
  }
}
