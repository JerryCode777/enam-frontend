import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/providers.dart';
import '../../../core/theme/area_colors.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/state_colors.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../../shared/widgets/state_banner.dart';
import '../../catalog/domain/catalog_models.dart';

/// Estado de descarga de un área.
enum DownloadState { noDescargada, descargando, descargada, actualizable }

/// Un paquete descargable por área (RF-30).
typedef Paquete = ({
  String areaId,
  String nombre,
  int preguntas,
  int megas,
  DownloadState estado,
  double progreso,
  int preguntasNuevas,
});

/// Paquetes offline. Falta `GET /offline/packages` conectado a SQLite local.
final paquetesProvider = Provider<List<Paquete>>((ref) {
  final arbol = ref.watch(catalogProvider).value ?? const <CatalogNode>[];

  // Los cuatro primeros con estados distintos, para poder ver los cuatro casos.
  const estados = [
    (DownloadState.descargada, 1.0, 0),
    (DownloadState.descargando, 0.56, 0),
    (DownloadState.actualizable, 1.0, 46),
    (DownloadState.noDescargada, 0.0, 0),
  ];

  return [
    for (var i = 0; i < arbol.length; i++)
      (
        areaId: arbol[i].id,
        nombre: arbol[i].nombre,
        preguntas: arbol[i].preguntasDisponibles,
        // ~120 KB por pregunta con sus imágenes comprimidas.
        megas: (arbol[i].preguntasDisponibles * 0.12).round(),
        estado: i < estados.length
            ? estados[i].$1
            : DownloadState.noDescargada,
        progreso: i < estados.length ? estados[i].$2 : 0.0,
        preguntasNuevas: i < estados.length ? estados[i].$3 : 0,
      ),
  ];
});

/// Pantalla 8.1 — descargas offline (RF-30).
///
/// Ya no tiene una variante con candado. RF-29 sigue en pie —el contenido
/// premium jamás viaja a un cliente sin plan— pero con el modelo de la v2 no
/// hay cliente sin plan navegando la app: el router lo dejó en la pantalla de
/// pago (D-01). Quien llega aquí puede descargar.
class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paquetes = ref.watch(paquetesProvider);

    final usadosMb = paquetes
        .where(
          (p) =>
              p.estado == DownloadState.descargada ||
              p.estado == DownloadState.actualizable,
        )
        .fold(0, (s, p) => s + p.megas);

    return Scaffold(
      body: Column(
        children: [
          const GradientHeader(titulo: 'Estudiar sin conexión'),
          Expanded(
            child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      DesignTokens.space4,
                      DesignTokens.space4,
                      DesignTokens.space4,
                      DesignTokens.space8,
                    ),
                    children: [
                      FadeUp(
                        child: Text(
                          'Descarga áreas para practicar sin internet — en la '
                          'guardia, en el bus. Tus resultados se sincronizan al '
                          'reconectar.',
                          style: context.texts.bodyMedium?.copyWith(
                            height: 1.55,
                          ),
                        ),
                      ),
                      const SizedBox(height: DesignTokens.space4),
                      FadeUp(index: 1, child: _Espacio(usadosMb: usadosMb)),
                      const SizedBox(height: DesignTokens.space4),
                      Card(
                        child: Column(
                          children: [
                            for (var i = 0; i < paquetes.length; i++)
                              _FilaPaquete(
                                paquete: paquetes[i],
                                index: i,
                                esUltima: i == paquetes.length - 1,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: DesignTokens.space4),
                      const FadeUp(
                        index: 3,
                        child: StateBanner(
                          message:
                              'Los simulacros nacionales siempre requieren '
                              'conexión. Las descargas incluyen las imágenes '
                              'comprimidas.',
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Espacio extends StatelessWidget {
  const _Espacio({required this.usadosMb});

  final int usadosMb;

  /// Referencia para la barra. No es el espacio real del teléfono, que se
  /// consultaría al sistema; sirve para dar contexto de magnitud.
  static const _referenciaMb = 600;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Espacio usado',
                    style: context.texts.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '$usadosMb MB de tu teléfono',
                  style: context.texts.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.space2),
            AnimatedBar(
              value: usadosMb / _referenciaMb,
              color: context.scheme.primary,
              height: 6,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaPaquete extends StatelessWidget {
  const _FilaPaquete({
    required this.paquete,
    required this.index,
    required this.esUltima,
  });

  final Paquete paquete;
  final int index;
  final bool esUltima;

  @override
  Widget build(BuildContext context) {
    final states = context.states;
    final color = AreaColors.of(paquete.areaId, Theme.of(context).brightness);

    final (icono, colorIcono, tooltip) = switch (paquete.estado) {
      DownloadState.descargada => (
        Symbols.check_circle,
        states.success.onTint,
        'Descargada. Mantén presionado para eliminar',
      ),
      DownloadState.descargando => (
        Symbols.pause,
        context.scheme.onSurfaceVariant,
        'Pausar la descarga',
      ),
      DownloadState.actualizable => (
        Symbols.sync,
        states.info.onTint,
        'Actualizar',
      ),
      DownloadState.noDescargada => (
        Symbols.download,
        states.info.onTint,
        'Descargar',
      ),
    };

    final detalle = switch (paquete.estado) {
      DownloadState.descargada =>
        '${paquete.preguntas} preguntas · ${paquete.megas} MB · al día',
      DownloadState.descargando =>
        'Descargando · ${(paquete.progreso * paquete.megas).round()} de '
            '${paquete.megas} MB',
      DownloadState.actualizable =>
        'Hay ${paquete.preguntasNuevas} preguntas nuevas',
      DownloadState.noDescargada =>
        '${paquete.preguntas} preguntas · ${paquete.megas} MB',
    };

    return FadeUp(
      index: index,
      child: Container(
        decoration: BoxDecoration(
          border: esUltima
              ? null
              : Border(
                  bottom: BorderSide(color: context.scheme.outlineVariant),
                ),
        ),
        child: InkWell(
          onLongPress: paquete.estado == DownloadState.descargada
              ? () => _confirmarEliminar(context)
              : null,
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.space4),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: DesignTokens.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        paquete.nombre,
                        style: context.texts.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        detalle,
                        style: context.texts.bodySmall?.copyWith(
                          fontSize: 13,
                          fontWeight:
                              paquete.estado == DownloadState.actualizable
                              ? FontWeight.w700
                              : null,
                          color: paquete.estado == DownloadState.actualizable
                              ? states.warning.onTint
                              : null,
                        ),
                      ),
                      if (paquete.estado == DownloadState.descargando) ...[
                        const SizedBox(height: DesignTokens.space1 + 2),
                        AnimatedBar(
                          value: paquete.progreso,
                          color: context.scheme.primary,
                          height: 4,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: DesignTokens.space2),
                IconButton(
                  icon: Icon(icono, size: 22, color: colorIcono),
                  tooltip: tooltip,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmarEliminar(BuildContext context) async {
    final borrar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Eliminar ${paquete.nombre}?'),
        content: Text(
          'Liberas ${paquete.megas} MB. Puedes volver a descargarla cuando '
          'quieras, y tu progreso no se pierde.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Conservar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (borrar == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${paquete.nombre} eliminada')),
      );
    }
  }
}

