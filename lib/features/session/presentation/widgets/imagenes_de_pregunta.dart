import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/state_colors.dart';
import '../../domain/session_models.dart';

/// De dónde sale cada imagen: de la caché en disco por URL. Las URLs del banco
/// son públicas y nunca cambian de contenido con el mismo nombre (el cargador
/// del backend lo impide), así que guardar por URL es seguro y sirve sin red.
///
/// Se puede cambiar en las pruebas, donde no hay red ni disco.
@visibleForTesting
ImageProvider Function(String url) proveedorDeImagen =
    CachedNetworkImageProvider.new;

/// Las imágenes de una pregunta (ECG, radiografías, tablas), cada una con su
/// crédito debajo. Se tocan para verlas a pantalla completa.
///
/// **Nunca empujan las opciones fuera de la pantalla:** cada imagen ocupa como
/// mucho un 30 % del alto (y 260 px), con su proporción. Un ECG de 12
/// derivaciones no se lee en miniatura de todas formas: para eso está el visor.
class ImagenesDePregunta extends StatelessWidget {
  const ImagenesDePregunta({required this.imagenes, super.key});

  final List<ImagenDetalle> imagenes;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < imagenes.length; i++) ...[
          if (i > 0) const SizedBox(height: DesignTokens.space3),
          _ImagenEnLinea(
            imagen: imagenes[i],
            numero: imagenes.length > 1 ? i + 1 : null,
          ),
        ],
      ],
    );
  }
}

class _ImagenEnLinea extends StatefulWidget {
  const _ImagenEnLinea({required this.imagen, this.numero});

  final ImagenDetalle imagen;

  /// «Imagen 2», cuando hay más de una.
  final int? numero;

  @override
  State<_ImagenEnLinea> createState() => _ImagenEnLineaState();
}

class _ImagenEnLineaState extends State<_ImagenEnLinea> {
  /// Sube al reintentar: una clave nueva fuerza a volver a pedirla.
  var _intento = 0;

  Future<void> _reintentar() async {
    await proveedorDeImagen(widget.imagen.url).evict();
    if (mounted) setState(() => _intento++);
  }

  void _ampliar() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => VisorDeImagen(imagen: widget.imagen),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final imagen = widget.imagen;
    final descripcion = imagen.alt?.trim().isNotEmpty ?? false
        ? imagen.alt!.trim()
        : 'Imagen de la pregunta';
    final altoMaximo = (MediaQuery.sizeOf(context).height * 0.3).clamp(
      140.0,
      260.0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, limites) {
            final proporcion = imagen.proporcion ?? 16 / 9;
            final alto = (limites.maxWidth / proporcion).clamp(0.0, altoMaximo);
            return Semantics(
              image: true,
              button: true,
              label: widget.numero == null
                  ? descripcion
                  : 'Imagen ${widget.numero}: $descripcion',
              hint: 'Toca dos veces para ampliar',
              excludeSemantics: true,
              child: Material(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: _ampliar,
                  child: SizedBox(
                    height: alto,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image(
                          key: ValueKey(_intento),
                          image: proveedorDeImagen(imagen.url),
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                          frameBuilder: (context, hijo, cuadro, sincrona) =>
                              sincrona || cuadro != null
                              ? hijo
                              : const _Cargando(),
                          errorBuilder: (context, _, _) =>
                              _NoCargo(onReintentar: _reintentar),
                        ),
                        Positioned(
                          right: DesignTokens.space2,
                          bottom: DesignTokens.space2,
                          child: _EtiquetaAmpliar(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        if (imagen.credito case final credito?) ...[
          const SizedBox(height: DesignTokens.space1 + 2),
          Text(
            credito,
            style: context.texts.bodySmall?.copyWith(
              fontSize: 12,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _EtiquetaAmpliar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space2,
        vertical: DesignTokens.space1,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Symbols.zoom_in, size: 16, color: Colors.white),
          SizedBox(width: DesignTokens.space1),
          Text(
            'Ampliar',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Cargando extends StatelessWidget {
  const _Cargando();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Symbols.image,
            size: 32,
            color: context.scheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
          const SizedBox(height: DesignTokens.space2),
          const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      ),
    );
  }
}

class _NoCargo extends StatelessWidget {
  const _NoCargo({required this.onReintentar});

  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Symbols.broken_image,
              size: 28,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: DesignTokens.space1),
            Text(
              'No pudimos cargar la imagen.',
              textAlign: TextAlign.center,
              style: context.texts.bodySmall,
            ),
            TextButton(
              onPressed: onReintentar,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// La imagen a pantalla completa: pellizco para acercar, arrastrar para
/// moverse, doble toque para acercar o volver. Se puede girar el teléfono: un
/// ECG apaisado se lee mucho mejor en horizontal. Al cerrar, la app vuelve a
/// vertical.
class VisorDeImagen extends StatefulWidget {
  const VisorDeImagen({required this.imagen, super.key});

  final ImagenDetalle imagen;

  @override
  State<VisorDeImagen> createState() => _VisorDeImagenState();
}

class _VisorDeImagenState extends State<VisorDeImagen> {
  final _transformacion = TransformationController();
  TapDownDetails? _dobleToque;

  /// Las de `main.dart`: la app se estudia en vertical.
  static const _vertical = [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ];

  @override
  void initState() {
    super.initState();
    unawaited(
      SystemChrome.setPreferredOrientations([
        ..._vertical,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]),
    );
  }

  @override
  void dispose() {
    unawaited(SystemChrome.setPreferredOrientations(_vertical));
    _transformacion.dispose();
    super.dispose();
  }

  void _alternarZoom() {
    if (_transformacion.value != Matrix4.identity()) {
      _transformacion.value = Matrix4.identity();
      return;
    }
    final punto = _dobleToque?.localPosition ?? Offset.zero;
    const escala = 2.5;
    _transformacion.value = Matrix4.identity()
      ..translateByDouble(
        -punto.dx * (escala - 1),
        -punto.dy * (escala - 1),
        0,
        1,
      )
      ..scaleByDouble(escala, escala, 1, 1);
  }

  @override
  Widget build(BuildContext context) {
    final imagen = widget.imagen;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onDoubleTapDown: (d) => _dobleToque = d,
              onDoubleTap: _alternarZoom,
              child: InteractiveViewer(
                transformationController: _transformacion,
                minScale: 1,
                maxScale: 6,
                child: Center(
                  child: Semantics(
                    image: true,
                    label: imagen.alt ?? 'Imagen de la pregunta',
                    child: Image(
                      image: proveedorDeImagen(imagen.url),
                      fit: BoxFit.contain,
                      errorBuilder: (context, _, _) => const Icon(
                        Symbols.broken_image,
                        size: 48,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: IconButton(
                tooltip: 'Cerrar',
                icon: const Icon(Symbols.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          if (imagen.credito case final credito?)
            SafeArea(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.all(DesignTokens.space3),
                  child: Text(
                    credito,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Deja en la caché del disco las imágenes de [preguntas], para verlas sin
/// red (paquetes offline). No falla nunca: una imagen que no baja se pedirá
/// al verla, y la descarga del área sigue siendo buena.
Future<void> guardarImagenesDePreguntas(Iterable<Question> preguntas) async {
  final urls = {
    for (final p in preguntas)
      for (final i in p.imagenesAMostrar) i.url,
  };
  for (final url in urls) {
    try {
      await DefaultCacheManager().downloadFile(url);
    } catch (_) {
      // Se intenta al verla.
    }
  }
}
