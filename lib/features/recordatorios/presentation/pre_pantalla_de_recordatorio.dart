import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/state_colors.dart';
import '../../../shared/widgets/enam_button.dart';
import 'recordatorios_controller.dart';

/// «¿Te recuerdo practicar cada día?»: la pantalla propia antes del permiso
/// del sistema.
///
/// Sale **una sola vez**, después de la primera sesión terminada: es cuando la
/// persona ya vio qué es practicar aquí y un recordatorio tiene sentido. Al
/// abrir la app por primera vez no se pide nada. Con «Ahora no» el sistema ni
/// pregunta, y así su diálogo —que solo sale una vez en la vida de la app—
/// queda para cuando la persona lo quiera, desde Ajustes.
///
/// Devuelve si quedó encendido.
Future<bool> ofrecerRecordatorio(BuildContext context, WidgetRef ref) async {
  final controller = ref.read(recordatoriosProvider.notifier);
  final hora = (await ref.read(recordatoriosProvider.future)).ajustes;
  if (!context.mounted) return false;

  final acepta = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    // Sin esto la hoja se topa a 9/16 de la pantalla, y en un teléfono chico
    // con letra grande «Ahora no» quedaba fuera.
    isScrollControlled: true,
    builder: (context) => _PrePantalla(
      hora: TimeOfDay(hour: hora.hora, minute: hora.minuto),
    ),
  );

  if (acepta ?? false) {
    return controller.activar(OrigenDelPermiso.prePantalla);
  }
  await controller.rechazarPrePantalla();
  return false;
}

class _PrePantalla extends StatelessWidget {
  const _PrePantalla({required this.hora});

  final TimeOfDay hora;

  @override
  Widget build(BuildContext context) {
    final info = context.states.info;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          DesignTokens.space5,
          0,
          DesignTokens.space5,
          DesignTokens.space5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: info.tint,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Symbols.notifications_active,
                  size: 28,
                  fill: 1,
                  color: info.onTint,
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.space4),
            Text(
              '¿Te recuerdo practicar cada día?',
              textAlign: TextAlign.center,
              style: context.texts.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: DesignTokens.space2),
            Text(
              'Un aviso a las ${hora.format(context)}, solo si ese día '
              'todavía no practicaste. Lo cambias o lo apagas cuando quieras '
              'en Ajustes.',
              textAlign: TextAlign.center,
              style: context.texts.bodyMedium?.copyWith(height: 1.45),
            ),
            const SizedBox(height: DesignTokens.space5),
            EnamButton(
              label: 'Sí, recuérdame',
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: DesignTokens.space1),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Ahora no'),
            ),
          ],
        ),
      ),
    );
  }
}
