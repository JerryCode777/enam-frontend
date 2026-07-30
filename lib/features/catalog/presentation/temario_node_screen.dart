import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/state_colors.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/enam_button.dart';
import '../../../shared/widgets/gradient_header.dart';
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
        appBar: AppBar(),
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
          return Scaffold(
            appBar: AppBar(),
            body: const Center(
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
      body: Column(
        children: [
          GradientHeader(
            titulo: nodo.nombre,
            subtitulo: _migas(),
            bottom: _ResumenNodo(nodo: nodo),
          ),
          Expanded(
            child: nodo.tieneHijos
                ? _ListaHijos(nodo: nodo, tieneBloques: _tieneBloques)
                : _SinDetalle(nodo: nodo),
          ),
        ],
      ),
      bottomNavigationBar: nodo.estado == NodeState.sinContenido
          ? null
          : _BarraPracticar(nodo: nodo),
    );
  }

  /// Migas de pan: sin esto, alguien que llegó por búsqueda no sabe dónde está.
  String? _migas() {
    if (ruta.length <= 1) return null;
    return ruta.take(ruta.length - 1).map((n) => n.nombre).join(' › ');
  }
}

/// Cifras del nodo, dentro del degradado de la cabecera.
class _ResumenNodo extends StatelessWidget {
  const _ResumenNodo({required this.nodo});

  final CatalogNode nodo;

  @override
  Widget build(BuildContext context) {
    final acierto = nodo.porcentajeAcierto;
    final densidad = nodo.temasPorPregunta;

    return Row(
      children: [
        if (nodo.peso != null)
          _Cifra(
            valor: '${nodo.peso}',
            etiqueta: nodo.peso == 1 ? 'pregunta' : 'preguntas',
          ),
        _Cifra(
          valor: acierto == null ? '—' : '${(acierto * 100).round()} %',
          etiqueta: 'tu acierto',
        ),
        if (nodo.totalTemas > 0)
          _Cifra(valor: '${nodo.totalTemas}', etiqueta: 'temas'),
        if (densidad != null)
          _Cifra(
            valor: densidad.toStringAsFixed(1),
            etiqueta: 'temas/pregunta',
          ),
      ],
    );
  }
}

class _Cifra extends StatelessWidget {
  const _Cifra({required this.valor, required this.etiqueta});

  final String valor;
  final String etiqueta;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            valor,
            style: context.texts.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            etiqueta,
            maxLines: 2,
            style: context.texts.bodySmall?.copyWith(
              fontSize: 10.5,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.space4,
        DesignTokens.space4,
        DesignTokens.space4,
        DesignTokens.space16,
      ),
      children: [
        if (necesitaBuscador) ...[
          _AvisoLista(cantidad: nodo.hijos.length),
          const SizedBox(height: DesignTokens.space4),
        ],
        if (tieneBloques)
          // Gineco: los bloques son encabezados, y sus hijos van debajo.
          for (final bloque in nodo.hijos) ...[
            _BloqueHeader(bloque: bloque),
            const SizedBox(height: DesignTokens.space3),
            for (var i = 0; i < bloque.hijos.length; i++) ...[
              if (i > 0) const SizedBox(height: DesignTokens.space3),
              _hijo(context, bloque.hijos[i], i, bloque.peso ?? 1),
            ],
            const SizedBox(height: DesignTokens.space6),
          ]
        else
          for (var i = 0; i < nodo.hijos.length; i++) ...[
            if (i > 0) const SizedBox(height: DesignTokens.space3),
            _hijo(context, nodo.hijos[i], i, nodo.peso ?? 1),
          ],
      ],
    );
  }

  Widget _hijo(
    BuildContext context,
    CatalogNode hijo,
    int index,
    int pesoPadre,
  ) {
    return NodeCard(
      nodo: hijo,
      index: index,
      pesoMaximo: pesoPadre,
      // Los temas no tienen peso propio en el documento oficial, así que no se
      // muestra una cifra que no existe.
      mostrarPeso: hijo.peso != null,
      onTap: hijo.tieneHijos
          ? () => context.push(Routes.temarioAreaOf(hijo.id))
          : null,
      onPracticar: () => context.push('${Routes.practiceConfig}?nodo=${hijo.id}'),
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
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: context.scheme.onSurfaceVariant,
              ),
            ),
          ),
          if (bloque.peso != null)
            Text(
              '${bloque.peso} preguntas',
              style: context.texts.bodySmall?.copyWith(fontSize: 11),
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
                sinContenido ? Symbols.hourglass_empty : Symbols.subdirectory_arrow_right,
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

/// Botón fijo abajo para practicar el nodo actual (RF-38).
class _BarraPracticar extends StatelessWidget {
  const _BarraPracticar({required this.nodo});

  final CatalogNode nodo;

  @override
  Widget build(BuildContext context) {
    final agotado = nodo.estado == NodeState.agotado;

    return Container(
      padding: EdgeInsets.fromLTRB(
        DesignTokens.space4,
        DesignTokens.space3,
        DesignTokens.space4,
        DesignTokens.space3 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: context.scheme.surface,
        border: Border(top: BorderSide(color: context.scheme.outlineVariant)),
      ),
      child: EnamButton(
        // Un nodo agotado no ofrece "practicar" sin más: ya vio todo. Se le
        // ofrece lo único que aporta, repasar lo que falló (RF-40).
        label: agotado ? 'Repasar lo que fallaste' : 'Practicar este tema',
        icon: agotado ? Symbols.replay : Symbols.play_arrow,
        onPressed: () => context.push(
          '${Routes.practiceConfig}?nodo=${nodo.id}'
          '${agotado ? "&origen=falladas" : ""}',
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
      appBar: AppBar(),
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
