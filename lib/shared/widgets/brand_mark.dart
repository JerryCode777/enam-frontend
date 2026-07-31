import 'package:flutter/material.dart';

import '../../core/theme/design_tokens.dart';

/// La marca de ENAM Prep: una cruz médica con el latido dentro.
///
/// Se dibuja, no se carga como imagen: así es nítida a cualquier tamaño, toma
/// el color que le pida cada pantalla y no obliga a empaquetar un PNG por
/// densidad. Es el mismo trazo que el icono de la app
/// (`assets/images/logo.svg`), para que icono y pantallas se lean como la
/// misma marca.
///
/// Sobre fondo de color se usa suelta ([BrandMark]); sobre fondo claro, dentro
/// de su cuadro con degradado ([BrandMarkTile]).
class BrandMark extends StatelessWidget {
  const BrandMark({
    this.size = 48,
    this.color = Colors.white,
    this.colorLatido,
    super.key,
  });

  final double size;

  /// Color de la cruz.
  final Color color;

  /// Color del latido recortado en el brazo horizontal. Por defecto, el azul
  /// de marca, que es lo que hace legible el recorte sobre la cruz blanca.
  final Color? colorLatido;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _MarcaPainter(
          color: color,
          colorLatido: colorLatido ?? const Color(0xFF16548C),
        ),
      ),
    );
  }
}

/// La marca dentro de su cuadro con el degradado de la app.
///
/// Es el icono tal cual, para cabeceras sobre fondo claro.
class BrandMarkTile extends StatelessWidget {
  const BrandMarkTile({this.size = 64, this.radio, super.key});

  final double size;
  final double? radio;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLight
              ? DesignTokens.headerGradientLight
              : DesignTokens.headerGradientDark,
          stops: DesignTokens.headerGradientStops,
        ),
        borderRadius: BorderRadius.circular(radio ?? size * 0.26),
      ),
      child: BrandMark(size: size * 0.62),
    );
  }
}

class _MarcaPainter extends CustomPainter {
  const _MarcaPainter({required this.color, required this.colorLatido});

  final Color color;
  final Color colorLatido;

  /// El trazo viene del SVG, que está sobre un lienzo de 1024 con el margen
  /// que necesita un icono de app. Aquí se dibuja **ajustado a la cruz**
  /// (520×520 a partir de 252,252): como marca suelta ese margen sobra, y con
  /// él la cruz salía a la mitad de tamaño y el latido no se leía.
  static const _origen = 252.0;
  static const _lienzo = 520.0;

  static final _vertical = RRect.fromLTRBR(447, 252, 577, 772, const Radius.circular(34));
  static final _horizontal = RRect.fromLTRBR(252, 447, 772, 577, const Radius.circular(34));

  static final _latido = Path()
    ..moveTo(312, 512)
    ..lineTo(424, 512)
    ..lineTo(452, 476)
    ..lineTo(488, 556)
    ..lineTo(524, 468)
    ..lineTo(556, 540)
    ..lineTo(582, 512)
    ..lineTo(712, 512);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / _lienzo, size.height / _lienzo);
    canvas.translate(-_origen, -_origen);

    final cruz = Paint()..color = color;
    canvas.drawRRect(_vertical, cruz);
    canvas.drawRRect(_horizontal, cruz);

    // El latido solo dentro del brazo horizontal: fuera de ahí rompería la
    // silueta de la cruz, que es lo que se reconoce a tamaño pequeño.
    canvas.save();
    canvas.clipRRect(_horizontal);
    canvas.drawPath(
      _latido,
      Paint()
        ..color = colorLatido
        ..style = PaintingStyle.stroke
        ..strokeWidth = 30
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();

    canvas.restore();
  }

  @override
  bool shouldRepaint(_MarcaPainter old) =>
      old.color != color || old.colorLatido != colorLatido;
}
