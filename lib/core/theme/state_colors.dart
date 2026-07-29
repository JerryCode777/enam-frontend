import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// Un estado semántico resuelto para el tema actual.
///
/// `base` para iconos y bordes · `onTint` para texto sobre `tint` · `tint` para
/// el fondo. Ver la nota en [DesignTokens] sobre por qué hacen falta las tres.
class StateColor {
  const StateColor({
    required this.base,
    required this.onTint,
    required this.tint,
  });

  final Color base;
  final Color onTint;
  final Color tint;
}

/// Acceso a los colores de estado ya resueltos según el tema.
///
/// ```dart
/// final s = context.states.error;
/// Container(color: s.tint, child: Text('…', style: TextStyle(color: s.onTint)));
/// ```
class StateColors {
  const StateColors._(this._light);

  factory StateColors.of(Brightness brightness) =>
      StateColors._(brightness == Brightness.light);

  final bool _light;

  StateColor get success => StateColor(
    base: DesignTokens.success,
    onTint: _light
        ? DesignTokens.successOnTintLight
        : DesignTokens.successOnTintDark,
    tint: _light ? DesignTokens.successTintLight : DesignTokens.successTintDark,
  );

  StateColor get error => StateColor(
    base: DesignTokens.error,
    onTint: _light ? DesignTokens.errorOnTintLight : DesignTokens.errorOnTintDark,
    tint: _light ? DesignTokens.errorTintLight : DesignTokens.errorTintDark,
  );

  StateColor get warning => StateColor(
    base: DesignTokens.warning,
    onTint: _light
        ? DesignTokens.warningOnTintLight
        : DesignTokens.warningOnTintDark,
    tint: _light ? DesignTokens.warningTintLight : DesignTokens.warningTintDark,
  );

  StateColor get info => StateColor(
    base: DesignTokens.info,
    onTint: _light ? DesignTokens.infoOnTintLight : DesignTokens.infoOnTintDark,
    tint: _light ? DesignTokens.infoTintLight : DesignTokens.infoTintDark,
  );
}

extension StateColorsX on BuildContext {
  /// Colores de estado del tema actual.
  StateColors get states => StateColors.of(Theme.of(this).brightness);

  /// Atajos que se usan mucho.
  ColorScheme get scheme => Theme.of(this).colorScheme;
  TextTheme get texts => Theme.of(this).textTheme;
}
