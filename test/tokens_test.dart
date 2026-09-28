import 'package:enam_app/core/theme/design_tokens.dart';
import 'package:enam_app/core/theme/motion.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ayuda/contraste.dart';

/// Los tokens compartidos con la web y los contrastes que tienen que cumplir.
///
/// Dos cosas distintas se fijan aquí:
///
/// 1. **Los valores exactos.** La web usa los mismos, con los mismos nombres
///    (diseno/TOKENS.md). Si alguien cambia uno aquí sin tocar la tabla y la web,
///    las dos plataformas empiezan a divergir sin que nadie lo note. Este test
///    obliga a que el cambio sea deliberado.
/// 2. **Los contrastes.** WCAG 2.2 AA: 4,5:1 para texto normal y 3:1 para el
///    borde que identifica un control.
void main() {
  group('Valores acordados con la web', () {
    test('claro', () {
      expect(DesignTokens.backgroundLight, const Color(0xFFF5F7FA));
      expect(DesignTokens.backgroundSecondaryLight, const Color(0xFFEAEFF5));
      expect(DesignTokens.surfaceLight, const Color(0xFFFFFFFF));
      expect(DesignTokens.surfaceElevatedLight, const Color(0xFFFAFBFD));
      expect(DesignTokens.borderLight, const Color(0xFF7A8BA0));
      expect(DesignTokens.borderSubtleLight, const Color(0xFFDCE4ED));
      expect(DesignTokens.textPrimaryLight, const Color(0xFF102338));
      expect(DesignTokens.textSecondaryLight, const Color(0xFF526479));
      expect(DesignTokens.textTertiaryLight, const Color(0xFF627286));
      expect(DesignTokens.actionLight, const Color(0xFF176497));
      expect(DesignTokens.actionPressedLight, const Color(0xFF124F78));
      expect(DesignTokens.infoOnTintLight, const Color(0xFF176497));
    });

    test('oscuro', () {
      expect(DesignTokens.backgroundDark, const Color(0xFF182742));
      expect(DesignTokens.surfaceDark, const Color(0xFF22334F));
      expect(DesignTokens.surfaceElevatedDark, const Color(0xFF2B3D5C));
      expect(DesignTokens.borderDark, const Color(0xFF6F8BBA));
      expect(DesignTokens.borderSubtleDark, const Color(0xFF374E75));
      expect(DesignTokens.textPrimaryDark, const Color(0xFFF3F4F6));
      expect(DesignTokens.textSecondaryDark, const Color(0xFFB8C2E0));
      expect(DesignTokens.textTertiaryDark, const Color(0xFFA0AACB));
      expect(DesignTokens.actionDark, const Color(0xFF6FC2E6));
      expect(DesignTokens.actionPressedDark, const Color(0xFF58B4DD));
      expect(DesignTokens.onActionDark, const Color(0xFF0A2540));
    });

    test('forma y movimiento', () {
      expect(DesignTokens.radiusMd, 12);
      expect(DesignTokens.radiusLg, 16);
      expect(DesignTokens.radiusXl, 24);
      expect(DesignTokens.fontSizeClinical, 17);
      expect(DesignTokens.lineHeightClinical, 1.6);
      expect(Motion.fast, const Duration(milliseconds: 140));
      expect(Motion.normal, const Duration(milliseconds: 220));
      expect(Motion.navigation, const Duration(milliseconds: 200));
      expect(Motion.slow, const Duration(milliseconds: 350));
      expect(Motion.stagger, const Duration(milliseconds: 30));
      expect(Motion.maxStaggerIndex, 4);
    });
  });

  group('Contraste AA', () {
    // (nombre, primer plano, fondo, mínimo)
    final pares = <(String, Color, Color, double)>[
      // Claro
      (
        'texto / fondo',
        DesignTokens.textPrimaryLight,
        DesignTokens.backgroundLight,
        4.5,
      ),
      (
        'secundario / fondo',
        DesignTokens.textSecondaryLight,
        DesignTokens.backgroundLight,
        4.5,
      ),
      (
        'terciario / fondo',
        DesignTokens.textTertiaryLight,
        DesignTokens.backgroundLight,
        4.5,
      ),
      (
        'terciario / superficie',
        DesignTokens.textTertiaryLight,
        DesignTokens.surfaceLight,
        4.5,
      ),
      (
        'borde de control / fondo',
        DesignTokens.borderLight,
        DesignTokens.backgroundLight,
        3,
      ),
      (
        'borde de control / superficie',
        DesignTokens.borderLight,
        DesignTokens.surfaceLight,
        3,
      ),
      (
        'acción / su texto',
        DesignTokens.actionLight,
        DesignTokens.onActionLight,
        4.5,
      ),
      (
        'acción como texto / fondo',
        DesignTokens.actionLight,
        DesignTokens.backgroundLight,
        4.5,
      ),
      (
        'info / tinte',
        DesignTokens.infoOnTintLight,
        DesignTokens.infoTintLight,
        4.5,
      ),
      (
        'éxito / tinte',
        DesignTokens.successOnTintLight,
        DesignTokens.successTintLight,
        4.5,
      ),
      (
        'error / tinte',
        DesignTokens.errorOnTintLight,
        DesignTokens.errorTintLight,
        4.5,
      ),
      (
        'aviso / tinte',
        DesignTokens.warningOnTintLight,
        DesignTokens.warningTintLight,
        4.5,
      ),
      (
        'blanco / degradado de marca',
        DesignTokens.onBrand,
        DesignTokens.buttonGradient.last,
        4.5,
      ),
      // Oscuro
      (
        'texto / fondo (osc.)',
        DesignTokens.textPrimaryDark,
        DesignTokens.backgroundDark,
        4.5,
      ),
      (
        'secundario / superficie (osc.)',
        DesignTokens.textSecondaryDark,
        DesignTokens.surfaceDark,
        4.5,
      ),
      (
        'terciario / superficie (osc.)',
        DesignTokens.textTertiaryDark,
        DesignTokens.surfaceDark,
        4.5,
      ),
      (
        'borde de control / superficie (osc.)',
        DesignTokens.borderDark,
        DesignTokens.surfaceDark,
        3,
      ),
      (
        'acción / su texto (osc.)',
        DesignTokens.actionDark,
        DesignTokens.onActionDark,
        4.5,
      ),
      (
        'info / tinte (osc.)',
        DesignTokens.infoOnTintDark,
        DesignTokens.infoTintDark,
        4.5,
      ),
      (
        'éxito / tinte (osc.)',
        DesignTokens.successOnTintDark,
        DesignTokens.successTintDark,
        4.5,
      ),
      (
        'error / tinte (osc.)',
        DesignTokens.errorOnTintDark,
        DesignTokens.errorTintDark,
        4.5,
      ),
      (
        'aviso / tinte (osc.)',
        DesignTokens.warningOnTintDark,
        DesignTokens.warningTintDark,
        4.5,
      ),
    ];

    for (final (nombre, frente, fondo, minimo) in pares) {
      test(nombre, () {
        expect(
          contraste(frente, fondo),
          greaterThanOrEqualTo(minimo),
          reason: '$nombre da ${contraste(frente, fondo).toStringAsFixed(2)}:1',
        );
      });
    }

    test('el azul de marca NO sirve como texto sobre blanco', () {
      // Documenta por qué existe `action`: si esto dejara de ser cierto, se
      // podría simplificar la paleta.
      expect(
        contraste(DesignTokens.brand, DesignTokens.surfaceLight),
        lessThan(4.5),
      );
    });
  });
}
