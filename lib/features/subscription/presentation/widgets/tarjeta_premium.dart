import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/state_colors.dart';
import '../../domain/acceso.dart';
import '../muro_de_venta_screen.dart';
import 'etiqueta_premium.dart';

/// En gratis, el sitio de una función de pago: qué es, con su etiqueta, y
/// el botón al muro. Ocupa el lugar de la función, para que se sepa que
/// existe y qué haría.
class TarjetaPremium extends ConsumerWidget {
  const TarjetaPremium({required this.funcion, super.key});

  final FuncionPremium funcion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.scheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const EtiquetaPremium(),
            const SizedBox(height: DesignTokens.space2),
            Text(
              funcion.titulo,
              style: context.texts.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: DesignTokens.space1),
            Text(
              funcion.vistaPrevia,
              style: context.texts.bodyMedium?.copyWith(height: 1.5),
            ),
            const SizedBox(height: DesignTokens.space2),
            TextButton.icon(
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              onPressed: () => abrirMuro(context, ref, FuncionDePago(funcion)),
              icon: Icon(Symbols.workspace_premium, color: scheme.primary),
              label: const Text('Ver Premium'),
            ),
          ],
        ),
      ),
    );
  }
}
