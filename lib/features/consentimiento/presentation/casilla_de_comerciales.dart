import 'package:flutter/material.dart';

import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/state_colors.dart';

/// El texto de la casilla del registro, el de la web (13/10/2026). Dice que es
/// opcional y que se puede dar de baja, y nada más: ni descuentos ni la web.
const textoCasillaComerciales =
    'Quiero novedades y ofertas por correo (opcional, me doy de baja cuando '
    'quiera).';

/// La casilla de correos comerciales del alta (Ley 29733): **desmarcada** por
/// defecto, aparte de la de los términos y sin bloquear nada. Lo que marque
/// viaja como `aceptaComerciales` en el registro con correo, Google o Apple, y
/// el servidor solo lo guarda si el alta crea la cuenta.
class CasillaDeComerciales extends StatelessWidget {
  const CasillaDeComerciales({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final alCambiar = onChanged;
    return MergeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: value,
            onChanged: alCambiar == null ? null : (v) => alCambiar(v ?? false),
          ),
          const SizedBox(width: DesignTokens.space1),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: alCambiar == null ? null : () => alCambiar(!value),
              child: Padding(
                padding: const EdgeInsets.only(top: DesignTokens.space3),
                child: Text(
                  textoCasillaComerciales,
                  style: context.texts.bodyMedium,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
