import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/theme/area_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/state_colors.dart';
import '../../domain/aula_models.dart';

/// Las piezas que se repiten en el catálogo, el curso y la clase. Son las de
/// `Presentacion.tsx` de la web, con los mismos textos.

/// El color del curso: el de su área, o el de marca en el repaso final, que no
/// es de ninguna.
Color colorDeCurso(BuildContext context, String? areaId) => areaId == null
    ? context.scheme.primary
    : AreaColors.of(areaId, Theme.of(context).brightness);

/// La ruta de una URL firmada, sin la firma: la clave de la caché.
///
/// La firma cambia cada vez que se pide (caduca, y se redondea al cuarto de
/// hora), así que indexar por la URL entera descargaría y decodificaría la
/// misma imagen en cada visita.
String sinFirma(String url) {
  final uri = Uri.tryParse(url);
  return uri == null ? url : uri.replace(query: '').toString();
}

/// Cómo se consigue la imagen de una URL, decodificada a [ancho] píxeles.
///
/// En la app, con caché en disco (`cached_network_image`) y en memoria (el
/// `ImageCache` de Flutter, que compara por la clave sin firma): volver a una
/// portada al hacer scroll no la pide ni la decodifica otra vez. Las pruebas lo
/// cambian por imágenes locales.
typedef ImagenDeRed = ImageProvider Function(String url, {int? ancho});

final imagenDeRedProvider = Provider<ImagenDeRed>(
  (ref) =>
      (url, {ancho}) => CachedNetworkImageProvider(
        url,
        cacheKey: sinFirma(url),
        maxWidth: ancho,
      ),
);

/// Una imagen firmada, decodificada al ancho en que se pinta.
///
/// Una portada viene a 1600 px; decodificarla entera para una tarjeta de 400
/// gasta cuatro veces la memoria y hace saltar el scroll.
class ImagenFirmada extends ConsumerWidget {
  const ImagenFirmada({
    required this.url,
    this.fit = BoxFit.cover,
    this.alFallar,
    super.key,
  });

  final String url;
  final BoxFit fit;
  final Widget? alFallar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imagen = ref.watch(imagenDeRedProvider);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(
      builder: (context, c) {
        // En escalones de 200 px: el ancho entra en la clave de la caché, y
        // así un píxel de diferencia no la invalida.
        final ancho = c.hasBoundedWidth
            ? ((c.maxWidth * dpr / 200).ceil() * 200)
            : null;
        return Image(
          image: imagen(url, ancho: ancho),
          fit: fit,
          width: double.infinity,
          height: double.infinity,
          gaplessPlayback: true,
          frameBuilder: (context, hijo, cuadro, sincrono) => sincrono
              ? hijo
              : AnimatedOpacity(
                  opacity: cuadro == null ? 0 : 1,
                  duration: DesignTokens.durationFast,
                  child: hijo,
                ),
          errorBuilder: (_, _, _) => alFallar ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

/// La portada: la imagen del curso o, sin ella, un degradado con el color del
/// área, su icono y el título.
///
/// Las portadas compuestas ya traen el nombre del curso, el profe y las
/// clases: se pintan tal cual, sin nada encima, y el título va para el lector
/// de pantalla.
class PortadaDeCurso extends StatelessWidget {
  const PortadaDeCurso({
    required this.titulo,
    required this.areaId,
    this.portadaUrl,
    this.radio = DesignTokens.radiusLg,
    super.key,
  });

  final String titulo;
  final String? areaId;
  final String? portadaUrl;
  final double radio;

  @override
  Widget build(BuildContext context) {
    final color = colorDeCurso(context, areaId);
    final sinImagen = _SinPortada(titulo: titulo, areaId: areaId, color: color);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radio),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: switch (portadaUrl) {
          final url? => Semantics(
            label: titulo,
            image: true,
            child: ExcludeSemantics(
              child: ImagenFirmada(url: url, alFallar: sinImagen),
            ),
          ),
          null => sinImagen,
        },
      ),
    );
  }
}

class _SinPortada extends StatelessWidget {
  const _SinPortada({
    required this.titulo,
    required this.areaId,
    required this.color,
  });

  final String titulo;
  final String? areaId;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, Colors.black, 0.35)!],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -12,
            right: -8,
            child: Icon(
              areaId == null ? Symbols.school : AreaColors.iconOf(areaId!),
              size: 96,
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          Positioned(
            left: DesignTokens.space4,
            right: DesignTokens.space4,
            bottom: DesignTokens.space3,
            child: Text(
              titulo,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.texts.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                height: DesignTokens.lineHeightTight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// El retrato del profe, o sus iniciales sin «Profe» en el color del curso.
class RetratoDelProfe extends StatelessWidget {
  const RetratoDelProfe({
    required this.profe,
    required this.areaId,
    this.tamano = 32,
    super.key,
  });

  final Profe profe;
  final String? areaId;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    final color = colorDeCurso(context, areaId);
    final url = tamano > 48
        ? profe.retratoUrl ?? profe.retratoMiniUrl
        : profe.retratoMiniUrl ?? profe.retratoUrl;
    final iniciales = Container(
      color: color,
      alignment: Alignment.center,
      child: Text(
        _iniciales(profe.nombre),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: tamano * 0.4,
        ),
      ),
    );
    return ExcludeSemantics(
      child: ClipOval(
        child: SizedBox.square(
          dimension: tamano,
          child: url == null
              ? iniciales
              : ImagenFirmada(url: url, alFallar: iniciales),
        ),
      ),
    );
  }

  static String _iniciales(String nombre) {
    final partes = nombre
        .replaceFirst(RegExp(r'^Profe\s+', caseSensitive: false), '')
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty);
    return partes.take(2).map((p) => p[0].toUpperCase()).join();
  }
}

/// El profe con su retrato, y debajo lo que se quiera decir de él.
class LineaDelProfe extends StatelessWidget {
  const LineaDelProfe({
    required this.profe,
    required this.areaId,
    this.subtitulo,
    this.tamano = 28,
    super.key,
  });

  final Profe profe;
  final String? areaId;
  final String? subtitulo;
  final double tamano;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        RetratoDelProfe(profe: profe, areaId: areaId, tamano: tamano),
        const SizedBox(width: DesignTokens.space2),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profe.nombre,
                style: context.texts.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitulo case final s?)
                Text(s, style: context.texts.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

/// Una pastilla de texto.
class _Pastilla extends StatelessWidget {
  const _Pastilla({
    required this.texto,
    required this.fondo,
    required this.color,
  });

  final String texto;
  final Color fondo;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
      ),
      child: Text(
        texto,
        style: context.texts.labelSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

/// «Gratis»: de la muestra del curso.
class EtiquetaGratis extends StatelessWidget {
  const EtiquetaGratis({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.states.success;
    return _Pastilla(texto: 'Gratis', fondo: s.tint, color: s.onTint);
  }
}

/// «Próximamente»: en el temario, todavía sin video.
class EtiquetaProximamente extends StatelessWidget {
  const EtiquetaProximamente({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return _Pastilla(
      texto: 'Próximamente',
      fondo: scheme.surfaceContainerHighest,
      color: scheme.onSurfaceVariant,
    );
  }
}

/// Una barra de avance fina.
class BarraDeAvance extends StatelessWidget {
  const BarraDeAvance({
    required this.valor,
    required this.etiqueta,
    this.alto = 6,
    this.color,
    super.key,
  });

  final double valor;
  final String etiqueta;
  final double alto;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: etiqueta,
      value: '${(valor * 100).round()} %',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
        child: LinearProgressIndicator(
          value: valor.clamp(0, 1),
          minHeight: alto,
          color: color ?? context.scheme.primary,
          backgroundColor: context.scheme.surfaceContainerHighest,
        ),
      ),
    );
  }
}
