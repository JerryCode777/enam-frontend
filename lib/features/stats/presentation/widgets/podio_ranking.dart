import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/state_colors.dart';
import '../../domain/stats_models.dart';

/// Los tres metales del podio.
///
/// Oro, plata y bronce se leen como puesto sin necesidad de texto. No salen de
/// la paleta de áreas a propósito: esos diez tonos significan «área del
/// blueprint», y reusarlos aquí rompe lo único que los hace legibles.
///
/// Son los mismos valores que en el cliente web (`--color-oro` y compañía), para
/// que las dos plataformas se lean iguales.
abstract final class Metales {
  static const oro = Color(0xFFD4A017);
  static const plata = Color(0xFF9CA3AF);
  static const bronce = Color(0xFFB87333);

  static Color? de(int posicion) => switch (posicion) {
    1 => oro,
    2 => plata,
    3 => bronce,
    _ => null,
  };
}

/// El podio: los tres primeros, en grande.
///
/// Se pintan **2 · 1 · 3** y no 1 · 2 · 3. Es la disposición de un podio de
/// verdad, y hace que el primero quede en el centro y más alto sin necesidad de
/// decir que es el primero: la forma ya lo dice.
///
/// Va sobre el degradado de marca, que es lo que separa esta franja del resto
/// de la pantalla y le da aire de sitio al que se llega, no de tabla que se
/// consulta.
///
/// Con menos de tres personas **no se pinta**: tres peanas con dos llenas y una
/// vacía se leen como un fallo de carga. Lo decide quien lo usa, no esto.
class PodioRanking extends StatelessWidget {
  const PodioRanking({required this.filas, super.key});

  /// Los tres primeros, en orden de posición.
  final List<RankingEntry> filas;

  @override
  Widget build(BuildContext context) {
    if (filas.length < 3) return const SizedBox.shrink();

    final isLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.space3,
        DesignTokens.space5,
        DesignTokens.space3,
        DesignTokens.space4,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLight
              ? DesignTokens.headerGradientLight
              : DesignTokens.headerGradientDark,
          stops: DesignTokens.headerGradientStops,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusXl - 4),
      ),
      // `end` es lo que escalona las tres columnas: cada una declara su alto y
      // todas se apoyan en la misma línea de base.
      //
      // El hueco entre ellas no es estético: pegadas, los tres escalones se
      // funden en una sola mancha clara y deja de leerse que son tres.
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: _Puesto(entrada: filas[1])),
          const SizedBox(width: DesignTokens.space2),
          Expanded(child: _Puesto(entrada: filas[0])),
          const SizedBox(width: DesignTokens.space2),
          Expanded(child: _Puesto(entrada: filas[2])),
        ],
      ),
    );
  }
}

class _Puesto extends StatelessWidget {
  const _Puesto({required this.entrada});

  final RankingEntry entrada;

  /// Alto del escalón. El primero manda.
  ///
  /// Los tres tienen que caber el nombre, la universidad y la nota; la
  /// diferencia entre ellos es el hueco que sobra abajo, que es justo lo que
  /// dibuja el escalón.
  double get _alto => switch (entrada.posicion) {
    1 => 104,
    2 => 88,
    3 => 76,
    _ => 76,
  };

  /// Espacio reservado para la corona en LOS TRES.
  ///
  /// Solo la lleva el primero, pero si los otros dos no reservan su hueco sus
  /// círculos suben y el escalonado deja de venir del escalón.
  static const _altoCorona = 24.0;

  /// Igual con el círculo: el del primero es mayor, así que la caja es común y
  /// el círculo se centra dentro.
  static const _altoCirculo = 54.0;

  @override
  Widget build(BuildContext context) {
    final esPrimero = entrada.posicion == 1;
    final metal = Metales.de(entrada.posicion) ?? Metales.bronce;
    final diametro = esPrimero ? 50.0 : 40.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: _altoCorona,
          child: esPrimero
              ? const Icon(Symbols.crown, size: 20, fill: 1, color: Metales.oro)
              : null,
        ),

        SizedBox(
          height: _altoCirculo,
          // Abajo y no centrado: así cada número se apoya en SU escalón en vez
          // de flotar sobre él. Es lo que hace que se lea "está subido ahí".
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: diametro,
              height: diametro,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.15),
                border: Border.all(color: metal, width: 2),
              ),
              child: Text(
                '${entrada.posicion}',
                style: context.texts.titleMedium?.copyWith(
                  fontSize: esPrimero ? 19 : 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: DesignTokens.space2),

        // El escalón, con el nombre y la nota DENTRO.
        //
        // Antes flotaban encima y cada columna los ponía a una altura distinta,
        // así que los nombres de los laterales se metían en el escalón del
        // centro y el conjunto se leía desordenado. Metidos dentro, cada
        // escalón es una pieza cerrada y lo único que varía es su alto.
        Container(
          height: _alto,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: DesignTokens.space2,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.13),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(DesignTokens.radiusMd),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                entrada.esUsuarioActual ? 'Tú' : entrada.usuarioNombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: context.texts.bodyLarge?.copyWith(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  color: Colors.white,
                ),
              ),
              if (entrada.universidad != null)
                Text(
                  entrada.universidad!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: context.texts.bodySmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              const SizedBox(height: 3),
              Text(
                // Siempre 2 decimales (RN-01). En blanco y no en el metal:
                // sobre este degradado el bronce no llega al contraste mínimo,
                // y una nota que no se lee no es una nota. El metal ya está
                // donde importa, en el aro del número.
                entrada.promedio.toStringAsFixed(2),
                style: context.texts.bodyLarge?.copyWith(
                  fontSize: esPrimero ? 17 : 15,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
