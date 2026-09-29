import 'package:flutter/material.dart';

/// La figura de marca de ENAM Prep: una doctora, **ilustración generada con
/// IA**. No es una persona real ni una médica del equipo.
///
/// Reglas de uso (`diseno/rediseno/PAQUETE-E-APP.md` §13):
///
/// - Es **decorativa**: el lector de pantalla no la anuncia, y no lleva
///   nombre, cargo, título ni frase que la presente como alguien.
/// - Nunca como testimonio, ni en las pantallas de pago.
/// - La imagen está cortada a la cintura: se coloca apoyada en un borde que
///   tape el corte.
///
/// Los recursos son WebP con transparencia a ~2× del tamaño en pantalla
/// (400 y 300 px de ancho, 46 KB entre los dos). Los originales, de
/// 1024 × 1536, no se versionan.
class FiguraDeMarca extends StatelessWidget {
  const FiguraDeMarca._(this._recurso, this._proporcion, {required this.ancho});

  /// De pie, con los brazos cruzados. Para la presentación.
  const FiguraDeMarca.brazosCruzados({required double ancho})
    : this._(
        'assets/images/doctora_brazos_cruzados.webp',
        592 / 400,
        ancho: ancho,
      );

  /// Señalando hacia su izquierda —la izquierda de quien mira— con una tablet
  /// en la otra mano. Va a la derecha de lo que señala.
  const FiguraDeMarca.senala({required double ancho})
    : this._('assets/images/doctora_senala.webp', 451 / 300, ancho: ancho);

  final String _recurso;
  final double _proporcion;
  final double ancho;

  double get alto => ancho * _proporcion;

  @override
  Widget build(BuildContext context) {
    final pixeles = MediaQuery.devicePixelRatioOf(context);
    return Image.asset(
      _recurso,
      width: ancho,
      height: alto,
      fit: BoxFit.contain,
      alignment: Alignment.bottomCenter,
      // Se decodifica al tamaño en que se pinta, no al del archivo.
      cacheWidth: (ancho * pixeles).round(),
      excludeFromSemantics: true,
      gaplessPlayback: true,
    );
  }
}
