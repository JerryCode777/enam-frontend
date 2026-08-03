import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../core/router/navegar.dart';
import '../../core/router/routes.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/state_colors.dart';

/// El consentimiento, dicho junto al botón que lo da.
///
/// Sustituye a un paso aparte: antes, entrar con Google abría la cuenta de
/// Google, volvía, y **entonces** aparecía un diálogo pidiendo aceptar los
/// términos. Ese es el peor momento posible para interrumpir —la persona ya
/// creía haber terminado— y no es lo que hace nadie en la industria.
///
/// La forma estándar es esta: la frase queda **a la vista, pegada a los
/// botones**, y pulsar es lo que consiente. La Ley N.º 29733 pide que el
/// consentimiento sea previo e informado; con el aviso encima del botón lo es,
/// y sin sacar a nadie del camino.
///
/// Lo que se cede: con una casilla se puede demostrar que la marcó; con esto,
/// que el texto estaba en pantalla al pulsar. Es la práctica del sector y sigue
/// guardándose fecha y versión de los términos igual que antes. El registro por
/// correo **mantiene su casilla**, porque ahí ya hay un formulario y no molesta.
class AvisoLegalAlContinuar extends StatefulWidget {
  const AvisoLegalAlContinuar({super.key});

  @override
  State<AvisoLegalAlContinuar> createState() => _AvisoLegalAlContinuarState();
}

class _AvisoLegalAlContinuarState extends State<AvisoLegalAlContinuar> {
  // Los reconocedores de gesto de un `TextSpan` hay que liberarlos a mano: no
  // cuelgan del árbol de widgets, así que nadie lo hace por ti.
  late final TapGestureRecognizer _terminos = TapGestureRecognizer()
    ..onTap = () => context.irA(Routes.terms);

  late final TapGestureRecognizer _privacidad = TapGestureRecognizer()
    ..onTap = () => context.irA(Routes.terms);

  @override
  void dispose() {
    _terminos.dispose();
    _privacidad.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = context.texts.bodySmall?.copyWith(
      fontSize: 12.5,
      height: 1.45,
      fontWeight: FontWeight.w600,
      color: context.scheme.onSurfaceVariant,
    );

    final enlace = base?.copyWith(
      fontWeight: FontWeight.w800,
      color: context.scheme.onSurface,
      decoration: TextDecoration.underline,
      decorationColor: context.scheme.primary,
      decorationThickness: 2,
    );

    return Padding(
      padding: const EdgeInsets.only(top: DesignTokens.space2),
      child: Text.rich(
        TextSpan(
          style: base,
          children: [
            const TextSpan(text: 'Al continuar, aceptas los '),
            TextSpan(text: 'Términos', style: enlace, recognizer: _terminos),
            const TextSpan(text: ' y la '),
            TextSpan(
              text: 'Política de datos personales',
              style: enlace,
              recognizer: _privacidad,
            ),
            const TextSpan(text: ' (Ley N.º 29733).'),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
