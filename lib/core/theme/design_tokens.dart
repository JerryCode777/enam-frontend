import 'package:flutter/material.dart';

/// Tokens de diseño de ENAM Prep.
///
/// Regla: los nombres son **semánticos** (qué hace el color), nunca el nombre
/// del color. Así, si la paleta cambia, el nombre sigue siendo verdadero.
///
/// Los valores que dependen del tema (fondos, textos, bordes) NO se leen desde
/// aquí en los widgets: se leen desde `Theme.of(context)` vía [AppTheme].
/// Esta clase es la única fuente de los valores crudos.
abstract final class DesignTokens {
  // ==================== MARCA ====================

  /// Azul-teal médico. Color de marca y de acción primaria.
  static const Color brand = Color(0xFF2E9BD0);
  static const Color brandDark = Color(0xFF2382B5);
  static const Color brandLight = Color(0xFF6FC2E6);
  static const Color brandSubtle = Color(0xFFE3F0FB);

  // ==================== ESTADOS SEMÁNTICOS ====================
  //
  // `success` es verde y NO el teal de marca, a propósito: en una app de
  // exámenes, "correcto" y "elemento de marca" no pueden compartir color.

  static const Color success = Color(0xFF10B981);
  static const Color successSubtle = Color(0xFFD1FAE5);

  static const Color error = Color(0xFFEF4444);
  static const Color errorSubtle = Color(0xFFFEE2E2);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSubtle = Color(0xFFFEF3C7);

  static const Color info = brand;
  static const Color infoSubtle = brandSubtle;

  // ==================== SUPERFICIES — TEMA CLARO ====================

  static const Color backgroundLight = Color(0xFFF3F4F6);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceElevatedLight = Color(0xFFFAFAFA);
  static const Color borderLight = Color(0xFFC8C8C8);
  static const Color borderSubtleLight = Color(0xFFE5E5E5);

  static const Color textPrimaryLight = Color(0xFF0A0F1C);
  static const Color textSecondaryLight = Color(0xFF6B7280);
  static const Color textTertiaryLight = Color(0xFF9CA3AF);

  // ==================== SUPERFICIES — TEMA OSCURO ====================

  static const Color backgroundDark = Color(0xFF0D1117);
  static const Color backgroundSecondaryDark = Color(0xFF0F1A35);
  static const Color surfaceDark = Color(0xFF0B0E16);
  static const Color surfaceElevatedDark = Color(0xFF1B1D2D);
  static const Color borderDark = Color(0xFF2A3F6B);
  static const Color borderSubtleDark = Color(0xFF1F2D4A);

  static const Color textPrimaryDark = Color(0xFFF3F4F6);
  static const Color textSecondaryDark = Color(0xFFB8C2E0);
  static const Color textTertiaryDark = Color(0xFF8A94B8);

  // ==================== TEXTO SOBRE COLOR ====================

  static const Color onBrand = Color(0xFFFFFFFF);
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onWarning = Color(0xFF0A0F1C);

  // ==================== TIPOGRAFÍA ====================

  static const String fontFamily = 'Manrope';

  static const double fontSizeXs = 12;
  static const double fontSizeSm = 14;
  static const double fontSizeMd = 16; // base
  static const double fontSizeLg = 18;
  static const double fontSizeXl = 20;
  static const double fontSize2xl = 24;
  static const double fontSize3xl = 30;
  static const double fontSize4xl = 36;

  static const double lineHeightTight = 1.25; // títulos
  static const double lineHeightNormal = 1.5; // cuerpo
  static const double lineHeightRelaxed = 1.625; // enunciados clínicos

  // ==================== ESPACIADO (múltiplos de 4) ====================

  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space8 = 32;
  static const double space10 = 40;
  static const double space12 = 48;
  static const double space16 = 64;

  // ==================== FORMA ====================

  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusFull = 999;

  // ==================== ACCESIBILIDAD ====================

  /// Área táctil mínima. Material y WCAG piden 48dp.
  static const double minTouchTarget = 48;

  /// Ancho mínimo que la app debe soportar (RNF-09).
  static const double minScreenWidth = 360;

  // ==================== MOVIMIENTO ====================

  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 250);
  static const Duration durationSlow = Duration(milliseconds: 400);
}
