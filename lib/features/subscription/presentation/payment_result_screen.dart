import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/state_colors.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/enam_button.dart';
import 'plans_screen.dart';

enum EstadoPago { exito, pendiente, fallo }

/// Pantalla 7.3 — resultado del pago.
///
/// Tres estados, y ninguno es un callejón sin salida:
/// - **Éxito**: activo, con fecha de vencimiento concreta
/// - **Pendiente** (Yape, RF-28): la verificación es manual y se dice cuánto
///   tarda; el plan gratis sigue usable mientras tanto
/// - **Fallo**: aclara que **no se hizo ningún cobro** y ofrece dos salidas
class PaymentResultScreen extends ConsumerWidget {
  const PaymentResultScreen({required this.estado, this.planId, super.key});

  final EstadoPago estado;
  final String? planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final states = context.states;
    final planes = ref.watch(plansProvider);
    final plan = planes.firstWhere(
      (p) => p.id == planId,
      orElse: () => planes.first,
    );
    final vence = DateTime.now().add(Duration(days: plan.duracionDias));

    final (icono, color, titulo, cuerpo) = switch (estado) {
      EstadoPago.exito => (
        Symbols.check_circle,
        states.success,
        'Ya eres Premium',
        'Tu ${plan.nombre.toLowerCase()} está activo hasta el '
            '${DateFormat("d 'de' MMMM", 'es').format(vence)}. Te enviamos el '
            'comprobante al correo.',
      ),
      EstadoPago.pendiente => (
        Symbols.schedule,
        states.warning,
        'Estamos verificando tu yapeo',
        'La verificación es manual y suele tomar menos de 2 horas en horario de '
            'atención. Te avisamos con una notificación apenas se active.',
      ),
      EstadoPago.fallo => (
        Symbols.error,
        states.error,
        'No se pudo procesar el pago',
        // Lo primero que hay que aclarar: no le cobraron.
        'No se hizo ningún cobro. Puedes intentar de nuevo o usar otro medio '
            'de pago.',
      ),
    };

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(DesignTokens.space8),
            child: FadeUp(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color.tint,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icono,
                      size: 44,
                      fill: estado == EstadoPago.exito ? 1 : 0,
                      color: color.base,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.space5),
                  Text(
                    titulo,
                    textAlign: TextAlign.center,
                    style: context.texts.headlineMedium?.copyWith(
                      fontSize: DesignTokens.fontSize2xl - 2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.space3),
                  Text(
                    cuerpo,
                    textAlign: TextAlign.center,
                    style: context.texts.bodyMedium?.copyWith(height: 1.55),
                  ),
                  if (estado == EstadoPago.pendiente) ...[
                    const SizedBox(height: DesignTokens.space4),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignTokens.space4,
                          vertical: DesignTokens.space3,
                        ),
                        child: Text(
                          'Yape · S/ ${plan.precio.toStringAsFixed(2)} · '
                          '${DateFormat("d MMM, h:mm a", 'es').format(DateTime.now())}',
                          style: context.texts.bodySmall,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: DesignTokens.space6),
                  ..._acciones(context, ref),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _acciones(BuildContext context, WidgetRef ref) => switch (estado) {
    EstadoPago.exito => [
      EnamButton(
        label: 'Empezar a practicar',
        onPressed: () {
          // El plan cambió: las estadísticas y los límites también.
          ref.invalidate(dashboardProvider);
          context.go(Routes.practiceConfig);
        },
      ),
    ],
    EstadoPago.pendiente => [
      EnamOutlinedButton(
        label: 'Seguir practicando gratis',
        height: 52,
        onPressed: () => context.go(Routes.home),
      ),
    ],
    EstadoPago.fallo => [
      EnamButton(
        label: 'Intentar de nuevo',
        onPressed: () => context.pop(),
      ),
      const SizedBox(height: DesignTokens.space2 + 2),
      EnamOutlinedButton(
        label: 'Cambiar de medio',
        height: 52,
        onPressed: () => context.pushReplacement(Routes.checkout),
      ),
    ],
  };
}
