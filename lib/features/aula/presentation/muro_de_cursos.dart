import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/error/failure.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/state_colors.dart';
import '../../../shared/widgets/enam_button.dart';
import '../../subscription/presentation/access_ended_screen.dart';
import '../../subscription/presentation/widgets/opciones_de_pago.dart';

/// Si [error] es el 403 de una clase de pago (`FUNCION_PREMIUM`, con
/// `funcion: "cursos"`). Los endpoints del aula no dan otra función.
bool esClaseDePago(Object? error) =>
    error is ForbiddenFailure && error.code == 'FUNCION_PREMIUM';

/// El muro de los cursos: se abre al tocar una clase con candado, o cuando el
/// servidor responde que la clase es de pago.
///
/// Es una hoja y no una pantalla porque no encierra a nadie: el temario sigue
/// detrás, con las clases gratis abiertas. Los textos son los de la web
/// (`MuroDeVenta.tsx`, función `cursos`).
///
/// **Sin precios ni ofertas.** En iOS, «Ver Premium» lleva a la compra con App
/// Store. En Android no hay botón: Google Play no deja llevar a pagar fuera de
/// Play Billing, y la app no lo tiene, así que solo se dice que Premium va con
/// la cuenta (como en `OpcionesDePago`).
// PENDIENTE(gratis-limitado): cuando la PR #2 entre a main, esto pasa a ser
// `abrirMuro(context, ref, const FuncionDePago(FuncionPremium.cursos))`.
Future<void> abrirMuroDeCursos(BuildContext context, WidgetRef ref) =>
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (hoja) => _MuroDeCursos(
        alVerPremium: enTiendaApple
            ? () {
                Navigator.of(hoja).pop();
                irAlPago(ref, context);
              }
            : null,
      ),
    );

class _MuroDeCursos extends StatelessWidget {
  const _MuroDeCursos({required this.alVerPremium});

  /// Nulo donde la app no vende (Android).
  final VoidCallback? alVerPremium;

  @override
  Widget build(BuildContext context) {
    final info = context.states.info;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.space6,
        0,
        DesignTokens.space6,
        DesignTokens.space6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.all(DesignTokens.space3),
              decoration: BoxDecoration(
                color: info.tint,
                borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
              ),
              child: Icon(Symbols.lock, size: 28, fill: 1, color: info.onTint),
            ),
          ),
          const SizedBox(height: DesignTokens.space4),
          Text(
            'Los cursos completos son de Premium',
            style: context.texts.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              // Sin color propio en el tema: en oscuro salía negro.
              color: context.scheme.onSurface,
              height: DesignTokens.lineHeightTight,
            ),
          ),
          const SizedBox(height: DesignTokens.space2),
          Text(
            'Todas las clases en video del temario oficial, cada una con su '
            'práctica. Las clases gratis siguen abiertas.',
            style: context.texts.bodyLarge?.copyWith(height: 1.5),
          ),
          const SizedBox(height: DesignTokens.space6),
          if (alVerPremium case final ver?)
            EnamButton(label: 'Ver Premium', onPressed: ver)
          else
            const PremiumConTuCuenta(),
          const SizedBox(height: DesignTokens.space2),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                alVerPremium == null ? 'Entendido' : 'Ahora no',
                style: TextStyle(color: context.scheme.onSurfaceVariant),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
