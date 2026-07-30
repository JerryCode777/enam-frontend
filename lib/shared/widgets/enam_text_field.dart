import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/theme/design_tokens.dart';
import '../../core/theme/state_colors.dart';

/// Campo de formulario de la app.
///
/// Sigue el diseño: etiqueta encima en 12px w700, campo de 56 px de alto, radio
/// 14, borde de 2 px en primario al enfocar, y texto de ayuda o de error debajo.
class EnamTextField extends StatefulWidget {
  const EnamTextField({
    required this.label,
    this.controller,
    this.hint,
    this.helper,
    this.error,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    super.key,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;

  /// Texto de ayuda permanente. Se oculta si hay [error].
  final String? helper;

  /// Mensaje de error. Si no es nulo, el campo se pinta en estado de error.
  final String? error;

  /// Campo de contraseña: oculta el texto y muestra el botón de ver/ocultar.
  final bool obscure;

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;

  @override
  State<EnamTextField> createState() => _EnamTextFieldState();
}

class _EnamTextFieldState extends State<EnamTextField> {
  late final FocusNode _focus = FocusNode()..addListener(_onFocusChange);
  bool _revealed = false;

  void _onFocusChange() => setState(() {});

  @override
  void dispose() {
    _focus
      ..removeListener(_onFocusChange)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final states = context.states;
    final hasError = widget.error != null;

    final borderColor = switch (null) {
      _ when hasError => states.error.base,
      _ when _focus.hasFocus => scheme.primary,
      _ => scheme.outline,
    };
    final borderWidth = (hasError || _focus.hasFocus) ? 2.0 : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: context.texts.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: DesignTokens.space1 + 2),
        TextField(
          controller: widget.controller,
          focusNode: _focus,
          obscureText: widget.obscure && !_revealed,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          autofillHints: widget.autofillHints,
          enabled: widget.enabled,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          autofocus: widget.autofocus,
          style: context.texts.bodyLarge,
          decoration: InputDecoration(
            hintText: widget.hint,
            // El error se pinta abajo a mano, para poder mostrar `helper`
            // cuando no hay error sin que Flutter reserve las dos líneas.
            errorStyle: const TextStyle(height: 0, fontSize: 0),
            constraints: const BoxConstraints(minHeight: 54),
            // `--surf2` del diseño: el campo va un tono por encima de la
            // tarjeta que lo contiene, no del mismo color.
            filled: true,
            fillColor: scheme.surfaceContainerHighest,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd + 2),
              borderSide: BorderSide(color: borderColor, width: borderWidth),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd + 2),
              borderSide: BorderSide(color: borderColor, width: borderWidth),
            ),
            suffixIcon: widget.obscure
                ? IconButton(
                    icon: Icon(
                      _revealed ? Symbols.visibility : Symbols.visibility_off,
                      size: 22,
                      color: scheme.onSurfaceVariant,
                    ),
                    onPressed: () => setState(() => _revealed = !_revealed),
                    tooltip: _revealed
                        ? 'Ocultar contraseña'
                        : 'Mostrar contraseña',
                  )
                : null,
          ),
        ),
        if (hasError || widget.helper != null) ...[
          const SizedBox(height: DesignTokens.space1 + 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasError) ...[
                Icon(Symbols.error, size: 15, color: states.error.onTint),
                const SizedBox(width: DesignTokens.space1),
              ],
              Expanded(
                child: Text(
                  widget.error ?? widget.helper!,
                  style: context.texts.bodySmall?.copyWith(
                    color: hasError
                        ? states.error.onTint
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
