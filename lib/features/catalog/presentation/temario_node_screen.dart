import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/area_colors.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/state_colors.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../../shared/widgets/enam_button.dart';
import '../../../shared/widgets/state_banner.dart';
import '../domain/catalog_models.dart';
import 'catalog_providers.dart';
import 'widgets/node_card.dart';

/// Pantallas 3.2 a 3.5 — un nodo del temario con sus hijos.
///
/// Es **una sola pantalla** para los cuatro casos del diseño, porque el modelo
/// es recursivo:
///
/// - **3.2** Área con sub áreas planas (Medicina, 11 sub áreas)
/// - **3.3** Área con capa de bloques (Ginecología Obstetricia, la única)
/// - **3.4** Área que no desarrolla tercer nivel (Emergencias, Ética,
///   Investigación, Gestión) — la navegación termina aquí (RF-37)
/// - **3.5** Sub área con su lista de temas (hasta 123 en Medicina)
///
/// Escribirlas por separado habría multiplicado el mismo layout por cuatro.
class TemarioNodeScreen extends ConsumerWidget {
  const TemarioNodeScreen({required this.nodeId, super.key});

  final String nodeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arbol = ref.watch(catalogProvider);

    return arbol.when(
      loading: () => const _NodoCargando(),
      error: (e, _) => Scaffold(
        appBar: const GradientHeader(titulo: 'Temario'),
        body: Center(
          child: Padding(
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
        ),
      ),
      data: (_) {
        final encontrado = ref.watch(nodoProvider(nodeId));
        if (encontrado == null) {
          return const Scaffold(
            appBar: GradientHeader(titulo: 'Temario'),
            body: Center(
              child: Text('No encontramos ese punto del temario.'),
            ),
          );
        }
        return _Contenido(nodo: encontrado.nodo, ruta: encontrado.ruta);
      },
    );
  }
}

class _Contenido extends ConsumerWidget {
  const _Contenido({required this.nodo, required this.ruta});

  final CatalogNode nodo;
  final List<CatalogNode> ruta;

  /// Los hijos son bloques, no sub áreas: el caso de Gineco-Obstetricia.
  bool get _tieneBloques => nodo.hijos.any((h) => h.nivel == 'bloque');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: context.scheme.surfaceContainerLowest,
      // El mismo degradado que el resto de cabeceras de la app: con un AppBar
      // plano, bajar un nivel del temario parecía salirse a otra aplicación.
      //
      // Lleva el **padre**, no el nodo: el nombre del nodo ya va grande en
      // `EncabezadoNodo`, justo debajo, y repetirlo dejaba "Medicina" dos veces
      // seguidas. Aquí sirve para saber de dónde cuelga esto, que es lo que
      // necesita quien llegó por búsqueda.
      appBar: GradientHeader(titulo: _padre() ?? 'Temario'),
      body: nodo.tieneHijos
          ? _ListaHijos(nodo: nodo, tieneBloques: _tieneBloques)
          : _SinDetalle(nodo: nodo),
    );
  }

  /// Nombre del nodo padre, para la barra superior.
  String? _padre() => ruta.length <= 1 ? null : ruta[ruta.length - 2].nombre;
}

/// Identidad del nodo: icono del área, nombre y sus cifras en fichas.
///
/// Va dentro de la lista y no en una cabecera fija: el diseño deja que suba con
/// el contenido, así la lista de sub áreas gana pantalla al desplazar.
class EncabezadoNodo extends StatelessWidget {
  const EncabezadoNodo({required this.nodo, required this.areaId, super.key});

  final CatalogNode nodo;
  final String areaId;

  @override
  Widget build(BuildContext context) {
    final states = context.states;
    final color = AreaColors.of(areaId, Theme.of(context).brightness);
    final acierto = nodo.porcentajeAcierto;
    final subAreas = nodo.hijos.length;

    return FadeUp(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: states.info.tint,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  AreaColors.iconOf(areaId),
                  size: 24,
                  fill: 1,
                  color: color,
                ),
              ),
              const SizedBox(width: DesignTokens.space2 + 2),
              Expanded(
                child: Text(
                  nodo.nombre,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space3),
          Wrap(
            spacing: DesignTokens.space2,
            runSpacing: DesignTokens.space2,
            children: [
              if (nodo.peso != null)
                _Ficha(
                  texto:
                      '${nodo.peso} de 180 · '
                      '${(nodo.peso! / 180 * 100).round()} %',
                ),
              _Ficha(
                texto: [
                  if (subAreas > 0)
                    '$subAreas ${subAreas == 1 ? "sub área" : "sub áreas"}',
                  '${nodo.totalTemas} temas',
                ].join(' · '),
              ),
              if (acierto != null)
                _Ficha(
                  texto: 'Acierto ${(acierto * 100).round()} %',
                  color: states.success.onTint,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Ficha con borde para las cifras del nodo.
class _Ficha extends StatelessWidget {
  const _Ficha({required this.texto, this.color});

  final String texto;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space2 + 2,
        vertical: DesignTokens.space1 + 2,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: color ?? scheme.onSurface,
        ),
      ),
    );
  }
}

class _ListaHijos extends ConsumerWidget {
  const _ListaHijos({required this.nodo, required this.tieneBloques});

  final CatalogNode nodo;
  final bool tieneBloques;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Muchos temas: hace falta buscar dentro del nodo. Medicina llega a 123.
    final necesitaBuscador = nodo.hijos.length > 12;
    final areaId = AreaColors.rootOf(nodo.id);
    final color = AreaColors.of(areaId, Theme.of(context).brightness);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.space5,
        DesignTokens.space1,
        DesignTokens.space5,
        DesignTokens.space8,
      ),
      children: [
        EncabezadoNodo(nodo: nodo, areaId: areaId),
        const SizedBox(height: DesignTokens.space3),
        if (nodo.estado != NodeState.sinContenido) ...[
          _BotonPracticar(nodo: nodo),
          const SizedBox(height: DesignTokens.space3),
        ],
        if (necesitaBuscador) ...[
          _AvisoLista(cantidad: nodo.hijos.length),
          const SizedBox(height: DesignTokens.space3),
        ],
        if (tieneBloques)
          // Gineco: los bloques son encabezados, y sus hijos van debajo.
          for (final bloque in nodo.hijos) ...[
            _BloqueHeader(bloque: bloque),
            const SizedBox(height: DesignTokens.space2),
            _TarjetaHijos(hijos: bloque.hijos, color: color),
            const SizedBox(height: DesignTokens.space4),
          ]
        else
          _TarjetaHijos(hijos: nodo.hijos, color: color),
      ],
    );
  }
}

/// Los hijos de un nodo, como filas de una sola tarjeta.
///
/// Una tarjeta por sub área daría once tarjetas en Medicina, cada una con su
/// borde y su sombra: mucho marco y poca información. El diseño usa una sola
/// tarjeta con separadores finos.
class _TarjetaHijos extends StatelessWidget {
  const _TarjetaHijos({required this.hijos, required this.color});

  final List<CatalogNode> hijos;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GroupedCard(
      children: [
        for (var i = 0; i < hijos.length; i++)
          NodeRow(
            nodo: hijos[i],
            color: color,
            ultima: i == hijos.length - 1,
            onTap: hijos[i].tieneHijos
                ? () => context.push(Routes.temarioAreaOf(hijos[i].id))
                : null,
            onPracticar: () => context.push(
              '${Routes.practiceConfig}?nodo=${hijos[i].id}'
              '${hijos[i].estado == NodeState.agotado ? "&origen=falladas" : ""}',
            ),
          ),
      ],
    );
  }
}

/// El único botón de práctica de la pantalla, con el degradado de marca.
///
/// Antes vivía fijo abajo. Arriba funciona mejor: se ve sin desplazar, y la
/// lista de sub áreas recupera el alto que ocupaba la barra.
class _BotonPracticar extends StatelessWidget {
  const _BotonPracticar({required this.nodo});

  final CatalogNode nodo;

  @override
  Widget build(BuildContext context) {
    final agotado = nodo.estado == NodeState.agotado;

    return FadeUp(
      child: EnamButton(
        // Un nodo agotado no ofrece "practicar" sin más: ya vio todo. Se le
        // ofrece lo único que aporta, repasar lo que falló (RF-40).
        label: agotado ? 'Repasar lo que fallaste' : 'Practicar ${nodo.nombre}',
        icon: agotado ? Symbols.replay : Symbols.play_arrow,
        onPressed: () => context.push(
          '${Routes.practiceConfig}?nodo=${nodo.id}'
          '${agotado ? "&origen=falladas" : ""}',
        ),
      ),
    );
  }
}

class _AvisoLista extends StatelessWidget {
  const _AvisoLista({required this.cantidad});

  final int cantidad;

  @override
  Widget build(BuildContext context) {
    return FadeUp(
      child: GestureDetector(
        onTap: () => context.push(Routes.temarioSearch),
        child: Container(
          padding: const EdgeInsets.all(DesignTokens.space3 + 1),
          decoration: BoxDecoration(
            color: context.scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd + 2),
          ),
          child: Row(
            children: [
              Icon(
                Symbols.search,
                size: 20,
                color: context.scheme.onSurfaceVariant,
              ),
              const SizedBox(width: DesignTokens.space2 + 2),
              Expanded(
                child: Text(
                  'Son $cantidad. Busca por nombre si ya sabes qué quieres.',
                  style: context.texts.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BloqueHeader extends StatelessWidget {
  const _BloqueHeader({required this.bloque});

  final CatalogNode bloque;

  @override
  Widget build(BuildContext context) {
    return FadeUp(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              bloque.nombre.toUpperCase(),
              style: context.texts.bodySmall?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: context.scheme.onSurfaceVariant,
              ),
            ),
          ),
          if (bloque.peso != null)
            Text(
              '${bloque.peso} preguntas',
              style: context.texts.bodySmall?.copyWith(fontSize: 13),
            ),
        ],
      ),
    );
  }
}

/// Un nodo que no desarrolla más detalle.
///
/// Cubre dos casos distintos que **no deben verse igual**:
/// - Cuatro áreas del documento oficial no tienen tercer nivel (RF-37). No es
///   información que falte: no existe.
/// - Un tema sin preguntas cargadas todavía (RN-08). Va a existir, aún no está.
class _SinDetalle extends StatelessWidget {
  const _SinDetalle({required this.nodo});

  final CatalogNode nodo;

  @override
  Widget build(BuildContext context) {
    final states = context.states;
    final sinContenido = nodo.estado == NodeState.sinContenido;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(DesignTokens.space8),
        child: FadeUp(
          child: Column(
            children: [
              Icon(
                sinContenido
                    ? Symbols.hourglass_empty
                    : Symbols.subdirectory_arrow_right,
                size: 40,
                color: sinContenido
                    ? states.warning.onTint
                    : context.scheme.onSurfaceVariant,
              ),
              const SizedBox(height: DesignTokens.space4),
              Text(
                sinContenido
                    ? 'Estamos preparando este tema'
                    : 'Aquí termina el detalle',
                textAlign: TextAlign.center,
                style: context.texts.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: DesignTokens.space3),
              Text(
                sinContenido
                    ? 'Todavía no hay preguntas cargadas. El banco crece por '
                          'áreas: vuelve en unos días.'
                    // Se explica por qué, para que no parezca un dato faltante.
                    : 'La Tabla de Especificaciones de ASPEFAM no desarrolla '
                          'temas para esta parte del examen. Puedes practicar '
                          'el nodo completo.',
                textAlign: TextAlign.center,
                style: context.texts.bodyMedium?.copyWith(height: 1.55),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NodoCargando extends StatelessWidget {
  const _NodoCargando();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientHeader(titulo: 'Temario'),
      body: ListView(
        padding: const EdgeInsets.all(DesignTokens.space4),
        children: [
          for (var i = 0; i < 6; i++)
            const Padding(
              padding: EdgeInsets.only(bottom: DesignTokens.space3),
              child: SkeletonBox(height: 132, radius: DesignTokens.radiusLg),
            ),
        ],
      ),
    );
  }
}
