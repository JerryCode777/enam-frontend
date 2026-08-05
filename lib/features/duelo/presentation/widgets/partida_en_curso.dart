import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/state_colors.dart';
import '../../../session/domain/session_models.dart';
import '../../../session/presentation/widgets/option_card.dart';
import '../../data/duelo_socket.dart';
import '../../domain/duelo_models.dart';
import 'cuenta_atras_de_la_pregunta.dart';
import 'marcador_duelo.dart';

/// La pregunta abierta, con el marcador arriba y el reloj corriendo.
///
/// # Responder es un solo toque, no dos
///
/// En la práctica hay que seleccionar y confirmar, porque leyendo un caso
/// clínico largo es fácil tocar de más y ahí no hay prisa. Aquí sí la hay: son
/// veinte o treinta segundos contra otra persona, y pedir dos toques regala
/// medio segundo en cada pregunta. La confirmación se cambia por una señal
/// clara de qué se marcó, y por el hecho de que la respuesta se cierra sola.
///
/// # Lo que pasa si la respuesta no sale
///
/// [onResponder] devuelve **si salió de verdad por la línea**. Un socket
/// cerrado se traga lo que le echen sin protestar, y dar por contestada una
/// pregunta que nunca llegó es peor que decir que no salió: el servidor la
/// contaría en blanco y la pantalla diría que respondiste.
class PartidaEnCurso extends StatefulWidget {
  const PartidaEnCurso({
    required this.estado,
    required this.onResponder,
    super.key,
  });

  final EstadoDelDuelo estado;

  /// Devuelve si la respuesta salió. `null` es «se acabó el tiempo».
  final bool Function(String? opcionId) onResponder;

  @override
  State<PartidaEnCurso> createState() => _PartidaEnCursoState();
}

class _PartidaEnCursoState extends State<PartidaEnCurso> {
  String? _marcada;
  bool _enviada = false;

  /// Cuál apertura de pregunta se está contestando.
  ///
  /// Se compara con `aperturaDeLaPregunta` y **no con el orden**: al reconectar,
  /// el servidor puede reabrir la MISMA pregunta. Con el orden como única
  /// señal, la pantalla se quedaba con la respuesta anterior dada por buena
  /// aunque el servidor no la tuviera.
  int _apertura = -1;

  @override
  Widget build(BuildContext context) {
    final estado = widget.estado;
    final partida = estado.partida;
    final pregunta = estado.pregunta;
    final resultado = estado.resultado;

    // Pregunta nueva —o la misma reabierta—: se limpia lo marcado.
    if (pregunta != null && estado.aperturaDeLaPregunta != _apertura) {
      _apertura = estado.aperturaDeLaPregunta;
      _marcada = null;
      _enviada = false;
    }

    return Column(
      children: [
        if (partida != null)
          MarcadorDuelo(
            partida: partida,
            rivalRespondidas: estado.rivalRespondidas,
          ),

        if (estado.aviso != null) _Aviso(texto: estado.aviso!),

        if (estado.rivalCaido && partida != null)
          _Aviso(
            texto:
                '${partida.rival.nombre} perdió la conexión. El reloj no se '
                'detiene.',
            tono: _Tono.espera,
          ),

        Expanded(
          child: resultado != null
              ? _ResultadoDeLaPregunta(resultado: resultado, estado: estado)
              : pregunta == null
              ? const _EntrePreguntas()
              : _Pregunta(
                  pregunta: pregunta,
                  marcada: _marcada,
                  bloqueada: _enviada,
                  onTocar: _responder,
                ),
        ),
      ],
    );
  }

  void _responder(String opcionId) {
    if (_enviada) return;

    setState(() => _marcada = opcionId);

    final salio = widget.onResponder(opcionId);
    if (salio) {
      setState(() => _enviada = true);
      return;
    }

    // No salió: se deshace la marca para que el usuario pueda volver a
    // intentarlo, y se le dice. Dejarla puesta sería exactamente la mentira
    // que este camino existe para evitar.
    setState(() => _marcada = null);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No salió tu respuesta. Revisa tu conexión.'),
      ),
    );
  }
}

class _Pregunta extends StatelessWidget {
  const _Pregunta({
    required this.pregunta,
    required this.marcada,
    required this.bloqueada,
    required this.onTocar,
  });

  final PreguntaEnJuego pregunta;
  final String? marcada;
  final bool bloqueada;
  final void Function(String opcionId) onTocar;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.space4,
        0,
        DesignTokens.space4,
        DesignTokens.space6,
      ),
      children: [
        CuentaAtrasDeLaPregunta(
          cierraEn: pregunta.cierraEn,
          segundos: pregunta.segundos,
        ),
        const SizedBox(height: DesignTokens.space4),
        Text(
          'Pregunta ${pregunta.orden} de ${pregunta.totalPreguntas}',
          style: texto.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: DesignTokens.space2),
        Text(
          pregunta.enunciado,
          style: texto.titleMedium?.copyWith(height: 1.4),
        ),
        const SizedBox(height: DesignTokens.space5),
        for (var i = 0; i < pregunta.opciones.length; i++) ...[
          OptionCard(
            opcion: QuestionOption(
              id: pregunta.opciones[i].id,
              texto: pregunta.opciones[i].texto,
            ),
            letra: String.fromCharCode(65 + i),
            visual: marcada == pregunta.opciones[i].id
                ? OptionVisual.seleccionada
                : OptionVisual.normal,
            onTap: bloqueada ? null : () => onTocar(pregunta.opciones[i].id),
          ),
          const SizedBox(height: DesignTokens.space2),
        ],
        if (bloqueada)
          Padding(
            padding: const EdgeInsets.only(top: DesignTokens.space2),
            child: Text(
              'Respondiste. Esperando a que se cierre la pregunta…',
              style: texto.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}

/// Cómo salió la pregunta, mientras llega la siguiente.
///
/// No lleva la explicación a propósito: son tres segundos con el rival
/// esperando y nadie lee un párrafo ahí. La explicación vive en la revisión
/// final, que es donde se puede leer con calma.
class _ResultadoDeLaPregunta extends StatelessWidget {
  const _ResultadoDeLaPregunta({required this.resultado, required this.estado});

  final ResultadoDePregunta resultado;
  final EstadoDelDuelo estado;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final estados = context.states;

    // Tres desenlaces y no dos: **no responder no es fallar**. Una es no saber
    // y la otra es no llegar, y decirlo cambia cómo se encaja.
    final sinResponder = resultado.tuOpcionId == null;
    final (color, icono, titulo) = sinResponder
        ? (estados.warning, Symbols.schedule, 'Se acabó el tiempo')
        : resultado.acertaste
        ? (estados.success, Symbols.check, '¡Correcto!')
        : (estados.error, Symbols.close, 'Incorrecto');

    final correcta = _textoDeLaCorrecta();

    return Container(
      width: double.infinity,
      color: color.tint,
      padding: const EdgeInsets.all(DesignTokens.space6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(color: color.base, shape: BoxShape.circle),
            child: Icon(icono, size: 48, color: Colors.white),
          ),
          const SizedBox(height: DesignTokens.space5),
          Text(
            titulo,
            style: texto.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: color.onTint,
            ),
            textAlign: TextAlign.center,
          ),
          if (!resultado.acertaste && correcta != null) ...[
            const SizedBox(height: DesignTokens.space3),
            Text(
              // Con su texto y no solo la letra: a esta altura de la partida
              // nadie recuerda qué decía la C.
              'La correcta era $correcta',
              style: texto.bodyLarge?.copyWith(color: color.onTint),
              textAlign: TextAlign.center,
            ),
          ],
          if (!resultado.rivalRespondio && estado.partida != null) ...[
            const SizedBox(height: DesignTokens.space4),
            Text(
              '${estado.partida!.rival.nombre} no llegó a responder',
              style: texto.bodyMedium?.copyWith(
                color: color.onTint,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  /// El texto de la alternativa correcta, si la pantalla lo tiene a mano.
  ///
  /// Puede no tenerlo: el resultado llega con el id, y las opciones vienen en
  /// el mensaje de la pregunta, que ya se limpió. Cuando falta, se calla en vez
  /// de enseñar un id.
  String? _textoDeLaCorrecta() {
    final opciones = estado.pregunta?.opciones;
    if (opciones == null) return null;
    for (final o in opciones) {
      if (o.id == resultado.opcionCorrectaId) return o.texto;
    }
    return null;
  }
}

class _EntrePreguntas extends StatelessWidget {
  const _EntrePreguntas();

  @override
  Widget build(BuildContext context) => const Center(
    child: SizedBox(
      width: 32,
      height: 32,
      child: CircularProgressIndicator(strokeWidth: 3),
    ),
  );
}

enum _Tono { aviso, espera }

class _Aviso extends StatelessWidget {
  const _Aviso({required this.texto, this.tono = _Tono.aviso});

  final String texto;
  final _Tono tono;

  @override
  Widget build(BuildContext context) {
    final color = tono == _Tono.espera
        ? context.states.warning
        : context.states.info;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: DesignTokens.space4),
      padding: const EdgeInsets.all(DesignTokens.space3),
      decoration: BoxDecoration(
        color: color.tint,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      ),
      child: Text(
        texto,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: color.onTint),
        textAlign: TextAlign.center,
      ),
    );
  }
}
