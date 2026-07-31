import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// Construye los temas claro y oscuro de la app.
///
/// Los widgets leen colores desde `Theme.of(context)`, no desde [DesignTokens]
/// directamente. Así una pantalla funciona en ambos temas sin condicionales.
abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: isLight ? DesignTokens.brand : DesignTokens.brandLight,
      onPrimary: isLight ? DesignTokens.onBrand : DesignTokens.textPrimaryLight,
      primaryContainer:
          isLight ? DesignTokens.brandSubtle : DesignTokens.brandDark,
      onPrimaryContainer:
          isLight ? DesignTokens.brandDark : DesignTokens.brandSubtle,
      secondary: isLight ? DesignTokens.brandDark : DesignTokens.brandLight,
      onSecondary: DesignTokens.onBrand,
      error: DesignTokens.error,
      onError: DesignTokens.onError,
      errorContainer: isLight
          ? DesignTokens.errorTintLight
          : DesignTokens.errorTintDark,
      onErrorContainer: isLight
          ? DesignTokens.errorOnTintLight
          : DesignTokens.errorOnTintDark,
      surface: isLight ? DesignTokens.surfaceLight : DesignTokens.surfaceDark,
      onSurface:
          isLight ? DesignTokens.textPrimaryLight : DesignTokens.textPrimaryDark,
      onSurfaceVariant: isLight
          ? DesignTokens.textSecondaryLight
          : DesignTokens.textSecondaryDark,
      surfaceContainerLowest:
          isLight ? DesignTokens.surfaceLight : DesignTokens.surfaceDark,
      surfaceContainer: isLight
          ? DesignTokens.backgroundLight
          : DesignTokens.backgroundSecondaryDark,
      surfaceContainerHighest: isLight
          ? DesignTokens.surfaceElevatedLight
          : DesignTokens.surfaceElevatedDark,
      outline: isLight ? DesignTokens.borderLight : DesignTokens.borderDark,
      outlineVariant:
          isLight ? DesignTokens.borderSubtleLight : DesignTokens.borderSubtleDark,
    );

    final textTheme = _textTheme(colorScheme);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor:
          isLight ? DesignTokens.backgroundLight : DesignTokens.backgroundDark,
      textTheme: textTheme,
      fontFamily: DesignTokens.fontFamily,

      appBarTheme: AppBarTheme(
        backgroundColor:
            isLight ? DesignTokens.backgroundLight : DesignTokens.backgroundDark,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),

      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg + 2),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),

      // Etiquetas de 12: es el mínimo de la escala y no baja aunque el texto
      // largo ("Simulacros") quede justo.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: isLight
            ? DesignTokens.brandSubtle
            : DesignTokens.infoTintDark,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final activa = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: DesignTokens.fontSizeXs,
            fontWeight: activa ? FontWeight.w800 : FontWeight.w600,
            color: activa ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final activa = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 22,
            color: activa ? colorScheme.primary : colorScheme.onSurfaceVariant,
          );
        }),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          // Ancho mínimo finito: Size.fromHeight daría ancho infinito y
          // reventaría cualquier botón dentro de un Row.
          minimumSize: const Size(64, DesignTokens.minTouchTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          // Ancho mínimo finito: Size.fromHeight daría ancho infinito y
          // reventaría cualquier botón dentro de un Row.
          minimumSize: const Size(64, DesignTokens.minTouchTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          ),
          side: BorderSide(color: colorScheme.outline),
          textStyle: textTheme.labelLarge,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(
            DesignTokens.minTouchTarget,
            DesignTokens.minTouchTarget,
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight
            ? DesignTokens.surfaceLight
            : DesignTokens.surfaceElevatedDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space4,
          vertical: DesignTokens.space4,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          borderSide: const BorderSide(color: DesignTokens.error),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
        ),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(DesignTokens.radiusXl),
          ),
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.outlineVariant,
      ),
    );
  }

  static TextTheme _textTheme(ColorScheme scheme) {
    // Nunito viene del bundle (ver pubspec), no de la red: la app tiene modo
    // offline y la marca no puede depender de que haya señal.
    final base = ThemeData(fontFamily: DesignTokens.fontFamily).textTheme;

    return base.copyWith(
      displaySmall: base.displaySmall?.copyWith(
        fontSize: DesignTokens.fontSize4xl,
        height: DesignTokens.lineHeightTight,
        fontWeight: FontWeight.w800,
        color: scheme.onSurface,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        fontSize: DesignTokens.fontSize3xl,
        height: DesignTokens.lineHeightTight,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: DesignTokens.fontSize2xl,
        height: DesignTokens.lineHeightTight,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: DesignTokens.fontSizeXl,
        height: DesignTokens.lineHeightTight,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: DesignTokens.fontSizeLg,
        height: DesignTokens.lineHeightNormal,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: DesignTokens.fontSizeMd,
        height: DesignTokens.lineHeightNormal,
        color: scheme.onSurface,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: DesignTokens.fontSizeSm,
        height: DesignTokens.lineHeightNormal,
        color: scheme.onSurfaceVariant,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: DesignTokens.fontSizeXs,
        height: DesignTokens.lineHeightNormal,
        color: scheme.onSurfaceVariant,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: DesignTokens.fontSizeMd,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// Estilo para enunciados clínicos.
  ///
  /// El 90 % de las preguntas del ENAM son casos clínicos de varios párrafos, y
  /// se leen cansado. Interlineado holgado y color de máximo contraste. Es la
  /// decisión tipográfica más importante de la app: no la bajes.
  static TextStyle clinicalCase(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextStyle(
      fontFamily: DesignTokens.fontFamily,
      fontSize: DesignTokens.fontSizeMd,
      height: DesignTokens.lineHeightRelaxed,
      color: scheme.onSurface,
      letterSpacing: 0.1,
    );
  }
}
