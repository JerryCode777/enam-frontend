import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../domain/session_models.dart';
import '../../../core/config/app_config.dart';
import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/motion.dart';
import '../../../core/theme/state_colors.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/enam_button.dart';
import '../../../shared/widgets/state_banner.dart';
import 'session_controller.dart';
import 'widgets/exam_grid.dart';
import 'widgets/option_card.dart';
import 'widgets/watermark.dart';

/// Pantallas 5.3, 5.4 y 5.5 — el simulacro en curso.
///
/// Diferencias con la práctica, todas por RF-16 y RN-09:
/// - **Cronómetro siempre visible**, con alarma a 15 y 5 minutos
/// - **Ninguna retroalimentación**: responder solo avanza
/// - **No se muestra área ni tema** de la pregunta
/// - **Envío automático** al agotarse el tiempo, sin opción de seguir
/// - Grilla de 180 casillas para saltar a cualquier pregunta
class SimulacroScreen extends ConsumerStatefulWidget {
  const SimulacroScreen({required this.sessionId, super.key});

  final String sessionId;

  @override
  ConsumerState<SimulacroScreen> createState() => _SimulacroScreenState();
}

class _SimulacroScreenState extends ConsumerState<SimulacroScreen> {
  Timer? _reloj;
  Timer? _autoguardado;
  Duration _restante = Duration.zero;
  bool _enviado = false;

  /// Umbrales de aviso. A 15 minutos se avisa una vez; a 5 el cronómetro pasa a
  /// rojo y queda así.
  static const _aviso15 = Duration(minutes: 15);
  static const _aviso5 = Duration(minutes: 5);
  bool _aviso15Dado = false;

  @override
  void initState() {
    super.initState();
    _reloj = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    // Autoguardado cada 30 s: mitigación del riesgo de caída durante un
    // simulacro nacional que el SSD lista como alto.
    _autoguardado = Timer.periodic(AppConfig.examAutosaveInterval, (_) {
      // El repositorio ya persiste cada respuesta al enviarla; esto es el
      // gancho para cuando exista el endpoint de progreso parcial.
    });
  }

  @override
  void dispose() {
    _reloj?.cancel();
    _autoguardado?.cancel();
    super.dispose();
  }

  void _tick() {
    final estado = ref.read(sessionControllerProvider(widget.sessionId)).value;
    final restante = estado?.session.tiempoRestante;
    if (restante == null) return;

    if (mounted) setState(() => _restante = restante);

    if (!_aviso15Dado &&
        restante <= _aviso15 &&
        restante > _aviso5 &&
        mounted) {
      _aviso15Dado = true;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Quedan 15 minutos.')));
    }

    // Envío automático al agotarse, sin diálogo que pregunte: el tiempo del
    // examen real no se negocia.
    if (restante <= Duration.zero && !_enviado) {
      _enviado = true;
      unawaited(_enviar(automatico: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(sessionControllerProvider(widget.sessionId));

    return estado.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('No pudimos cargar el simulacro.')),
      ),
      data: (s) => _construir(context, s),
    );
  }

  Widget _construir(BuildContext context, SessionState estado) {
    final control = ref.read(
      sessionControllerProvider(widget.sessionId).notifier,
    );
    final usuario = ref.watch(currentUserProvider);
    final pregunta = estado.pregunta;

    // Sin salida por atrás: salir de un simulacro es una decisión explícita.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmarAbandono();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _Cabecera(
                estado: estado,
                restante: _restante,
                onGrilla: () => _abrirGrilla(estado, control),
                onSalir: _confirmarAbandono,
                onMarcar: control.alternarMarca,
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    DesignTokens.space5,
                    DesignTokens.space2,
                    DesignTokens.space5,
                    DesignTokens.space4,
                  ),
                  children: [
                    Watermark(
                      texto: _marca(usuario?.id, usuario?.email),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(
                            DesignTokens.space4 + 2,
                          ),
                          child: Text(
                            pregunta.enunciado,
                            style: context.texts.bodyLarge?.copyWith(
                              fontSize: DesignTokens.fontSizeMd,
                              height: DesignTokens.lineHeightRelaxed,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space4),
                    for (var i = 0; i < pregunta.opciones.length; i++) ...[
                      if (i > 0)
                        const SizedBox(height: DesignTokens.space2 + 2),
                      OptionCard(
                        opcion: pregunta.opciones[i],
                        letra: const ['A', 'B', 'C', 'D'][i],
                        visual:
                            (estado.seleccion ?? estado.respuesta?.optionId) ==
                                pregunta.opciones[i].id
                            ? OptionVisual.seleccionada
                            : OptionVisual.normal,
                        onTap: () =>
                            control.seleccionar(pregunta.opciones[i].id),
                      ),
                    ],
                  ],
                ),
              ),
              _BarraNavegacion(
                estado: estado,
                control: control,
                onEnviar: () => _confirmarEnvio(estado),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _marca(String? id, String? email) =>
      '${(id ?? "anon").split("-").first.toUpperCase()} · ${email ?? ""}';

  Future<void> _abrirGrilla(
    SessionState estado,
    SessionController control,
  ) async {
    final destino = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => _HojaGrilla(estado: estado),
    );
    if (destino != null) control.irA(destino);
  }

  Future<void> _confirmarAbandono() async {
    final tipo = ref
        .read(sessionControllerProvider(widget.sessionId))
        .value
        ?.session
        .tipo;

    final salir = await confirmar(
      context,
      titulo: tipo == SessionType.examenPasado
          ? '¿Salir del examen?'
          : '¿Salir del simulacro?',
      mensaje:
          'El cronómetro sigue corriendo. Si el tiempo se agota, el examen se '
          'envía con lo que hayas respondido.',
      confirmar: 'Salir',
      cancelar: 'Seguir rindiendo',
    );
    if (!salir || !mounted) return;

    // Un examen pasado no se empieza desde la pestaña de simulacros, así que
    // devolver ahí deja al usuario en un sitio por el que no pasó. Al inicio,
    // que es de donde salió.
    context.go(
      tipo == SessionType.examenPasado
          ? Routes.home
          : Routes.simulacroSelection,
    );
  }

  /// Pantalla 5.5 — confirmación de envío.
  Future<void> _confirmarEnvio(SessionState estado) async {
    final sinResponder = estado.session.sinResponder;
    final marcadas = estado.session.marcadas;

    final enviar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Enviar el examen?'),
        content: Text(
          sinResponder == 0
              ? 'Respondiste todas. Después de enviar no se puede cambiar nada.'
              : 'Te quedan $sinResponder sin responder'
                    '${marcadas > 0 ? " y $marcadas marcadas" : ""}. '
                    'Sin puntaje en contra, dejar en blanco vale 0: conviene '
                    'responder aunque no estés seguro.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Seguir rindiendo'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );

    if (enviar == true) await _enviar();
  }

  Future<void> _enviar({bool automatico = false}) async {
    final control = ref.read(
      sessionControllerProvider(widget.sessionId).notifier,
    );
    final finalizada = await control.enviar();

    if (!mounted) return;

    if (finalizada == null) {
      showErrorSnack(context, 'No pudimos enviar el examen. Reintenta.');
      _enviado = false;
      return;
    }

    if (automatico) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Se acabó el tiempo'),
          content: const Text(
            'Tu examen se envió automáticamente con lo que respondiste.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Ver resultados'),
            ),
          ],
        ),
      );
    }

    if (mounted) {
      context.pushReplacement(Routes.simulacroResultsOf(widget.sessionId));
    }
  }
}

class _Cabecera extends StatelessWidget {
  const _Cabecera({
    required this.estado,
    required this.restante,
    required this.onGrilla,
    required this.onSalir,
    required this.onMarcar,
  });

  final SessionState estado;
  final Duration restante;
  final VoidCallback onGrilla;
  final VoidCallback onSalir;
  final VoidCallback onMarcar;

  static const _urgente = Duration(minutes: 5);

  @override
  Widget build(BuildContext context) {
    final states = context.states;
    final urgente = restante <= _urgente && restante > Duration.zero;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space3,
        vertical: DesignTokens.space2,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Symbols.close),
            tooltip: 'Salir',
            onPressed: onSalir,
          ),
          // El cronómetro es el elemento más importante de la pantalla.
          AnimatedContainer(
            duration: Motion.duration(context, Motion.normal),
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.space3,
              vertical: DesignTokens.space1 + 2,
            ),
            decoration: BoxDecoration(
              color: urgente ? states.error.tint : context.scheme.surface,
              border: Border.all(
                color: urgente ? states.error.base : context.scheme.outline,
                width: urgente ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
            ),
            child: Row(
              children: [
                Icon(
                  Symbols.timer,
                  size: 17,
                  color: urgente
                      ? states.error.onTint
                      : context.scheme.onSurfaceVariant,
                ),
                const SizedBox(width: DesignTokens.space1 + 2),
                Text(
                  _formato(restante),
                  style: context.texts.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: urgente
                        ? states.error.onTint
                        : context.scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Text(
            '${estado.indice + 1}/${estado.session.totalPreguntas}',
            style: context.texts.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Pop(
            trigger: estado.marcada,
            child: IconButton(
              icon: Icon(
                Symbols.bookmark,
                fill: estado.marcada ? 1 : 0,
                color: estado.marcada
                    ? states.warning.onTint
                    : context.scheme.onSurfaceVariant,
              ),
              tooltip: estado.marcada ? 'Quitar marca' : 'Marcar para revisar',
              onPressed: onMarcar,
            ),
          ),
          IconButton(
            icon: const Icon(Symbols.grid_view),
            tooltip: 'Ver todas las preguntas',
            onPressed: onGrilla,
          ),
        ],
      ),
    );
  }

  static String _formato(Duration d) {
    final h = d.inHours;
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }
}

class _HojaGrilla extends StatelessWidget {
  const _HojaGrilla({required this.estado});

  final SessionState estado;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      builder: (context, controller) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space4),
        child: ListView(
          controller: controller,
          children: [
            Text(
              'Todas las preguntas',
              style: context.texts.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: DesignTokens.space3),
            ExamGridLegend(session: estado.session),
            ExamGrid(
              session: estado.session,
              indiceActual: estado.indice,
              onSeleccionar: (i) => Navigator.of(context).pop(i),
            ),
            const SizedBox(height: DesignTokens.space6),
          ],
        ),
      ),
    );
  }
}

class _BarraNavegacion extends StatelessWidget {
  const _BarraNavegacion({
    required this.estado,
    required this.control,
    required this.onEnviar,
  });

  final SessionState estado;
  final SessionController control;
  final VoidCallback onEnviar;

  @override
  Widget build(BuildContext context) {
    final haySeleccion = estado.seleccion != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.space5,
        DesignTokens.space3,
        DesignTokens.space5,
        DesignTokens.space5,
      ),
      decoration: BoxDecoration(
        color: context.scheme.surface,
        border: Border(top: BorderSide(color: context.scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          IconButton.outlined(
            icon: const Icon(Symbols.arrow_back),
            tooltip: 'Anterior',
            onPressed: estado.indice == 0 ? null : control.anterior,
          ),
          const SizedBox(width: DesignTokens.space2 + 2),
          Expanded(
            child: estado.esUltima
                ? EnamButton(
                    label: 'Enviar examen',
                    icon: Symbols.send,
                    loading: estado.enviando,
                    onPressed: haySeleccion
                        ? () async {
                            await control.responder();
                            onEnviar();
                          }
                        : onEnviar,
                  )
                : EnamButton(
                    // Responder y avanzar es un solo gesto: en un examen
                    // cronometrado, dos toques por pregunta son 360 toques.
                    label: haySeleccion ? 'Responder y seguir' : 'Saltar',
                    icon: Symbols.arrow_forward,
                    loading: estado.enviando,
                    onPressed: haySeleccion
                        ? control.responder
                        : control.siguiente,
                  ),
          ),
        ],
      ),
    );
  }
}
