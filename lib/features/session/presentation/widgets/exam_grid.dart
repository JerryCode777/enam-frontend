import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/state_colors.dart';
import '../../domain/session_models.dart';

/// Estado de una casilla de la grilla del examen.
enum CellState { sinResponder, respondida, marcada, actual }

/// Grilla de navegación del simulacro (RF-17).
///
/// El reto real: **180 casillas tocables en 360 px de ancho**. Con el padding de
/// la pantalla quedan ~328 px útiles; a 8 columnas cada casilla mide ~37 px, por
/// debajo del mínimo táctil de 48.
///
/// La salida no es apretar más las casillas sino **agruparlas por área**: el
/// examen ya viene ordenado por bloques de área, así que la grilla se corta en
/// secciones de 40, 34, 16… Cada sección respira, la casilla llega a 40 px de
/// caja con 4 px de separación —48 de área táctil efectiva contando el gesto— y
/// además el usuario ubica "las de Pediatría" sin contar.
///
/// El color nunca es el único portador: la casilla marcada lleva una esquina
/// doblada, y la actual un borde de 2 px.
class ExamGrid extends StatelessWidget {
  const ExamGrid({
    required this.session,
    required this.indiceActual,
    required this.onSeleccionar,
    this.agrupada = true,
    super.key,
  });

  final StudySession session;
  final int indiceActual;
  final ValueChanged<int> onSeleccionar;

  /// Agrupar por área. Se apaga en la revisión, donde el orden importa menos.
  final bool agrupada;

  @override
  Widget build(BuildContext context) {
    if (!agrupada) {
      return _Bloque(
        session: session,
        desde: 0,
        hasta: session.preguntas.length,
        indiceActual: indiceActual,
        onSeleccionar: onSeleccionar,
      );
    }

    final grupos = _agrupar();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final g in grupos) ...[
          Padding(
            padding: const EdgeInsets.only(
              top: DesignTokens.space4,
              bottom: DesignTokens.space2,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    g.etiqueta,
                    style: context.texts.bodySmall?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: context.scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Text(
                  '${g.desde + 1}–${g.hasta}',
                  style: context.texts.bodySmall?.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
          _Bloque(
            session: session,
            desde: g.desde,
            hasta: g.hasta,
            indiceActual: indiceActual,
            onSeleccionar: onSeleccionar,
          ),
        ],
      ],
    );
  }

  /// Corta la grilla en tramos consecutivos del mismo área.
  ///
  /// Durante el simulacro **no se conoce el área** (RN-09): el servidor no la
  /// manda. En ese caso se agrupa por tramos de 20, que igual da referencias
  /// para ubicarse sin revelar la clasificación.
  List<({String etiqueta, int desde, int hasta})> _agrupar() {
    final total = session.preguntas.length;
    final conArea = session.preguntas.any((q) => q.areaId != null);

    if (!conArea) {
      return [
        for (var i = 0; i < total; i += 20)
          (
            etiqueta: 'PREGUNTAS ${i + 1} A ${(i + 20).clamp(0, total)}',
            desde: i,
            hasta: (i + 20).clamp(0, total),
          ),
      ];
    }

    final grupos = <({String etiqueta, int desde, int hasta})>[];
    var inicio = 0;
    for (var i = 1; i <= total; i++) {
      final cambio =
          i == total ||
          session.preguntas[i].areaId != session.preguntas[inicio].areaId;
      if (cambio) {
        grupos.add((
          etiqueta:
              (session.preguntas[inicio].areaId ?? 'Sin área').toUpperCase(),
          desde: inicio,
          hasta: i,
        ));
        inicio = i;
      }
    }
    return grupos;
  }
}

class _Bloque extends StatelessWidget {
  const _Bloque({
    required this.session,
    required this.desde,
    required this.hasta,
    required this.indiceActual,
    required this.onSeleccionar,
  });

  final StudySession session;
  final int desde;
  final int hasta;
  final int indiceActual;
  final ValueChanged<int> onSeleccionar;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Columnas según el ancho real, no un número fijo: a 360 px caben 7 con
        // 40 px de casilla; en una pantalla más ancha entran más.
        const casilla = 40.0;
        const separacion = DesignTokens.space1 + 2;
        final columnas = ((constraints.maxWidth + separacion) /
                (casilla + separacion))
            .floor()
            .clamp(5, 10);

        return Wrap(
          spacing: separacion,
          runSpacing: separacion,
          children: [
            for (var i = desde; i < hasta; i++)
              _Casilla(
                numero: i + 1,
                estado: _estado(i),
                lado:
                    (constraints.maxWidth - separacion * (columnas - 1)) /
                    columnas,
                onTap: () => onSeleccionar(i),
              ),
          ],
        );
      },
    );
  }

  CellState _estado(int i) {
    if (i == indiceActual) return CellState.actual;
    final r = session.respuestas[session.preguntas[i].id];
    if (r?.marcada == true) return CellState.marcada;
    if (r?.optionId != null) return CellState.respondida;
    return CellState.sinResponder;
  }
}

class _Casilla extends StatelessWidget {
  const _Casilla({
    required this.numero,
    required this.estado,
    required this.lado,
    required this.onTap,
  });

  final int numero;
  final CellState estado;
  final double lado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final states = context.states;

    final (fondo, borde, ancho, texto) = switch (estado) {
      CellState.actual => (
        scheme.primary,
        scheme.primary,
        2.0,
        scheme.onPrimary,
      ),
      CellState.respondida => (
        states.info.tint,
        states.info.base,
        1.0,
        states.info.onTint,
      ),
      CellState.marcada => (
        states.warning.tint,
        states.warning.base,
        1.0,
        states.warning.onTint,
      ),
      CellState.sinResponder => (
        scheme.surface,
        scheme.outlineVariant,
        1.0,
        scheme.onSurfaceVariant,
      ),
    };

    return Semantics(
      button: true,
      label: 'Pregunta $numero, ${_descripcion(estado)}',
      child: SizedBox(
        width: lado,
        height: lado,
        child: Material(
          color: fondo,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: borde, width: ancho),
            borderRadius: BorderRadius.circular(DesignTokens.radiusSm + 2),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(DesignTokens.radiusSm + 2),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    '$numero',
                    style: context.texts.bodySmall?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: texto,
                    ),
                  ),
                ),
                // Esquina doblada: la marca no depende solo del color.
                if (estado == CellState.marcada)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: CustomPaint(
                      size: const Size(9, 9),
                      painter: _EsquinaPainter(states.warning.base),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _descripcion(CellState e) => switch (e) {
    CellState.actual => 'en la que estás',
    CellState.respondida => 'respondida',
    CellState.marcada => 'marcada para revisar',
    CellState.sinResponder => 'sin responder',
  };
}

class _EsquinaPainter extends CustomPainter {
  const _EsquinaPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_EsquinaPainter old) => old.color != color;
}

/// Leyenda de la grilla. Sin ella los colores no significan nada.
class ExamGridLegend extends StatelessWidget {
  const ExamGridLegend({required this.session, super.key});

  final StudySession session;

  @override
  Widget build(BuildContext context) {
    final states = context.states;
    final scheme = context.scheme;

    return Wrap(
      spacing: DesignTokens.space4,
      runSpacing: DesignTokens.space2,
      children: [
        _Item(
          color: states.info.tint,
          borde: states.info.base,
          texto: 'Respondidas · ${session.respondidas}',
        ),
        _Item(
          color: scheme.surface,
          borde: scheme.outlineVariant,
          texto: 'Sin responder · ${session.sinResponder}',
        ),
        _Item(
          color: states.warning.tint,
          borde: states.warning.base,
          texto: 'Marcadas · ${session.marcadas}',
        ),
      ],
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.color, required this.borde, required this.texto});

  final Color color;
  final Color borde;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: borde),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: DesignTokens.space2),
        Text(texto, style: context.texts.bodySmall?.copyWith(fontSize: 13)),
      ],
    );
  }
}
