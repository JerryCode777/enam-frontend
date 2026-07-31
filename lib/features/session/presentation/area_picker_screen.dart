import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/providers.dart';
import '../../../core/theme/area_colors.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/state_colors.dart';
import '../../../shared/widgets/state_banner.dart';
import '../../catalog/domain/catalog_models.dart';

/// Pantalla 4.1b — elegir sobre qué practicar.
///
/// Existe porque el configurador de práctica vive **fuera** del shell de
/// pestañas y antes abría `/temario` con `push`. Eso montaba una segunda copia
/// del shell y su `Navigator`, con la misma `GlobalKey` que el ya montado, y
/// Flutter reventaba con "A GlobalKey was used multiple times".
///
/// Además el flujo era peor: el usuario se iba a la pestaña del temario y
/// perdía la configuración que estaba armando. Aquí elige y vuelve con el nodo
/// puesto.
class AreaPickerScreen extends ConsumerWidget {
  const AreaPickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogo = ref.watch(catalogProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Elige qué practicar'),
        leading: IconButton(
          icon: const Icon(Symbols.close),
          tooltip: 'Cancelar',
          onPressed: () => context.pop(),
        ),
      ),
      body: catalogo.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(DesignTokens.space4),
          child: StateBanner(
            kind: BannerKind.error,
            message: 'No pudimos cargar el temario.',
            action: TextButton(
              onPressed: () => ref.invalidate(catalogProvider),
              child: const Text('Reintentar'),
            ),
          ),
        ),
        data: (areas) => _Lista(areas: areas),
      ),
    );
  }
}

class _Lista extends StatelessWidget {
  const _Lista({required this.areas});

  final List<CatalogNode> areas;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.space5,
        DesignTokens.space3,
        DesignTokens.space5,
        DesignTokens.space8,
      ),
      children: [
        // Practicar de todo es una opción legítima y frecuente: es lo que hace
        // alguien que solo quiere sumar preguntas hoy.
        _Opcion(
          icono: Symbols.shuffle,
          color: context.states.info.onTint,
          titulo: 'Todo el temario',
          detalle: 'Preguntas de todas las áreas, mezcladas',
          onTap: () => context.pop(const _SinNodo()),
        ),
        const SizedBox(height: DesignTokens.space4),
        Text(
          'POR ÁREA',
          style: context.texts.bodySmall?.copyWith(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.9,
            color: context.scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: DesignTokens.space2),
        for (final area in areas) ...[
          _Area(area: area),
          const SizedBox(height: DesignTokens.space2 + 1),
        ],
      ],
    );
  }
}

/// Marca "sin nodo": practicar de todo el temario.
class _SinNodo {
  const _SinNodo();
}

/// Un área, expandible a sus sub áreas.
///
/// El peso va visible: 40 preguntas y 2 preguntas no pueden verse igual a la
/// hora de decidir dónde invertir el tiempo.
class _Area extends StatelessWidget {
  const _Area({required this.area});

  final CatalogNode area;

  @override
  Widget build(BuildContext context) {
    final color = AreaColors.of(area.id, Theme.of(context).brightness);
    final hijos = area.hijos.where((h) => h.preguntasDisponibles > 0).toList();
    final sinPreguntas = area.preguntasDisponibles == 0;

    final cabecera = Row(
      children: [
        Container(
          width: 4,
          height: 34,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: DesignTokens.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                area.nombre,
                style: context.texts.bodyLarge?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  color: context.scheme.onSurface,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                sinPreguntas
                    ? 'Aún no disponible'
                    : '${area.preguntasDisponibles} preguntas · '
                          '${area.peso ?? 0} en el examen',
                style: context.texts.bodySmall?.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    // Sin sub áreas con preguntas no hay nada que desplegar: se elige el área
    // entera de un toque.
    if (hijos.isEmpty) {
      return Card(
        child: InkWell(
          onTap: sinPreguntas ? null : () => context.pop(area),
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg + 2),
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.space3 + 2),
            child: cabecera,
          ),
        ),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Theme(
        // Quita las líneas divisorias que Material pone al expandir.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: cabecera,
          tilePadding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space3 + 2,
          ),
          childrenPadding: const EdgeInsets.only(
            left: DesignTokens.space4,
            right: DesignTokens.space3,
            bottom: DesignTokens.space2,
          ),
          children: [
            _SubArea(
              nodo: area,
              titulo: 'Toda el área',
              detalle: '${area.preguntasDisponibles} preguntas',
            ),
            for (final hijo in hijos)
              _SubArea(
                nodo: hijo,
                titulo: hijo.nombre,
                detalle: '${hijo.preguntasDisponibles} preguntas',
              ),
          ],
        ),
      ),
    );
  }
}

class _SubArea extends StatelessWidget {
  const _SubArea({
    required this.nodo,
    required this.titulo,
    required this.detalle,
  });

  final CatalogNode nodo;
  final String titulo;
  final String detalle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.pop(nodo),
      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space2,
          vertical: DesignTokens.space3 - 2,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: context.texts.bodyMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: context.scheme.onSurface,
                    ),
                  ),
                  Text(
                    detalle,
                    style: context.texts.bodySmall?.copyWith(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Symbols.chevron_right,
              size: 20,
              color: context.scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// Opción suelta de la cabecera (practicar de todo).
class _Opcion extends StatelessWidget {
  const _Opcion({
    required this.icono,
    required this.color,
    required this.titulo,
    required this.detalle,
    required this.onTap,
  });

  final IconData icono;
  final Color color;
  final String titulo;
  final String detalle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg + 2),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.space4),
          child: Row(
            children: [
              Icon(icono, size: 24, fill: 1, color: color),
              const SizedBox(width: DesignTokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: context.texts.bodyLarge?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: context.scheme.onSurface,
                      ),
                    ),
                    Text(
                      detalle,
                      style: context.texts.bodySmall?.copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Resultado del selector: `null` si se canceló, el nodo elegido, o
/// [practicarDeTodo] si se eligió el temario completo.
bool esPracticarDeTodo(Object? resultado) => resultado is _SinNodo;
