import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/theme/area_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/state_colors.dart';
import '../../../../shared/widgets/animations.dart';
import '../../domain/catalog_models.dart';

/// Chip que comunica el estado de un nodo del temario.
///
/// El color **nunca** es el único portador: siempre lleva texto. Y
/// `sinContenido` usa tono neutral, no de error: que el banco no tenga
/// preguntas todavía no es una falla del usuario ni del sistema (RN-08).
class NodeStateChip extends StatelessWidget {
  const NodeStateChip({required this.estado, super.key});

  final NodeState estado;

  @override
  Widget build(BuildContext context) {
    final states = context.states;
    final scheme = context.scheme;

    final (texto, fondo, textoColor) = switch (estado) {
      NodeState.sinContenido => (
        'Disponible pronto',
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
      ),
      NodeState.sinEmpezar => (
        'Sin empezar',
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
      ),
      NodeState.enCurso => (
        'En curso',
        states.warning.tint,
        states.warning.onTint,
      ),
      NodeState.dominado => (
        'Dominado',
        states.success.tint,
        states.success.onTint,
      ),
      NodeState.agotado => (
        'Lo viste todo',
        states.info.tint,
        states.info.onTint,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space2 + 2,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        texto,
        style: context.texts.bodySmall?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: textoColor,
        ),
      ),
    );
  }
}

/// Cuánto espacio ocupa un área en el mapa del temario.
///
/// El diseño usa tres tamaños porque **el peso del área es la información que
/// hace falta para decidir**: Medicina son 40 preguntas y Ética 2. Con todas
/// las tarjetas iguales, el ojo no ve dónde está el 74 % del examen.
enum AreaCardSize {
  /// 31 preguntas o más: nombre grande, cifras y barra de cobertura.
  grande,

  /// De 15 a 30: una línea de nombre y una de detalle.
  media,

  /// 14 o menos: fila dentro de una lista agrupada.
  compacta;

  static AreaCardSize forPeso(int? peso) => switch (peso ?? 0) {
    >= 31 => AreaCardSize.grande,
    >= 15 => AreaCardSize.media,
    _ => AreaCardSize.compacta,
  };
}

/// Tarjeta de un área en el mapa del temario (3.1).
///
/// El color del área va en el borde izquierdo y en el icono, siempre junto al
/// nombre. Sin botón de practicar: en el mapa se elige área, y la práctica se
/// inicia desde el detalle, donde ya se sabe sobre qué.
class AreaCard extends StatelessWidget {
  const AreaCard({
    required this.nodo,
    required this.onTap,
    this.index = 0,
    super.key,
  });

  final CatalogNode nodo;
  final VoidCallback? onTap;
  final int index;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final estado = nodo.estado;
    final sinContenido = estado == NodeState.sinContenido;
    final color = AreaColors.of(
      AreaColors.rootOf(nodo.id),
      Theme.of(context).brightness,
    );
    final grande = AreaCardSize.forPeso(nodo.peso) == AreaCardSize.grande;

    return FadeUp(
      index: index,
      child: Opacity(
        // Atenuado, no gris: sigue siendo legible pero se lee como "todavía no".
        opacity: sinContenido ? 0.62 : 1,
        child: Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border.all(color: scheme.outlineVariant),
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // La franja del área va posicionada y no como borde ni como hijo
              // de un Row: Flutter no admite bordes de color mixto con radio, y
              // un hijo con `stretch` pedía alto infinito dentro de la lista.
              // Así se estira a lo que mida el contenido y nada más.
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 4,
                child: ColoredBox(color: color),
              ),
              InkWell(
                onTap: sinContenido ? null : onTap,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    DesignTokens.space4 + 2,
                    grande ? 11 : 9,
                    DesignTokens.space3 + 2,
                    grande ? 11 : 9,
                  ),
                  child: grande
                      ? _Grande(nodo: nodo, color: color)
                      : _Media(nodo: nodo, color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Áreas de 31 preguntas o más: Medicina y Pediatría.
class _Grande extends StatelessWidget {
  const _Grande({required this.nodo, required this.color});

  final CatalogNode nodo;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final acierto = nodo.porcentajeAcierto;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              AreaColors.iconOf(AreaColors.rootOf(nodo.id)),
              size: 20,
              fill: 1,
              color: color,
            ),
            const SizedBox(width: DesignTokens.space2),
            Expanded(
              child: Text(
                nodo.nombre,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: DesignTokens.space2),
            Text(
              '${nodo.peso} de 180',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.space1 + 2),
        _MetaFila(
          partes: [
            ('${nodo.totalTemas} temas', null),
            if (acierto != null) ('Acierto ${(acierto * 100).round()} %', null),
            _estadoTexto(context, nodo.estado),
          ],
        ),
        const SizedBox(height: DesignTokens.space1 + 2),
        // Cobertura: qué parte del banco de esta área ya se vio. No es el
        // acierto — son dos cosas distintas y mezclarlas engaña.
        _BarraCobertura(valor: nodo.cobertura, color: color),
      ],
    );
  }
}

/// Áreas de 15 a 30 preguntas.
class _Media extends StatelessWidget {
  const _Media({required this.nodo, required this.color});

  final CatalogNode nodo;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final acierto = nodo.porcentajeAcierto;
    final hijos = nodo.hijos.length;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    AreaColors.iconOf(AreaColors.rootOf(nodo.id)),
                    size: 18,
                    fill: 1,
                    color: color,
                  ),
                  const SizedBox(width: DesignTokens.space2 - 1),
                  Expanded(
                    child: Text(
                      nodo.nombre,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                [
                  if (hijos > 0)
                    '$hijos ${hijos == 1 ? "sub área" : "sub áreas"}'
                  else
                    '${nodo.totalTemas} temas',
                  if (acierto != null)
                    'Acierto ${(acierto * 100).round()} %'
                  else
                    _estadoTexto(context, nodo.estado).$1,
                ].join(' · '),
                style: context.texts.bodySmall?.copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: DesignTokens.space2 + 2),
        Text(
          '${nodo.peso}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Fila compacta para las áreas de 14 preguntas o menos.
///
/// Van agrupadas en una sola tarjeta con [AreaCompactList]: cuatro áreas de 2 a
/// 14 preguntas con tarjeta propia cada una ocuparían más pantalla que
/// Medicina, que vale veinte veces más.
class AreaCompactRow extends StatelessWidget {
  const AreaCompactRow({
    required this.nodo,
    required this.onTap,
    this.destacado,
    this.ultima = false,
    super.key,
  });

  final CatalogNode nodo;
  final VoidCallback? onTap;

  /// Etiqueta corta a la izquierda del número, como "Rinde 4×".
  final String? destacado;

  final bool ultima;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final states = context.states;
    final color = AreaColors.of(
      AreaColors.rootOf(nodo.id),
      Theme.of(context).brightness,
    );
    final sinContenido = nodo.estado == NodeState.sinContenido;

    return InkWell(
      onTap: sinContenido ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space3 + 2,
          vertical: 9,
        ),
        decoration: ultima
            ? null
            : BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: scheme.outlineVariant),
                ),
              ),
        child: Opacity(
          opacity: sinContenido ? 0.62 : 1,
          child: Row(
            children: [
              Icon(
                AreaColors.iconOf(AreaColors.rootOf(nodo.id)),
                size: 18,
                fill: 1,
                color: color,
              ),
              const SizedBox(width: DesignTokens.space2 + 2),
              Expanded(
                child: Text(
                  nodo.nombre,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (destacado != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.space2,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: states.success.tint,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    destacado!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: states.success.onTint,
                    ),
                  ),
                ),
                const SizedBox(width: DesignTokens.space2 + 2),
              ],
              Text(
                '${nodo.peso}',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tarjeta que agrupa varias filas, con el borde y el redondeo del diseño.
///
/// La usan tanto las áreas compactas del mapa como las listas de sub áreas y
/// temas del detalle: en el diseño son la misma pieza.
class GroupedCard extends StatelessWidget {
  const GroupedCard({required this.children, this.index = 0, super.key});

  final List<Widget> children;
  final int index;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;

    return FadeUp(
      index: index,
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      ),
    );
  }
}

/// Fila de sub área o tema dentro de una [GroupedCard] (pantallas 3.2 a 3.5).
///
/// La acción de practicar es el icono de la derecha y no un botón con texto:
/// en una lista de once sub áreas, once botones "Practicar" ocupan más que el
/// contenido. El icono deja la fila para lo que importa —el nombre y cómo vas—
/// y sigue teniendo su área táctil completa.
class NodeRow extends StatelessWidget {
  const NodeRow({
    required this.nodo,
    required this.onTap,
    this.onPracticar,
    this.ultima = false,
    this.color,
    super.key,
  });

  final CatalogNode nodo;
  final VoidCallback? onTap;

  /// `null` oculta el icono de práctica.
  final VoidCallback? onPracticar;

  final bool ultima;

  /// Color del área a la que pertenece, para la mini barra.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final states = context.states;
    final estado = nodo.estado;
    final sinContenido = estado == NodeState.sinContenido;
    final acierto = nodo.porcentajeAcierto;
    final agotado = estado == NodeState.agotado;

    return InkWell(
      onTap: sinContenido ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space4,
          vertical: 13,
        ),
        decoration: ultima
            ? null
            : BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: scheme.outlineVariant),
                ),
              ),
        child: Opacity(
          opacity: sinContenido ? 0.75 : 1,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nodo.nombre,
                      // Sin recorte: hay temas oficiales de más de 100
                      // caracteres y truncarlos los vuelve indistinguibles
                      // entre sí.
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _detalle(nodo),
                      style: context.texts.bodySmall?.copyWith(fontSize: 11.5),
                    ),
                    if (agotado) ...[
                      const SizedBox(height: DesignTokens.space1 + 2),
                      Row(
                        children: [
                          const NodeStateChip(estado: NodeState.agotado),
                          if (nodo.preguntasFalladas > 0) ...[
                            const SizedBox(width: DesignTokens.space1 + 2),
                            Flexible(
                              child: Text(
                                'Repasar tus ${nodo.preguntasFalladas} falladas',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: states.info.onTint,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: DesignTokens.space3),
              if (sinContenido)
                const NodeStateChip(estado: NodeState.sinContenido)
              else ...[
                if (acierto != null && color != null) ...[
                  _MiniBarra(valor: acierto, contexto: context),
                  const SizedBox(width: DesignTokens.space3),
                ],
                if (onPracticar != null)
                  IconButton(
                    onPressed: onPracticar,
                    icon: Icon(agotado ? Symbols.replay : Symbols.play_circle),
                    iconSize: 22,
                    color: scheme.primary,
                    // El icono es chico pero el objetivo táctil no: 44 px es el
                    // mínimo para poder tocarlo sin apuntar.
                    constraints: const BoxConstraints(
                      minWidth: DesignTokens.minTouchTarget,
                      minHeight: DesignTokens.minTouchTarget,
                    ),
                    padding: EdgeInsets.zero,
                    tooltip: agotado
                        ? 'Repasar lo que fallaste'
                        : 'Practicar ${nodo.nombre}',
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _detalle(CatalogNode nodo) {
    if (nodo.estado == NodeState.sinContenido) {
      return 'Estamos preparando las preguntas de este tema';
    }

    final partes = <String>[
      if (nodo.peso != null) '${nodo.peso} pts',
      if (nodo.totalTemas > 0) '${nodo.totalTemas} temas',
      if (nodo.preguntasVistas == 0)
        'sin empezar'
      else
        'acierto ${((nodo.porcentajeAcierto ?? 0) * 100).round()} %',
    ];
    return partes.join(' · ');
  }
}

/// Barra de acierto de 52 × 5, con color según qué tan bien va.
class _MiniBarra extends StatelessWidget {
  const _MiniBarra({required this.valor, required this.contexto});

  final double valor;
  final BuildContext contexto;

  @override
  Widget build(BuildContext context) {
    final states = context.states;

    // El color habla del acierto, no del área: aquí lo que importa es si vas
    // bien o mal, y el área ya está en la cabecera de la pantalla.
    final color = switch (valor) {
      >= 0.7 => states.success.base,
      >= 0.5 => states.warning.base,
      _ => states.error.base,
    };

    return SizedBox(
      width: 52,
      height: 5,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(
          value: valor,
          backgroundColor: context.scheme.outlineVariant,
          valueColor: AlwaysStoppedAnimation(color),
        ),
      ),
    );
  }
}

class _BarraCobertura extends StatelessWidget {
  const _BarraCobertura({required this.valor, required this.color});

  final double valor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 6,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: AnimatedBar(value: valor, color: color),
      ),
    );
  }
}

/// Fila de metadatos separados por espacio, como en el diseño.
class _MetaFila extends StatelessWidget {
  const _MetaFila({required this.partes});

  /// Texto y, si lo lleva, un color propio.
  final List<(String, Color?)> partes;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: DesignTokens.space3 + 2,
      runSpacing: 2,
      children: [
        for (final (texto, color) in partes)
          Text(
            texto,
            style: context.texts.bodySmall?.copyWith(
              fontSize: 12,
              fontWeight: color != null ? FontWeight.w700 : null,
              color: color,
            ),
          ),
      ],
    );
  }
}

/// Texto y color del estado, para las líneas de metadatos.
(String, Color?) _estadoTexto(BuildContext context, NodeState estado) {
  final states = context.states;
  return switch (estado) {
    NodeState.sinContenido => ('Disponible pronto', null),
    NodeState.sinEmpezar => ('Sin empezar', null),
    NodeState.enCurso => ('En curso', states.warning.onTint),
    NodeState.dominado => ('Dominado', states.success.onTint),
    NodeState.agotado => ('Lo viste todo', states.info.onTint),
  };
}
