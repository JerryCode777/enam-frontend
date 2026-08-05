import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/state_colors.dart';
import '../../domain/duelo_models.dart';
import 'avatar_de_jugador.dart';

/// La cabecera de la partida: quién es quién y cómo va cada uno.
///
/// # La regla que se defiende aquí
///
/// **Los aciertos del rival no se enseñan hasta que el duelo termina.** Se sabe
/// cuántas lleva respondidas —eso pone nervioso, que es lo que hace tenso el
/// duelo— pero no cuántas acertó, que lo desinflaría. El backend manda
/// `aciertos` en nulo a propósito, y aquí un nulo se pinta como «va por la 4»,
/// nunca como un cero.
class MarcadorDuelo extends StatelessWidget {
  const MarcadorDuelo({required this.partida, this.rivalRespondidas, super.key});

  final EstadoDeLaPartida partida;

  /// Cuántas lleva el rival según el último aviso en vivo.
  ///
  /// Va aparte de `partida.rival.respondidas` porque el mensaje que lo trae
  /// —`rival_respondio`— **no incluye el marcador**. Sin este dato, la fila del
  /// rival no se movía hasta que la pregunta se cerraba, y el hueco se leía
  /// como que la app se había colgado.
  final int? rivalRespondidas;

  @override
  Widget build(BuildContext context) {
    final total = partida.totalPreguntas;
    final rival = partida.rival;
    final respondidasDelRival = rivalRespondidas != null
        ? (rivalRespondidas! > rival.respondidas
              ? rivalRespondidas!
              : rival.respondidas)
        : rival.respondidas;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space4,
        vertical: DesignTokens.space3,
      ),
      child: Row(
        children: [
          Expanded(
            child: _LadoDelMarcador(
              lado: partida.tu,
              nombre: 'Tú',
              respondidas: partida.tu.respondidas,
              total: total,
              alineado: CrossAxisAlignment.start,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.space2,
            ),
            child: Text(
              'VS',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: _LadoDelMarcador(
              lado: rival,
              nombre: rival.nombre.isEmpty ? 'Rival' : rival.nombre,
              respondidas: respondidasDelRival,
              total: total,
              alineado: CrossAxisAlignment.end,
            ),
          ),
        ],
      ),
    );
  }
}

class _LadoDelMarcador extends StatelessWidget {
  const _LadoDelMarcador({
    required this.lado,
    required this.nombre,
    required this.respondidas,
    required this.total,
    required this.alineado,
  });

  final LadoDuelo lado;
  final String nombre;
  final int respondidas;
  final int total;
  final CrossAxisAlignment alineado;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    // El bot no tiene socket y nunca se cae. Si se pintara como caído, el rival
    // humano vería «sin conexión» durante toda la partida.
    final caido = !lado.conectado && !lado.esBot;

    final aLaDerecha = alineado == CrossAxisAlignment.end;

    return Column(
      crossAxisAlignment: alineado,
      children: [
        Row(
          mainAxisAlignment: aLaDerecha
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            if (!aLaDerecha) ...[
              AvatarDeJugador(nombre: nombre, esBot: lado.esBot, tamano: 32),
              const SizedBox(width: DesignTokens.space2),
            ],
            Flexible(
              child: Text(
                nombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: texto.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            if (aLaDerecha) ...[
              const SizedBox(width: DesignTokens.space2),
              AvatarDeJugador(nombre: nombre, esBot: lado.esBot, tamano: 32),
            ],
          ],
        ),
        const SizedBox(height: DesignTokens.space1),
        _FilaDePuntos(
          resultados: lado.resultados,
          respondidas: respondidas,
          total: total,
          alineado: alineado,
          nombre: nombre,
        ),
        if (caido)
          Padding(
            padding: const EdgeInsets.only(top: DesignTokens.space1),
            child: Text(
              'Sin conexión',
              style: texto.labelSmall?.copyWith(
                color: context.states.warning.onTint,
                fontWeight: FontWeight.w700,
              ),
            ),
          )
        else if (lado.aciertos != null)
          Padding(
            padding: const EdgeInsets.only(top: DesignTokens.space1),
            child: Text(
              '${lado.aciertos} aciertos',
              style: texto.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
      ],
    );
  }
}

/// La fila de puntos, uno por pregunta.
///
/// Se manda como lista y no como dos contadores porque lo interesante es el
/// patrón —fallé las tres primeras y luego acerté cinco— y eso un número no lo
/// cuenta.
///
/// Cuando el marcador del rival está oculto llegan todos vacíos: se ve cuántas
/// respondió (los puntos rellenos en gris) pero no cómo le fue.
class _FilaDePuntos extends StatelessWidget {
  const _FilaDePuntos({
    required this.resultados,
    required this.respondidas,
    required this.total,
    required this.alineado,
    required this.nombre,
  });

  final List<ResultadoPorPregunta> resultados;
  final int respondidas;
  final int total;
  final CrossAxisAlignment alineado;
  final String nombre;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final estados = context.states;

    Color colorDe(int i) {
      final resultado = i < resultados.length
          ? resultados[i]
          : ResultadoPorPregunta.sinContestar;

      return switch (resultado) {
        ResultadoPorPregunta.acierto => estados.success.base,
        ResultadoPorPregunta.fallo => estados.error.base,
        // No responder NO es fallar. Se distingue también aquí y no solo en la
        // revisión: un rojo por no haber llegado a tiempo se lee como un error
        // que no se cometió.
        ResultadoPorPregunta.enBlanco => estados.warning.base,
        // Sin resultado visible: relleno si ya contestó, hueco si no. Es lo que
        // deja ver el ritmo del rival sin filtrar cómo le va.
        ResultadoPorPregunta.sinContestar => i < respondidas
            ? scheme.onSurfaceVariant
            : scheme.outlineVariant,
      };
    }

    return Semantics(
      label: _resumen(),
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: alineado == CrossAxisAlignment.end
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          for (var i = 0; i < total; i++)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 3),
              decoration: BoxDecoration(
                color: colorDe(i),
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  /// Lo mismo que dicen los puntos, para quien los oye en vez de verlos.
  String _resumen() {
    final aciertos = resultados
        .where((r) => r == ResultadoPorPregunta.acierto)
        .length;
    final fallos = resultados
        .where((r) => r == ResultadoPorPregunta.fallo)
        .length;
    final enBlanco = resultados
        .where((r) => r == ResultadoPorPregunta.enBlanco)
        .length;

    if (aciertos == 0 && fallos == 0 && enBlanco == 0) {
      return '$nombre: $respondidas de $total respondidas';
    }

    final partes = <String>[
      if (aciertos > 0) '$aciertos ${aciertos == 1 ? "acierto" : "aciertos"}',
      if (fallos > 0) '$fallos ${fallos == 1 ? "fallo" : "fallos"}',
      if (enBlanco > 0) '$enBlanco sin responder',
    ];
    return '$nombre: ${partes.join(", ")} de $total';
  }
}
