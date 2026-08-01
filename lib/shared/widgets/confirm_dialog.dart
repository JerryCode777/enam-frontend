import 'package:flutter/material.dart';

import '../../core/theme/design_tokens.dart';
import '../../core/theme/state_colors.dart';
import 'enam_button.dart';

/// El diálogo de confirmación de la app.
///
/// Existe para que salir de una práctica y salir de un simulacro se vean igual:
/// antes cada pantalla montaba su propio `AlertDialog` con los botones por
/// defecto de Material, y el resultado era más plano y más flojo que el resto
/// de la app.
///
/// Sigue lo que hace la web:
/// - Titular en 800, que es donde está la pregunta
/// - Explicación en 600, nunca en gris apagado: dice qué pasa si confirmas
/// - La acción que confirma va con el degradado de marca; la de volver atrás,
///   sin peso, porque no es la decisión que la pantalla espera
///
/// Devuelve `true` si el usuario confirmó.
Future<bool> confirmar(
  BuildContext context, {
  required String titulo,
  required String mensaje,
  required String confirmar,
  required String cancelar,
  bool destructivo = false,
}) async {
  final resultado = await showDialog<bool>(
    context: context,
    // La confirmación no se cierra tocando fuera: es una decisión, no un aviso.
    barrierDismissible: false,
    builder: (context) => _Confirmacion(
      titulo: titulo,
      mensaje: mensaje,
      confirmar: confirmar,
      cancelar: cancelar,
      destructivo: destructivo,
    ),
  );
  return resultado ?? false;
}

class _Confirmacion extends StatelessWidget {
  const _Confirmacion({
    required this.titulo,
    required this.mensaje,
    required this.confirmar,
    required this.cancelar,
    required this.destructivo,
  });

  final String titulo;
  final String mensaje;
  final String confirmar;
  final String cancelar;
  final bool destructivo;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;

    return AlertDialog(
      backgroundColor: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusXl - 4),
      ),
      titlePadding: const EdgeInsets.fromLTRB(
        DesignTokens.space5,
        DesignTokens.space5,
        DesignTokens.space5,
        0,
      ),
      contentPadding: const EdgeInsets.fromLTRB(
        DesignTokens.space5,
        DesignTokens.space2,
        DesignTokens.space5,
        DesignTokens.space4,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        DesignTokens.space5,
        0,
        DesignTokens.space5,
        DesignTokens.space5,
      ),
      title: Text(
        titulo,
        style: context.texts.headlineMedium?.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          height: 1.25,
          color: scheme.onSurface,
        ),
      ),
      content: Text(
        mensaje,
        style: context.texts.bodyMedium?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          height: 1.45,
          color: scheme.onSurfaceVariant,
        ),
      ),
      // Las dos acciones a la derecha, con la que confirma al final: es donde
      // el pulgar acaba el gesto de leer. Si las etiquetas no caben en una
      // fila —pasa con la fuente muy ampliada— se apilan en vez de partirse.
      actions: [
        LayoutBuilder(
          builder: (context, constraints) {
            final volver = _Volver(
              label: cancelar,
              onPressed: () => Navigator.of(context).pop(false),
            );
            final seguir = destructivo
                ? _BotonPeligro(
                    label: confirmar,
                    onPressed: () => Navigator.of(context).pop(true),
                  )
                : EnamButton(
                    label: confirmar,
                    expanded: false,
                    onPressed: () => Navigator.of(context).pop(true),
                  );

            final apiladas =
                MediaQuery.textScalerOf(context).scale(15) > 20 ||
                constraints.maxWidth < 280;

            if (apiladas) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  destructivo
                      ? seguir
                      : EnamButton(
                          label: confirmar,
                          onPressed: () => Navigator.of(context).pop(true),
                        ),
                  const SizedBox(height: DesignTokens.space2),
                  volver,
                ],
              );
            }

            return Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(child: volver),
                const SizedBox(width: DesignTokens.space2),
                seguir,
              ],
            );
          },
        ),
      ],
    );
  }
}

/// La salida sin peso de fondo, pero con el mismo grosor de letra que la
/// acción principal: es una opción de verdad, no una nota al pie.
class _Volver extends StatelessWidget {
  const _Volver({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space3),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.texts.bodyLarge?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: context.scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Para lo que no tiene vuelta atrás, como eliminar la cuenta.
class _BotonPeligro extends StatelessWidget {
  const _BotonPeligro({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final states = context.states;

    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: states.error.base,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusXl - 4),
        ),
      ),
      child: Text(
        label,
        style: context.texts.bodyLarge?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}
