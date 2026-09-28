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

  /// Azul-teal médico. Color de marca **decorativo**: iconos grandes,
  /// ilustración, portada. Sobre blanco da 3,1:1, así que nunca va como color
  /// de texto pequeño ni como fondo de un texto blanco. Para eso está [action].
  static const Color brand = Color(0xFF2E9BD0);
  static const Color brandDark = Color(0xFF2382B5);
  static const Color brandLight = Color(0xFF6FC2E6);
  static const Color brandSubtle = Color(0xFFE3F0FB);

  // ==================== ACCIÓN PRIMARIA ====================
  //
  // El relleno del botón principal y el texto de marca que se puede leer. Antes
  // el botón era un degradado que terminaba en [brand], y el texto blanco caía a
  // 3,1:1 en ese extremo. Ahora es un color plano que cumple AA en los dos
  // temas, con los mismos valores que la web (docs/TOKENS.md).

  /// Claro: blanco encima da 6,35:1.
  static const Color actionLight = Color(0xFF176497);
  static const Color actionPressedLight = Color(0xFF124F78);
  static const Color onActionLight = Color(0xFFFFFFFF);

  /// Oscuro: el relleno se aclara y el texto pasa a azul marino (7,8:1). Un
  /// azul medio con texto blanco se perdía sobre el fondo marino.
  static const Color actionDark = Color(0xFF6FC2E6);
  static const Color actionPressedDark = Color(0xFF58B4DD);
  static const Color onActionDark = Color(0xFF0A2540);

  // ==================== ESTADOS SEMÁNTICOS ====================
  //
  // `success` es verde y NO el teal de marca, a propósito: en una app de
  // exámenes, "correcto" y "elemento de marca" no pueden compartir color.
  //
  // Cada estado tiene tres piezas, y hacen falta las tres:
  //   - base:   el color del icono, el borde o el relleno de un botón
  //   - onTint: el color del **texto** puesto sobre `tint`
  //   - tint:   el fondo tenue de un banner o una tarjeta
  //
  // El `base` no cumple contraste AA sobre `tint` — por eso existe `onTint`, que
  // es el mismo tono oscurecido (en claro) o aclarado (en oscuro). Sin esa
  // tercera pieza, todo banner de estado queda por debajo de 4.5:1.

  static const Color success = Color(0xFF10B981);
  static const Color successOnTintLight = Color(0xFF047857);
  static const Color successOnTintDark = Color(0xFF34D399);
  static const Color successTintLight = Color(0xFFECFDF5);
  static const Color successTintDark = Color(0xFF0B2E22);

  static const Color error = Color(0xFFEF4444);
  static const Color errorOnTintLight = Color(0xFFB91C1C);
  static const Color errorOnTintDark = Color(0xFFF87171);
  static const Color errorTintLight = Color(0xFFFEF2F2);
  static const Color errorTintDark = Color(0xFF3A1214);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningOnTintLight = Color(0xFFB45309);
  static const Color warningOnTintDark = Color(0xFFFBBF24);
  static const Color warningTintLight = Color(0xFFFFFBEB);
  static const Color warningTintDark = Color(0xFF33240A);

  static const Color info = brand;
  static const Color infoOnTintLight = actionLight; // 5,5:1 sobre el tinte
  static const Color infoOnTintDark = brandLight;
  static const Color infoTintLight = brandSubtle;
  static const Color infoTintDark = Color(0xFF2A4570); // 4,8:1 con su texto

  // ==================== GRADIENTES ====================
  //
  // El diseño usa degradado en las cabeceras y en los botones principales. Se
  // definen como listas de paradas para poder construir el `LinearGradient` con
  // la geometría que pida cada uso.

  /// Cabeceras de pantalla, en diagonal.
  static const List<Color> headerGradientLight = [
    Color(0xFF0A2540),
    Color(0xFF16548C),
    Color(0xFF2E9BD0),
  ];
  static const List<Color> headerGradientDark = [
    Color(0xFF14213A),
    Color(0xFF1B3A66),
    Color(0xFF2E76B4),
  ];
  static const List<double> headerGradientStops = [0.0, 0.55, 1.0];

  /// Superficies de marca pulsables que llevan texto blanco (la tarjeta del
  /// duelo, por ejemplo). **No** es el relleno del botón principal: ese es
  /// [actionLight] plano. Las dos paradas dejan el blanco por encima de 4,5:1
  /// en todo el recorrido.
  static const List<Color> buttonGradient = [
    Color(0xFF124F78),
    Color(0xFF176497),
  ];

  // ==================== SUPERFICIES — TEMA CLARO ====================

  // Fondo con un matiz frío y texto azul marino, en vez de gris neutro y casi
  // negro: es la dirección visual del rediseño (plan §3). Los contrastes están
  // medidos contra el fondo, que es donde más texto cae.

  static const Color backgroundLight = Color(0xFFF5F7FA);

  /// Pistas de barra y fondos hundidos.
  static const Color backgroundSecondaryLight = Color(0xFFEAEFF5);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceElevatedLight = Color(0xFFFAFBFD);

  /// Borde de **controles** (campos, casillas): 3,3:1 sobre el fondo, el mínimo
  /// de WCAG para distinguir un componente. El de antes daba 1,7:1.
  static const Color borderLight = Color(0xFF7A8BA0);

  /// Separadores y contorno de tarjetas. Decorativo, no identifica nada.
  static const Color borderSubtleLight = Color(0xFFDCE4ED);

  static const Color textPrimaryLight = Color(0xFF102338); // 14,8:1
  static const Color textSecondaryLight = Color(0xFF526479); // 5,7:1
  static const Color textTertiaryLight = Color(0xFF627286); // 4,6:1

  // ==================== SUPERFICIES — TEMA OSCURO ====================
  //
  // Azul marino, no casi negro. Es una decisión del diseño: un oscuro con
  // temperatura se lee mejor de noche en sesiones largas que un gris neutro, y
  // conserva la identidad de marca en ambos temas.

  static const Color backgroundDark = Color(0xFF182742);
  static const Color backgroundSecondaryDark = Color(0xFF2B3D5C);
  static const Color surfaceDark = Color(0xFF22334F);
  static const Color surfaceElevatedDark = Color(0xFF2B3D5C);
  /// Borde de controles: 3,7:1 sobre la superficie (el de antes, 2,2:1).
  static const Color borderDark = Color(0xFF6F8BBA);
  static const Color borderSubtleDark = Color(0xFF374E75);

  static const Color textPrimaryDark = Color(0xFFF3F4F6);
  static const Color textSecondaryDark = Color(0xFFB8C2E0);
  static const Color textTertiaryDark = Color(0xFFA0AACB); // 5,5:1

  // ==================== TEXTO SOBRE COLOR ====================

  /// Texto sobre superficies de marca oscuras (portadas, [buttonGradient]).
  static const Color onBrand = Color(0xFFFFFFFF);
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onWarning = Color(0xFF0A0F1C);

  // ==================== TIPOGRAFÍA ====================

  static const String fontFamily = 'Nunito';

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
  static const double lineHeightRelaxed = 1.6; // párrafos largos

  /// Enunciados clínicos: 17 px con interlineado 1,6 (plan §3). Es el texto que
  /// más se lee en la app, casi siempre cansado y en párrafos largos.
  static const double fontSizeClinical = 17;
  static const double lineHeightClinical = 1.6;

  // ==================== ESPACIADO (múltiplos de 4) ====================

  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space7 = 28;
  static const double space8 = 32;
  static const double space10 = 40;
  static const double space12 = 48;
  static const double space16 = 64;
  static const double space24 = 96;

  // ==================== FORMA ====================

  static const double radiusSm = 8;

  /// Controles: botones, campos, selectores.
  static const double radiusMd = 12;

  /// Tarjetas.
  static const double radiusLg = 16;

  /// Contenedores destacados: el bloque de siguiente acción, las hojas.
  static const double radiusXl = 24;

  /// Píldoras para etiquetas cortas.
  static const double radiusFull = 999;

  // ==================== ACCESIBILIDAD ====================

  /// Área táctil mínima. Material y WCAG piden 48dp.
  static const double minTouchTarget = 48;

  /// Ancho mínimo que la app debe soportar (RNF-09).
  static const double minScreenWidth = 360;

  // ==================== MOVIMIENTO ====================

  // Los valores viven en `Motion`; se repiten aquí solo para la tabla de
  // correspondencia con la web.
  static const Duration durationFast = Duration(milliseconds: 140);
  static const Duration durationNormal = Duration(milliseconds: 220);
  static const Duration durationSlow = Duration(milliseconds: 350);
}
