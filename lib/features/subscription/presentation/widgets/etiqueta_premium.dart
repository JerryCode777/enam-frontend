import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/state_colors.dart';

/// «Premium» con candado, junto a una función de pago, solo en gratis.
///
/// Anuncia el límite antes de chocar con él: en gratis limitado el límite es
/// parte de la venta (deja sin efecto RP-01, «los límites no se anuncian»).
/// No impide nada por sí misma: lo que no se puede, lo dice el servidor con un
/// 403 que abre el muro.
class EtiquetaPremium extends StatelessWidget {
  const EtiquetaPremium({super.key});

  @override
  Widget build(BuildContext context) {
    final info = context.states.info;
    return Semantics(
      label: 'Función Premium',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space2,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: info.tint,
          borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Symbols.lock, size: 13, fill: 1, color: info.onTint),
            const SizedBox(width: 3),
            Text(
              'Premium',
              style: context.texts.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: info.onTint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
