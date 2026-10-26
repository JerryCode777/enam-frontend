import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/analitica/analitica.dart';
import '../../../core/router/navegar.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/state_colors.dart';
import '../../../shared/widgets/state_banner.dart';
import '../../subscription/domain/acceso.dart';
import '../../subscription/presentation/muro_de_venta_screen.dart';
import '../domain/marcadores.dart';
import '../domain/tutor_models.dart';
import 'tutor_controller.dart';
import 'widgets/piezas_del_tutor.dart';
import 'widgets/texto_del_tutor.dart';

/// El tutor con IA (fase 1).
///
/// Copia la experiencia del tutor de StudyFetch, no su aspecto (plan en
/// `sparky-research/PLAN-ENAM.md`). La regla que manda: **el alumno nunca
/// tiene que pensar qué escribir**. Siempre hay un botón para el siguiente
/// paso: tres sugerencias al empezar, respuestas rápidas al final de cada
/// respuesta y «No entiendo» bajo cada una.
///
/// La lista va invertida (lo nuevo abajo, anclado): mientras la respuesta
/// crece, la pantalla la sigue sin tener que calcular desplazamientos.
class TutorScreen extends ConsumerStatefulWidget {
  const TutorScreen({this.contexto = const ContextoDelTutor(), super.key});

  final ContextoDelTutor contexto;

  @override
  ConsumerState<TutorScreen> createState() => _TutorScreenState();
}

class _TutorScreenState extends ConsumerState<TutorScreen> {
  final _campo = TextEditingController();
  final _foco = FocusNode();

  @override
  void initState() {
    super.initState();
    ref.read(tutorControllerProvider.notifier).iniciar(widget.contexto);
    // Una vez por apertura, y solo si el servidor dice que está disponible.
    ref.read(estadoDelServicioProvider.future).then((servicio) {
      if (!mounted || servicio == null || !servicio.disponible) return;
      ref
          .read(analiticaProvider)
          .registrar(
            Evento.tutorAbierto,
            propiedades: propiedadesDeApertura(widget.contexto, servicio),
          );
    });
  }

  @override
  void dispose() {
    _campo.dispose();
    _foco.dispose();
    super.dispose();
  }

  void _enviar([String? texto, TipoDeMensaje tipo = TipoDeMensaje.normal]) {
    final mensaje = texto ?? _campo.text;
    if (mensaje.trim().isEmpty) return;
    ref.read(tutorControllerProvider.notifier).enviar(mensaje, tipo: tipo);
    if (texto == null) _campo.clear();
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(tutorControllerProvider);
    final nombre =
        ref.watch(estadoDelServicioProvider).value?.nombreVisible ??
        EstadoDelServicio.nombrePorDefecto;

    // Gastó la prueba: el muro, con el tutor como motivo. Una vez; si lo
    // cierra, queda la tarjeta con el botón en lugar de la caja de texto.
    ref.listen(tutorControllerProvider.select((e) => e.bloqueo), (antes, b) {
      if (antes == null && b == BloqueoDelTutor.gratisAgotado) {
        abrirMuro(context, ref, const FuncionDePago(FuncionPremium.tutor));
      }
    });

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            const AvatarDelTutor(size: 30),
            const SizedBox(width: DesignTokens.space2 + 2),
            Flexible(
              child: Text(
                nombre,
                overflow: TextOverflow.ellipsis,
                style: context.texts.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: estado.vacio
                  ? _EstadoVacio(
                      contexto: widget.contexto,
                      onSugerencia: (s) => _enviar(s, TipoDeMensaje.sugerencia),
                    )
                  : _Conversacion(
                      estado: estado,
                      onOpcion: (s) {
                        registrarAccionDelTutor(
                          ref.read(analiticaProvider),
                          'opcion',
                        );
                        _enviar(s, TipoDeMensaje.sugerencia);
                      },
                    ),
            ),
            switch (estado.bloqueo) {
              BloqueoDelTutor.gratisAgotado => const _Bloqueo(delDia: false),
              BloqueoDelTutor.limiteDelDia => const _Bloqueo(delDia: true),
              null => _CajaDeEntrada(
                campo: _campo,
                foco: _foco,
                ocupado: estado.respondiendo,
                restantes: estado.contadorVisible,
                onEnviar: _enviar,
              ),
            },
          ],
        ),
      ),
    );
  }
}

// ==================== ESTADO VACÍO ====================

class _EstadoVacio extends ConsumerWidget {
  const _EstadoVacio({required this.contexto, required this.onSugerencia});

  final ContextoDelTutor contexto;
  final void Function(String) onSugerencia;

  /// Si el servidor no manda sugerencias, estas. Una por categoría.
  static const _porDefecto = {
    CategoriaDeSugerencia.entender: 'Explícame un tema que me cuesta',
    CategoriaDeSugerencia.practicar: 'Hazme preguntas de mi área más débil',
    CategoriaDeSugerencia.plan: '¿Qué repaso esta semana?',
  };

  /// Con una pregunta como contexto, las sugerencias son sobre ella.
  static const _sobreLaPregunta = {
    CategoriaDeSugerencia.entender: '¿Por qué esta es la correcta?',
    CategoriaDeSugerencia.practicar: 'Hazme una pregunta parecida',
    CategoriaDeSugerencia.plan: '¿Qué más repaso de este tema?',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicio = ref.watch(estadoDelServicioProvider).value;
    final sugerencias = {
      for (final c in CategoriaDeSugerencia.values)
        c: contexto.sobreUnaPregunta
            ? _sobreLaPregunta[c]!
            : servicio?.sugerencias[c]?.firstOrNull ?? _porDefecto[c]!,
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.space5,
        DesignTokens.space8,
        DesignTokens.space5,
        DesignTokens.space5,
      ),
      children: [
        const Center(child: AvatarDelTutor(size: 64)),
        const SizedBox(height: DesignTokens.space4),
        Text(
          contexto.sobreUnaPregunta
              ? '¿Qué quieres saber de esta pregunta?'
              : '¿En qué te ayudo hoy?',
          textAlign: TextAlign.center,
          style: context.texts.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: DesignTokens.space2),
        Text(
          contexto.sobreUnaPregunta
              ? 'Ya la tengo a la vista, con su explicación.'
              : 'Conozco el banco de preguntas y tu avance. Pregúntame lo '
                    'que necesites.',
          textAlign: TextAlign.center,
          style: context.texts.bodyMedium?.copyWith(
            color: context.scheme.onSurfaceVariant,
          ),
        ),
        if (contexto.enunciado case final enunciado?) ...[
          const SizedBox(height: DesignTokens.space4),
          _PreguntaDeContexto(enunciado: enunciado),
        ],
        const SizedBox(height: DesignTokens.space6),
        for (final c in CategoriaDeSugerencia.values)
          Padding(
            padding: const EdgeInsets.only(bottom: DesignTokens.space2),
            child: _ChipDeSugerencia(
              categoria: c,
              texto: sugerencias[c]!,
              onTap: () => onSugerencia(sugerencias[c]!),
            ),
          ),
      ],
    );
  }
}

class _PreguntaDeContexto extends StatelessWidget {
  const _PreguntaDeContexto({required this.enunciado});

  final String enunciado;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Symbols.quiz, size: 18, color: scheme.primary),
          const SizedBox(width: DesignTokens.space2),
          Expanded(
            child: Text(
              enunciado,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: context.texts.bodySmall?.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipDeSugerencia extends StatelessWidget {
  const _ChipDeSugerencia({
    required this.categoria,
    required this.texto,
    required this.onTap,
  });

  final CategoriaDeSugerencia categoria;
  final String texto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final states = context.states;
    // Color e icono por categoría, como en el original; los colores son los
    // de estado de la app, que ya cumplen contraste en los dos temas.
    final (color, icono, etiqueta) = switch (categoria) {
      CategoriaDeSugerencia.entender => (
        states.info,
        Symbols.lightbulb,
        'Entender',
      ),
      CategoriaDeSugerencia.practicar => (
        states.success,
        Symbols.quiz,
        'Practicar',
      ),
      CategoriaDeSugerencia.plan => (
        states.warning,
        Symbols.calendar_month,
        'Plan',
      ),
    };
    final scheme = context.scheme;

    return Semantics(
      button: true,
      label: '$etiqueta: $texto',
      excludeSemantics: true,
      child: Material(
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.space3,
              vertical: DesignTokens.space3,
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.tint,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                  ),
                  child: Icon(icono, size: 18, color: color.onTint),
                ),
                const SizedBox(width: DesignTokens.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        etiqueta.toUpperCase(),
                        style: context.texts.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: color.onTint,
                        ),
                      ),
                      Text(
                        texto,
                        style: context.texts.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== CONVERSACIÓN ====================

class _Conversacion extends StatelessWidget {
  const _Conversacion({required this.estado, required this.onOpcion});

  final EstadoDelTutor estado;
  final void Function(String) onOpcion;

  @override
  Widget build(BuildContext context) {
    final mensajes = estado.mensajes;
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.space4,
        DesignTokens.space4,
        DesignTokens.space4,
        DesignTokens.space2,
      ),
      itemCount: mensajes.length,
      itemBuilder: (context, i) {
        final indice = mensajes.length - 1 - i;
        final m = mensajes[indice];
        final ultimo = indice == mensajes.length - 1;
        return Padding(
          padding: const EdgeInsets.only(bottom: DesignTokens.space4),
          child: m.esDelTutor
              ? RespuestaDelTutor(
                  key: ValueKey(m.id),
                  mensaje: m,
                  ultima: ultimo,
                  onOpcion: onOpcion,
                )
              : _MensajeDelAlumno(texto: m.texto),
        );
      },
    );
  }
}

class _MensajeDelAlumno extends StatelessWidget {
  const _MensajeDelAlumno({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.8,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space3 + 2,
            vertical: DesignTokens.space2 + 2,
          ),
          decoration: BoxDecoration(
            color: context.states.info.tint,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(DesignTokens.radiusLg),
              topRight: Radius.circular(DesignTokens.radiusLg),
              bottomLeft: Radius.circular(DesignTokens.radiusLg),
              bottomRight: Radius.circular(DesignTokens.radiusSm),
            ),
          ),
          child: Text(
            texto,
            style: context.texts.bodyLarge?.copyWith(
              color: scheme.onSurface,
              height: 1.45,
            ),
          ),
        ),
      ),
    );
  }
}

/// Una respuesta del tutor: avatar y texto sin burbuja, y debajo sus acciones.
class RespuestaDelTutor extends ConsumerStatefulWidget {
  const RespuestaDelTutor({
    required this.mensaje,
    required this.ultima,
    required this.onOpcion,
    super.key,
  });

  final MensajeDelTutor mensaje;

  /// Solo la última ofrece respuestas rápidas y «Reintentar»: en una vieja ya
  /// no tienen sentido.
  final bool ultima;
  final void Function(String) onOpcion;

  @override
  ConsumerState<RespuestaDelTutor> createState() => _RespuestaDelTutorState();
}

class _RespuestaDelTutorState extends ConsumerState<RespuestaDelTutor> {
  var _noEntiendoAbierto = false;

  @override
  Widget build(BuildContext context) {
    final m = widget.mensaje;
    final partes = partirRespuesta(
      m.texto,
      completo:
          m.estado == EstadoDelMensaje.listo ||
          m.estado == EstadoDelMensaje.fallo,
    );
    final pensando = m.texto.isEmpty && m.enCurso;
    final controller = ref.read(tutorControllerProvider.notifier);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: AvatarDelTutor(pensando: m.enCurso),
        ),
        const SizedBox(width: DesignTokens.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (pensando || m.fase != null)
                Semantics(
                  liveRegion: true,
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: 4,
                      bottom: pensando ? 0 : DesignTokens.space2,
                    ),
                    child: Text(
                      m.fase ?? 'Pensando…',
                      style: context.texts.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: context.scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              for (var i = 0; i < partes.length; i++)
                Padding(
                  padding: EdgeInsets.only(
                    top: i == 0 ? 0 : DesignTokens.space3,
                  ),
                  child: switch (partes[i]) {
                    TextoDeRespuesta(:final markdown) => TextoDelTutor(
                      markdown: markdown,
                      onPregunta: (id) => abrirPreguntaCitada(context, id),
                      onClase: (curso, clase) {
                        // Sin `marcador_valido`: la clase la carga su
                        // pantalla, y aquí no se sabe si existía.
                        registrarAccionDelTutor(
                          ref.read(analiticaProvider),
                          'abrir_clase',
                        );
                        context.irA(Routes.claseOf(curso, clase));
                      },
                    ),
                    final PracticaPropuesta p => TarjetaPracticar(practica: p),
                    OpcionesRapidas(:final opciones) =>
                      widget.ultima && m.estado == EstadoDelMensaje.listo
                          ? _Opciones(
                              opciones: opciones,
                              onTap: widget.onOpcion,
                            )
                          : const SizedBox.shrink(),
                  },
                ),
              if (m.estado == EstadoDelMensaje.fallo) ...[
                if (partes.isNotEmpty)
                  const SizedBox(height: DesignTokens.space3),
                StateBanner(
                  kind: BannerKind.error,
                  message: m.error ?? 'Se cortó la respuesta.',
                  action: widget.ultima
                      ? TextButton(
                          onPressed: controller.reintentar,
                          child: const Text('Reintentar'),
                        )
                      : null,
                ),
              ],
              if (m.estado == EstadoDelMensaje.listo) ...[
                const SizedBox(height: DesignTokens.space1),
                _BarraDeAcciones(
                  mensaje: m,
                  noEntiendoAbierto: _noEntiendoAbierto,
                  onNoEntiendo: () {
                    if (!_noEntiendoAbierto) {
                      registrarAccionDelTutor(
                        ref.read(analiticaProvider),
                        'no_entiendo',
                      );
                    }
                    setState(() => _noEntiendoAbierto = !_noEntiendoAbierto);
                  },
                ),
                if (_noEntiendoAbierto)
                  _FormularioNoEntiendo(
                    onCancelar: () =>
                        setState(() => _noEntiendoAbierto = false),
                    onEnviar: (texto) {
                      setState(() => _noEntiendoAbierto = false);
                      controller.noEntiendo(texto);
                    },
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Opciones extends StatelessWidget {
  const _Opciones({required this.opciones, required this.onTap});

  final List<String> opciones;
  final void Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: DesignTokens.space2,
      runSpacing: DesignTokens.space2,
      children: [
        for (final o in opciones)
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.space3,
                vertical: DesignTokens.space2,
              ),
            ),
            onPressed: () => onTap(o),
            child: Text(o),
          ),
      ],
    );
  }
}

/// Copiar · 👍 · 👎 · No entiendo. Sin regenerar ni voz en la fase 1.
class _BarraDeAcciones extends ConsumerWidget {
  const _BarraDeAcciones({
    required this.mensaje,
    required this.noEntiendoAbierto,
    required this.onNoEntiendo,
  });

  final MensajeDelTutor mensaje;
  final bool noEntiendoAbierto;
  final VoidCallback onNoEntiendo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.scheme;
    final controller = ref.read(tutorControllerProvider.notifier);
    final apagado = scheme.onSurfaceVariant;
    final marcado = scheme.primary;

    Widget boton({
      required IconData icono,
      required String tooltip,
      required VoidCallback onPressed,
      bool activo = false,
    }) => IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      iconSize: 18,
      isSelected: activo,
      icon: Icon(
        icono,
        color: activo ? marcado : apagado,
        fill: activo ? 1 : 0,
      ),
      onPressed: onPressed,
    );

    return Row(
      children: [
        boton(
          icono: Symbols.content_copy,
          tooltip: 'Copiar',
          onPressed: () async {
            registrarAccionDelTutor(ref.read(analiticaProvider), 'copiar');
            await Clipboard.setData(
              ClipboardData(text: textoParaCopiar(mensaje.texto)),
            );
            if (context.mounted) {
              ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                const SnackBar(content: Text('Respuesta copiada.')),
              );
            }
          },
        ),
        boton(
          icono: Symbols.thumb_up,
          tooltip: 'Me sirvió',
          activo: mensaje.util == true,
          onPressed: () => controller.valorar(mensaje.id, true),
        ),
        boton(
          icono: Symbols.thumb_down,
          tooltip: 'No me sirvió',
          activo: mensaje.util == false,
          onPressed: () => controller.valorar(mensaje.id, false),
        ),
        boton(
          icono: Symbols.help,
          tooltip: 'No entiendo',
          activo: noEntiendoAbierto,
          onPressed: onNoEntiendo,
        ),
      ],
    );
  }
}

class _FormularioNoEntiendo extends StatefulWidget {
  const _FormularioNoEntiendo({
    required this.onCancelar,
    required this.onEnviar,
  });

  final VoidCallback onCancelar;
  final void Function(String) onEnviar;

  @override
  State<_FormularioNoEntiendo> createState() => _FormularioNoEntiendoState();
}

class _FormularioNoEntiendoState extends State<_FormularioNoEntiendo> {
  final _campo = TextEditingController();

  @override
  void dispose() {
    _campo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Container(
      margin: const EdgeInsets.only(top: DesignTokens.space2),
      padding: const EdgeInsets.all(DesignTokens.space3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '¿Qué parte no entendiste?',
            style: context.texts.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: DesignTokens.space2),
          TextField(
            controller: _campo,
            autofocus: true,
            minLines: 2,
            maxLines: 4,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Por ejemplo: no entiendo por qué no es la B',
              counterText: '',
            ),
          ),
          const SizedBox(height: DesignTokens.space2),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: widget.onCancelar,
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: DesignTokens.space2),
              FilledButton(
                onPressed: () => widget.onEnviar(_campo.text),
                child: const Text('Enviar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==================== ENTRADA Y BLOQUEOS ====================

class _CajaDeEntrada extends StatelessWidget {
  const _CajaDeEntrada({
    required this.campo,
    required this.foco,
    required this.ocupado,
    required this.restantes,
    required this.onEnviar,
  });

  final TextEditingController campo;
  final FocusNode foco;
  final bool ocupado;

  /// El contador discreto de la prueba gratis, solo cuando quedan pocos.
  final int? restantes;
  final void Function() onEnviar;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.space4,
        DesignTokens.space2,
        DesignTokens.space3,
        DesignTokens.space3,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (restantes case final n?)
            Padding(
              padding: const EdgeInsets.only(bottom: DesignTokens.space1 + 2),
              child: Text(
                n == 1
                    ? 'Te queda 1 mensaje de prueba'
                    : 'Te quedan $n mensajes de prueba',
                style: context.texts.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: campo,
                  focusNode: foco,
                  minLines: 1,
                  maxLines: 5,
                  maxLength: 2000,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => ocupado ? null : onEnviar(),
                  decoration: const InputDecoration(
                    hintText: 'Escribe tu duda…',
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(width: DesignTokens.space2),
              ListenableBuilder(
                listenable: campo,
                builder: (context, _) => IconButton.filled(
                  tooltip: 'Enviar',
                  icon: const Icon(Symbols.arrow_upward),
                  onPressed: ocupado || campo.text.trim().isEmpty
                      ? null
                      : onEnviar,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// En lugar de la caja de texto cuando el tutor ya no responde.
class _Bloqueo extends ConsumerWidget {
  const _Bloqueo({required this.delDia});

  /// Premium sin mensajes hoy; si no, la prueba gratis agotada.
  final bool delDia;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = context.scheme;
    return Container(
      padding: const EdgeInsets.all(DesignTokens.space4),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: delDia
          ? const StateBanner(
              icon: Symbols.hourglass_bottom,
              message:
                  'Ya usaste tus mensajes de hoy con el tutor. Mañana tienes '
                  'más.',
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Usaste tus mensajes de prueba',
                  style: context.texts.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: DesignTokens.space1),
                Text(
                  'Con Premium sigues con el tutor todos los días: te '
                  'explica cada pregunta y te dice qué practicar.',
                  style: context.texts.bodyMedium,
                ),
                const SizedBox(height: DesignTokens.space3),
                FilledButton(
                  onPressed: () => abrirMuro(
                    context,
                    ref,
                    const FuncionDePago(FuncionPremium.tutor),
                  ),
                  child: const Text('Ver Premium'),
                ),
              ],
            ),
    );
  }
}
