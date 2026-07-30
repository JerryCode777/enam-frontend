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

    final (texto, fondo, texto2) = switch (estado) {
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
      NodeState.enCurso => ('En curso', states.info.tint, states.info.onTint),
      NodeState.dominado => (
        'Dominado',
        states.success.tint,
        states.success.onTint,
      ),
      NodeState.agotado => (
        'Completado',
        states.info.tint,
        states.info.onTint,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space2 + 1,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm + 1),
      ),
      child: Text(
        texto,
        style: context.texts.bodySmall?.copyWith(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: texto2,
        ),
      ),
    );
  }
}

/// Tarjeta de un nodo del temario: área, bloque, sub área o tema.
///
/// La barra tiene **doble codificación**: el **ancho de la pista** es el peso del
/// nodo en el examen y el **relleno** es el acierto del usuario. Así un área de
/// 2 preguntas donde va mal se ve chica, y una de 40 donde va regular se ve
/// grande — que es la información que hace falta para decidir dónde estudiar.
class NodeCard extends StatelessWidget {
  const NodeCard({
    required this.nodo,
    required this.onTap,
    this.index = 0,
    this.pesoMaximo = 40,
    this.mostrarPeso = true,
    this.onPracticar,
    super.key,
  });

  final CatalogNode nodo;
  final VoidCallback? onTap;
  final int index;

  /// Peso de referencia para escalar el ancho de la pista. En el mapa de áreas
  /// es 40 (Medicina); dentro de un área, el peso del área.
  final int pesoMaximo;

  final bool mostrarPeso;

  /// Acción directa para practicar este nodo (RF-38). `null` la oculta.
  final VoidCallback? onPracticar;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final estado = nodo.estado;
    final sinContenido = estado == NodeState.sinContenido;
    final acierto = nodo.porcentajeAcierto;

    // El color del área tiñe todo el subárbol: un tema de Medicina se ve azul
    // igual que su área, para no perder la referencia al navegar.
    final colorArea = AreaColors.of(
      _areaRaiz(context),
      Theme.of(context).brightness,
    );

    return FadeUp(
      index: index,
      child: Opacity(
        // Atenuado, no gris: sigue siendo legible pero se lee como "todavía no".
        opacity: sinContenido ? 0.62 : 1,
        child: Card(
          child: InkWell(
            onTap: sinContenido ? null : onTap,
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            child: Padding(
              padding: const EdgeInsets.all(DesignTokens.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(top: 5),
                        decoration: BoxDecoration(
                          color: colorArea,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: DesignTokens.space2 + 2),
                      Expanded(
                        child: Text(
                          nodo.nombre,
                          style: context.texts.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (nodo.tieneHijos && !sinContenido) ...[
                        const SizedBox(width: DesignTokens.space2),
                        Icon(
                          Symbols.chevron_right,
                          size: 20,
                          color: scheme.onSurfaceVariant,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: DesignTokens.space3),
                  Row(
                    children: [
                      NodeStateChip(estado: estado),
                      const SizedBox(width: DesignTokens.space2),
                      if (mostrarPeso && nodo.peso != null)
                        Text(
                          // "pts" no: son preguntas del examen real.
                          '${nodo.peso} ${nodo.peso == 1 ? "pregunta" : "preguntas"}',
                          style: context.texts.bodySmall,
                        ),
                      const Spacer(),
                      if (acierto != null && !sinContenido)
                        Text(
                          '${(acierto * 100).round()} %',
                          style: context.texts.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: scheme.onSurface,
                          ),
                        ),
                    ],
                  ),
                  if (!sinContenido) ...[
                    const SizedBox(height: DesignTokens.space2),
                    _BarraDoble(
                      anchoRelativo: mostrarPeso && nodo.peso != null
                          ? ((nodo.peso! / pesoMaximo).clamp(0.18, 1.0))
                          : 1.0,
                      relleno: acierto ?? 0,
                      color: colorArea,
                    ),
                    const SizedBox(height: DesignTokens.space2),
                    Text(
                      _detalle(nodo),
                      style: context.texts.bodySmall?.copyWith(fontSize: 11.5),
                    ),
                  ] else ...[
                    const SizedBox(height: DesignTokens.space1),
                    Text(
                      'Estamos preparando las preguntas de este tema.',
                      style: context.texts.bodySmall?.copyWith(fontSize: 11.5),
                    ),
                  ],
                  if (onPracticar != null && !sinContenido) ...[
                    const SizedBox(height: DesignTokens.space3),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: onPracticar,
                        icon: const Icon(Symbols.play_arrow, size: 18),
                        label: const Text('Practicar'),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(
                            0,
                            DesignTokens.minTouchTarget,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: DesignTokens.space2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _detalle(CatalogNode nodo) {
    if (nodo.estado == NodeState.agotado) {
      return 'Viste las ${nodo.preguntasDisponibles} preguntas disponibles';
    }
    if (nodo.preguntasVistas == 0) {
      return '${nodo.preguntasDisponibles} preguntas disponibles';
    }
    return '${nodo.preguntasVistas} de ${nodo.preguntasDisponibles} vistas · '
        '${nodo.preguntasRestantes} por ver';
  }

  /// El id del área raíz, para tomar su color. Los ids de sub área y tema
  /// arrancan con el slug del área, así que basta el primer segmento conocido.
  String _areaRaiz(BuildContext context) {
    for (final id in AreaColors.knownAreaIds) {
      if (nodo.id == id || nodo.id.startsWith('$id-')) return id;
    }
    // Gineco usa prefijo corto en sus hijos (`go-parto`), y otros abrevian.
    const prefijos = {
      'go-': 'gineco-obstetricia',
      'sp-': 'salud-publica',
      'cb-': 'ciencias-basicas',
      'inv-': 'investigacion',
    };
    for (final entry in prefijos.entries) {
      if (nodo.id.startsWith(entry.key)) return entry.value;
    }
    return nodo.id;
  }
}

/// La barra de doble codificación: pista angosta = poco peso en el examen.
class _BarraDoble extends StatelessWidget {
  const _BarraDoble({
    required this.anchoRelativo,
    required this.relleno,
    required this.color,
  });

  final double anchoRelativo;
  final double relleno;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: (anchoRelativo * 100).round(),
          child: AnimatedBar(value: relleno, color: color),
        ),
        // El resto queda vacío: es lo que hace visible la diferencia de peso.
        if (anchoRelativo < 1)
          Expanded(flex: ((1 - anchoRelativo) * 100).round(), child: const SizedBox()),
      ],
    );
  }
}
