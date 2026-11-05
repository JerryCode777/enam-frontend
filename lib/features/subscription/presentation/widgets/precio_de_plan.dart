import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/state_colors.dart';
import '../../data/oferta_de_tienda.dart';

/// El precio de un plan, tal cual lo formatea la tienda. Con oferta, el precio
/// de oferta y el normal tachado: debajo, o al lado con [enLinea].
class PrecioDePlan extends StatelessWidget {
  const PrecioDePlan({
    required this.precio,
    required this.oferta,
    required this.tamano,
    this.enLinea = false,
    super.key,
  });

  final String precio;
  final OfertaDeTienda? oferta;
  final double tamano;
  final bool enLinea;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final principal = Text(
      oferta?.precio ?? precio,
      style: context.texts.bodyLarge?.copyWith(
        fontSize: tamano,
        fontWeight: FontWeight.w900,
        color: scheme.onSurface,
      ),
    );
    final normal = oferta?.precioNormal;
    if (normal == null) return principal;

    final tachado = Text(
      normal,
      semanticsLabel: 'Precio normal $normal',
      style: context.texts.bodySmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: scheme.onSurfaceVariant,
        decoration: TextDecoration.lineThrough,
      ),
    );
    if (enLinea) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          tachado,
          const SizedBox(width: DesignTokens.space2),
          principal,
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [principal, tachado],
    );
  }
}

/// Lo que cuesta el primer periodo y lo que se cobra después.
class LeyendaDeOferta extends StatelessWidget {
  const LeyendaDeOferta(this.oferta, {super.key});

  final OfertaDeTienda oferta;

  @override
  Widget build(BuildContext context) {
    return Text(
      oferta.leyenda,
      style: context.texts.bodySmall?.copyWith(
        fontSize: 12,
        height: 1.3,
        fontWeight: FontWeight.w600,
        color: context.scheme.onSurfaceVariant,
      ),
    );
  }
}

/// La etiqueta del plan que más conviene.
class EtiquetaMejorOpcion extends StatelessWidget {
  const EtiquetaMejorOpcion({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
      ),
      child: Text(
        'Mejor opción',
        style: context.texts.bodySmall?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: scheme.onPrimary,
        ),
      ),
    );
  }
}
