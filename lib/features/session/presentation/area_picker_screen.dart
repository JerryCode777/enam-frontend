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
import '../../offline/presentation/offline_providers.dart';

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

    // Sin señal solo se puede practicar lo que está en el teléfono. Se dice
    // **antes** de elegir y no después de tocar: dejar elegir y luego fallar es
    // la forma más rápida de que alguien crea que la app está rota.
    final hayRed = ref.watch(hayRedProvider).value ?? true;
    final descargadas = ref.watch(areasDescargadasProvider).value ?? const {};

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
        data: (areas) => _Lista(
          areas: areas,
          soloDescargadas: !hayRed,
          descargadas: descargadas,
        ),
      ),
    );
  }
}

class _Lista extends StatelessWidget {
  const _Lista({
    required this.areas,
    required this.soloDescargadas,
    required this.descargadas,
  });

  final List<CatalogNode> areas;

  /// Sin conexión: lo que no esté en el teléfono va con candado.
  final bool soloDescargadas;
  final Set<String> descargadas;

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
        if (soloDescargadas) ...[
          StateBanner(
            message: descargadas.isEmpty
                ? 'Estás sin conexión y no tienes áreas descargadas. Cuando '
                      'vuelvas a tener internet, descarga las que quieras '
                      'llevarte.'
                : 'Estás sin conexión: puedes practicar lo que descargaste.',
          ),
          const SizedBox(height: DesignTokens.space4),
        ],
        // Practicar de todo es una opción legítima y frecuente: es lo que hace
        // alguien que solo quiere sumar preguntas hoy.
        _Opcion(
          icono: Symbols.shuffle,
          color: context.states.info.onTint,
          titulo: soloDescargadas ? 'Todo lo descargado' : 'Todo el temario',
          detalle: soloDescargadas
              ? 'Preguntas de las áreas que tienes en el teléfono'
              : 'Preguntas de todas las áreas, mezcladas',
          onTap: soloDescargadas && descargadas.isEmpty
              ? null
              : () => context.pop(const _SinNodo()),
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
          _Area(
            area: area,
            bloqueada: soloDescargadas && !descargadas.contains(area.id),
          ),
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
  const _Area({required this.area, this.bloqueada = false});

  final CatalogNode area;

  /// Sin conexión y sin descargar: se ve, pero no se puede elegir.
  ///
  /// Se enseña en vez de esconderla porque esconderla haría creer que el área
  /// no existe; con el candado se entiende que existe y qué hay que hacer para
  /// tenerla.
  final bool bloqueada;

  @override
  Widget build(BuildContext context) {
    final color = AreaColors.of(area.id, Theme.of(context).brightness);
    final hijos = bloqueada
        ? const <CatalogNode>[]
        : area.hijos.where((h) => h.preguntasDisponibles > 0).toList();
    final sinPreguntas = area.preguntasDisponibles == 0 || bloqueada;

    final cabecera = Row(
      children: [
        Container(
          width: 4,
          height: 34,
          decoration: BoxDecoration(
            color: bloqueada ? context.scheme.outlineVariant : color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: DesignTokens.space3),
        if (bloqueada) ...[
          Icon(
            Symbols.lock,
            size: 18,
            color: context.scheme.onSurfaceVariant,
          ),
          const SizedBox(width: DesignTokens.space2),
        ],
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
                  color: bloqueada
                      ? context.scheme.onSurfaceVariant
                      : context.scheme.onSurface,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                bloqueada
                    ? 'Descárgala para practicarla sin conexión'
                    : sinPreguntas
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

  /// Nulo la deja apagada: sin conexión y sin nada descargado, «todo» no
  /// lleva a ninguna parte.
  final VoidCallback? onTap;

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
