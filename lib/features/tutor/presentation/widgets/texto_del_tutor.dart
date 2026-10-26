import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/state_colors.dart';
import '../../domain/marcadores.dart';

/// El markdown del tutor, con los chips de cita dentro del párrafo.
///
/// Solo lo que el contrato permite: `##` y `###`, `**negrita**`, `*cursiva*`,
/// `` `código` `` y listas con `-` y `1.`. Es poco a propósito, y por eso se
/// pinta aquí en vez de traer un paquete de markdown entero: las citas tienen
/// que ir **dentro** de la línea, como un chip, y eso un renderizador genérico
/// no lo hace sin pelearse con él.
class TextoDelTutor extends StatelessWidget {
  const TextoDelTutor({
    required this.markdown,
    required this.onPregunta,
    required this.onClase,
    super.key,
  });

  final String markdown;
  final void Function(String id) onPregunta;
  final void Function(String cursoId, String claseId) onClase;

  @override
  Widget build(BuildContext context) {
    final bloques = _bloques(markdown);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < bloques.length; i++) ...[
          if (i > 0)
            SizedBox(
              height: bloques[i] is _Titulo
                  ? DesignTokens.space4
                  : DesignTokens.space2 + 2,
            ),
          _pintar(context, bloques[i]),
        ],
      ],
    );
  }

  Widget _pintar(BuildContext context, _Bloque bloque) {
    final cuerpo = context.texts.bodyLarge?.copyWith(
      height: DesignTokens.lineHeightRelaxed,
    );
    return switch (bloque) {
      _Titulo(:final nivel, :final texto) => Semantics(
        header: true,
        child: Text.rich(
          _enLinea(context, texto, cuerpo),
          style:
              (nivel <= 2
                      ? context.texts.titleMedium
                      : context.texts.titleSmall)
                  ?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: DesignTokens.lineHeightTight,
                  ),
        ),
      ),
      _Parrafo(:final texto) => Text.rich(
        _enLinea(context, texto, cuerpo),
        style: cuerpo,
      ),
      _Lista(:final items, :final ordenada) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: EdgeInsets.only(
                top: i == 0 ? 0 : DesignTokens.space1 + 2,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(
                      ordenada ? '${i + 1}.' : '•',
                      style: cuerpo?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.scheme.primary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text.rich(
                      _enLinea(context, items[i], cuerpo),
                      style: cuerpo,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    };
  }

  /// Negrita, cursiva, código y los chips, dentro de una línea.
  TextSpan _enLinea(BuildContext context, String texto, TextStyle? base) {
    final scheme = context.scheme;
    final hijos = <InlineSpan>[];
    var desde = 0;
    for (final m in _enLineaRe.allMatches(texto)) {
      if (m.start > desde) {
        hijos.add(TextSpan(text: texto.substring(desde, m.start)));
      }
      if (m.group(1) != null) {
        hijos.add(
          TextSpan(
            text: m.group(1),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        );
      } else if (m.group(2) != null) {
        // Sin fuente monoespaciada: aquí el «código» son dosis y valores
        // («30 ml/min»), no programas. Se resalta con la letra de la app.
        hijos.add(
          TextSpan(
            text: m.group(2),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
        );
      } else if (m.group(3) != null) {
        final id = m.group(3)!;
        hijos.add(
          _chip(
            context,
            icono: Symbols.quiz,
            texto: 'Ver pregunta',
            semantica: 'Abrir la pregunta citada',
            onTap: () => onPregunta(id),
          ),
        );
      } else if (m.group(4) != null) {
        final curso = m.group(4)!;
        final clase = m.group(5)!;
        hijos.add(
          _chip(
            context,
            icono: Symbols.play_circle,
            texto: 'Ver clase',
            semantica: 'Abrir la clase citada',
            onTap: () => onClase(curso, clase),
          ),
        );
      } else if (m.group(6) != null) {
        hijos.add(
          TextSpan(
            text: m.group(6),
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        );
      }
      desde = m.end;
    }
    if (desde < texto.length) {
      hijos.add(TextSpan(text: texto.substring(desde)));
    }
    return TextSpan(children: hijos);
  }

  WidgetSpan _chip(
    BuildContext context, {
    required IconData icono,
    required String texto,
    required String semantica,
    required VoidCallback onTap,
  }) {
    final info = context.states.info;
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Semantics(
          button: true,
          label: semantica,
          excludeSemantics: true,
          child: Material(
            color: info.tint,
            borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
            child: InkWell(
              borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.space2,
                  vertical: 3,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icono, size: 15, color: info.onTint),
                    const SizedBox(width: DesignTokens.space1),
                    Text(
                      texto,
                      style: context.texts.labelMedium?.copyWith(
                        color: info.onTint,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Un solo patrón con todas las piezas en línea, en orden de prioridad:
/// 1 negrita, 2 código, 3 pregunta, 4-5 clase, 6 cursiva.
final _enLineaRe = RegExp(
  r'\*\*(.+?)\*\*'
  r'|`([^`]+)`'
  '|${citaDePregunta.pattern}'
  '|${citaDeClase.pattern}'
  r'|\*([^*\s][^*]*?)\*',
);

sealed class _Bloque {
  const _Bloque();
}

final class _Titulo extends _Bloque {
  const _Titulo(this.nivel, this.texto);

  final int nivel;
  final String texto;
}

final class _Parrafo extends _Bloque {
  const _Parrafo(this.texto);

  final String texto;
}

final class _Lista extends _Bloque {
  const _Lista(this.items, {required this.ordenada});

  final List<String> items;
  final bool ordenada;
}

final _titulo = RegExp(r'^(#{1,6})\s+(.*)$');
final _vineta = RegExp(r'^\s*[-*•]\s+(.*)$');
final _numerada = RegExp(r'^\s*\d+[.)]\s+(.*)$');

/// Corta el markdown en títulos, párrafos y listas.
List<_Bloque> _bloques(String markdown) {
  final bloques = <_Bloque>[];
  final parrafo = <String>[];
  final lista = <String>[];
  bool? ordenada;

  void cerrarParrafo() {
    if (parrafo.isEmpty) return;
    bloques.add(_Parrafo(parrafo.join(' ')));
    parrafo.clear();
  }

  void cerrarLista() {
    if (lista.isEmpty) return;
    bloques.add(_Lista([...lista], ordenada: ordenada ?? false));
    lista.clear();
    ordenada = null;
  }

  for (final crudo in markdown.split('\n')) {
    final linea = crudo.trimRight();
    if (linea.trim().isEmpty) {
      cerrarParrafo();
      cerrarLista();
      continue;
    }
    if (_titulo.firstMatch(linea) case final m?) {
      cerrarParrafo();
      cerrarLista();
      bloques.add(_Titulo(m.group(1)!.length, m.group(2)!.trim()));
      continue;
    }
    final vineta = _vineta.firstMatch(linea);
    final numerada = vineta == null ? _numerada.firstMatch(linea) : null;
    if (vineta != null || numerada != null) {
      cerrarParrafo();
      final esNumerada = numerada != null;
      if (ordenada != null && ordenada != esNumerada) cerrarLista();
      ordenada = esNumerada;
      lista.add((vineta ?? numerada)!.group(1)!.trim());
      continue;
    }
    cerrarLista();
    parrafo.add(linea.trim());
  }
  cerrarParrafo();
  cerrarLista();
  return bloques;
}
