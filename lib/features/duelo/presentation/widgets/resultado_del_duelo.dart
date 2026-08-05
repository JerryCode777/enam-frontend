import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/state_colors.dart';
import '../../../../shared/widgets/enam_button.dart';
import '../../domain/duelo_models.dart';
import 'avatar_de_jugador.dart';

/// La pantalla de resultado.
///
/// Es el único momento en que se enseñan los aciertos del rival, y por eso es
/// la parte emocionante: durante la partida solo se veía cuántas llevaba.
class ResultadoDelDuelo extends StatelessWidget {
  const ResultadoDelDuelo({
    required this.resultado,
    required this.rival,
    required this.onRevancha,
    required this.onRevisar,
    required this.onOtroOponente,
    required this.onInicio,
    this.pidiendoRevancha = false,
    this.meRetan = false,
    super.key,
  });

  final FinalDeDuelo resultado;
  final String rival;

  /// El rival ya pidió la revancha y está esperando (RF-61).
  ///
  /// Sin este aviso, la única forma de que los dos se juntaran era que pulsaran
  /// por su cuenta y casi a la vez — y quien pulsaba primero se quedaba solo
  /// hasta que le ofrecían el bot.
  final bool meRetan;

  final bool pidiendoRevancha;
  final VoidCallback onRevancha;
  final VoidCallback onRevisar;
  final VoidCallback onOtroOponente;
  final VoidCallback onInicio;

  /// Se jugó con el duelo diario gratuito (RF-65).
  ///
  /// Cambia dos cosas, y las dos son para NO ofrecer lo que el servidor va a
  /// rechazar: no hay revisión que abrir y el pase no da revancha. Un botón que
  /// lleva a un error es peor que no tener botón.
  bool get _conPase => resultado.conPaseGratis;

  bool get _ganaste => resultado.desenlace == Desenlace.ganaste;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(DesignTokens.space4),
      children: [
        _Marcador(resultado: resultado, rival: rival, ganaste: _ganaste),

        const SizedBox(height: DesignTokens.space4),

        // La nota vive fuera del marcador: es el dato serio, y encima del
        // degradado competía con lo emocionante.
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space5,
            vertical: DesignTokens.space4,
          ),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tu nota',
                style: texto.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              Text(
                resultado.tuNota.toStringAsFixed(2),
                style: texto.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),

        if (resultado.porTiempo) ...[
          const SizedBox(height: DesignTokens.space3),
          Text(
            'Empataron en aciertos: ganó quien tardó menos — '
            '${(resultado.tuTiempoTotalMs / 1000).toStringAsFixed(1)} s contra '
            '${(resultado.rivalTiempoTotalMs / 1000).toStringAsFixed(1)} s.',
            style: texto.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],

        if (meRetan && !_conPase) ...[
          const SizedBox(height: DesignTokens.space4),
          _AvisoDeRevancha(rival: rival),
        ],

        const SizedBox(height: DesignTokens.space5),

        if (!_conPase) ...[
          EnamButton(
            // La revancha va primero y en primario: es lo que el usuario
            // quiere hacer justo después de perder, y es lo que trae la
            // siguiente partida.
            label: meRetan ? 'Aceptar la revancha' : 'Revancha con $rival',
            icon: Symbols.replay,
            loading: pidiendoRevancha,
            onPressed: onRevancha,
          ),
          const SizedBox(height: DesignTokens.space3),
          OutlinedButton(
            onPressed: onRevisar,
            child: Text('Revisar las ${resultado.revision.length} preguntas'),
          ),
          const SizedBox(height: DesignTokens.space3),
          TextButton(onPressed: onOtroOponente, child: const Text('Otro oponente')),
        ] else
          // Se dice lo que hay, en vez de dejar un hueco donde estaban dos
          // botones. Y se dice qué se gana pagando —las explicaciones— porque
          // es cierto y es exactamente lo que le faltó a esta partida.
          Container(
            padding: const EdgeInsets.all(DesignTokens.space4),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
            ),
            child: Text(
              'Con el duelo gratis no se guarda la revisión. Con un plan puedes '
              'repasar las diez con su explicación, y jugar sin límite.',
              style: texto.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),

        const SizedBox(height: DesignTokens.space3),
        TextButton(onPressed: onInicio, child: const Text('Volver al inicio')),
      ],
    );
  }
}

/// El marcador final: quién ganó, contra quién y con cuánto.
///
/// **El destacado NO siempre es el tuyo.** Si perdiste, el que resalta es el
/// rival. Marcar siempre el propio sería no decir el resultado, que es el único
/// trabajo de esta pantalla.
class _Marcador extends StatelessWidget {
  const _Marcador({
    required this.resultado,
    required this.rival,
    required this.ganaste,
  });

  final FinalDeDuelo resultado;
  final String rival;
  final bool ganaste;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final oscuro = Theme.of(context).brightness == Brightness.dark;

    final titulo = switch (resultado.desenlace) {
      Desenlace.ganaste => '¡Ganaste!',
      Desenlace.perdiste => 'Perdiste',
      Desenlace.empate => 'Empate',
    };

    final marcador = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space4,
        vertical: DesignTokens.space7,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          // El degradado de marca de siempre, el mismo que la cabecera de la
          // app, así que sigue al tema oscuro sin definirlo dos veces.
          colors: oscuro
              ? DesignTokens.headerGradientDark
              : DesignTokens.headerGradientLight,
          stops: DesignTokens.headerGradientStops,
        ),
      ),
      child: Column(
        children: [
          Text(
            titulo,
            style: (ganaste ? texto.displaySmall : texto.headlineSmall)
                ?.copyWith(fontWeight: FontWeight.w800, color: Colors.white),
          ),
          if (resultado.porAbandono) ...[
            const SizedBox(height: DesignTokens.space1),
            Text(
              // «Ganaste» a secas cuando el otro abandonó se lee como una
              // burla.
              ganaste ? '$rival dejó el duelo' : 'Dejaste el duelo',
              style: texto.bodyMedium?.copyWith(color: Colors.white70),
            ),
          ],
          const SizedBox(height: DesignTokens.space6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _JugadorFinal(
                  nombre: 'Tú',
                  aciertos: resultado.tusAciertos,
                  gano: resultado.desenlace == Desenlace.ganaste,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: DesignTokens.space8),
                child: Text(
                  '·',
                  style: texto.headlineMedium?.copyWith(color: Colors.white54),
                ),
              ),
              Expanded(
                child: _JugadorFinal(
                  nombre: rival,
                  aciertos: resultado.rivalAciertos,
                  gano: resultado.desenlace == Desenlace.perdiste,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (!ganaste) return marcador;

    // Ganar se nota, y la luz entra por las ESQUINAS.
    //
    // Puesta en el centro —que fue el primer intento— cae justo detrás del
    // «¡Ganaste!»: ámbar sobre azul a media opacidad no da dorado, da un caqui
    // apagado —son colores opuestos y mezclarlos apaga los dos— y encima le
    // baja el contraste al texto blanco. En las esquinas no hay nada escrito.
    return ClipRRect(
      borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      child: Stack(
        children: [
          marcador,
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topLeft,
                    radius: 1.1,
                    colors: [Color(0x8CF59E0B), Color(0x00F59E0B)],
                  ),
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.bottomRight,
                    radius: 1.0,
                    colors: [Color(0x66F59E0B), Color(0x00F59E0B)],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JugadorFinal extends StatelessWidget {
  const _JugadorFinal({
    required this.nombre,
    required this.aciertos,
    required this.gano,
  });

  final String nombre;
  final int aciertos;
  final bool gano;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            AvatarDeJugador(
              nombre: nombre,
              tamano: 64,
              fondo: gano ? Colors.white : Colors.transparent,
              tinta: gano ? DesignTokens.headerGradientLight.first : Colors.white70,
              borde: gano ? null : Colors.white38,
            ),
            if (gano)
              Positioned(
                right: -4,
                bottom: -4,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: DesignTokens.warning,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Symbols.workspace_premium,
                    size: 18,
                    color: Colors.black87,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: DesignTokens.space3),
        Text(
          nombre,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: texto.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: gano ? Colors.white : Colors.white70,
          ),
        ),
        const SizedBox(height: DesignTokens.space1),
        Text(
          '$aciertos',
          style: texto.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: gano ? Colors.white : Colors.white60,
          ),
        ),
      ],
    );
  }
}

class _AvisoDeRevancha extends StatelessWidget {
  const _AvisoDeRevancha({required this.rival});

  final String rival;

  @override
  Widget build(BuildContext context) {
    final estados = context.states;
    final texto = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.space4),
      decoration: BoxDecoration(
        color: estados.info.tint,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(color: estados.info.base),
      ),
      child: Row(
        children: [
          Icon(Symbols.notifications_active, color: estados.info.base),
          const SizedBox(width: DesignTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$rival quiere la revancha',
                  style: texto.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: estados.info.onTint,
                  ),
                ),
                Text(
                  'Te está esperando ahora mismo',
                  style: texto.bodySmall?.copyWith(color: estados.info.onTint),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
