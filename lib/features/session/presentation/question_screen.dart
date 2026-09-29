import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/config/contacto.dart';
import '../../../core/error/failure.dart';
import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/motion.dart';
import '../../../core/theme/state_colors.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/enam_button.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/state_banner.dart';
import '../../catalog/presentation/catalog_providers.dart';
import '../domain/session_models.dart';
import 'session_controller.dart';
import 'widgets/option_card.dart';
import 'widgets/watermark.dart';

/// Pantallas 4.2 y 4.3 — pregunta en práctica y su retroalimentación.
///
/// Son la misma pantalla en dos momentos, no dos pantallas: el enunciado se
/// queda arriba y debajo cambian las alternativas por el panel de explicación.
/// Separarlas obligaría a volver a pintar el enunciado y perdería el hilo de
/// lectura.
///
/// Decisiones que sostienen la legibilidad, que es la tarea principal:
/// - Enunciado a 17 px con interlineado 1,6 (el 81 % son casos clínicos), en
///   una columna de 720 px como máximo para que en tableta no se lean renglones
///   de lado a lado
/// - **Seleccionar no responde**: hace falta confirmar, porque leyendo un texto
///   largo es fácil tocar de más
/// - **No se muestra de qué área es** hasta responder (RN-09)
/// - Al responder, la pantalla baja sola hasta el veredicto: el enunciado de
///   un caso clínico ocupa la pantalla entera, y sin esto lo primero que se
///   veía tras confirmar era otra vez el caso, con la respuesta fuera de vista
class QuestionScreen extends ConsumerWidget {
  const QuestionScreen({required this.sessionId, super.key});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(sessionControllerProvider(sessionId));

    return estado.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.space4),
            child: StateBanner(
              kind: BannerKind.error,
              message: 'No pudimos cargar la sesión.',
              action: TextButton(
                onPressed: () =>
                    ref.invalidate(sessionControllerProvider(sessionId)),
                child: const Text('Reintentar'),
              ),
            ),
          ),
        ),
      ),
      data: (s) => _Contenido(sessionId: sessionId, estado: s),
    );
  }
}

class _Contenido extends ConsumerStatefulWidget {
  const _Contenido({required this.sessionId, required this.estado});

  final String sessionId;
  final SessionState estado;

  @override
  ConsumerState<_Contenido> createState() => _ContenidoState();
}

class _ContenidoState extends ConsumerState<_Contenido> {
  final _scroll = ScrollController();

  /// El panel de la respuesta, para bajar hasta él al confirmar.
  final _claveFeedback = GlobalKey();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_Contenido anterior) {
    super.didUpdateWidget(anterior);
    final antes = anterior.estado;
    final ahora = widget.estado;

    // Pregunta nueva: se empieza a leer desde arriba.
    if (antes.indice != ahora.indice && _scroll.hasClients) {
      _scroll.jumpTo(0);
    }

    // Recién respondida: el veredicto y el porqué, a la vista.
    if (!antes.respondida && ahora.respondida) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final destino = _claveFeedback.currentContext;
        if (destino == null || !mounted) return;
        Scrollable.ensureVisible(
          destino,
          duration: Motion.duration(context, Motion.normal),
          curve: Motion.enter,
          // Arriba del todo, con el margen del propio panel: el final del
          // enunciado queda justo encima y se puede volver a él.
          alignment: 0,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionId = widget.sessionId;
    final estado = widget.estado;
    final control = ref.read(sessionControllerProvider(sessionId).notifier);
    final usuario = ref.watch(currentUserProvider);
    final pregunta = estado.pregunta;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Cabecera(
              estado: estado,
              onCerrar: () => _confirmarSalida(context),
              onMarcar: control.alternarMarca,
            ),
            if (estado.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.space5,
                  vertical: DesignTokens.space2,
                ),
                child: StateBanner(
                  kind: BannerKind.error,
                  message: estado.error!.message,
                ),
              ),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  // Columna de lectura (plan §6): 680–760 px.
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: ListView(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(
                      DesignTokens.space4,
                      DesignTokens.space2,
                      DesignTokens.space4,
                      DesignTokens.space6,
                    ),
                    children: [
                      // La marca de agua solo envuelve el enunciado, que es lo
                      // que alguien capturaría (RNF-05).
                      Watermark(
                        texto: _idUsuario(usuario?.id, usuario?.email),
                        child: _TarjetaEnunciado(pregunta: pregunta),
                      ),
                      const SizedBox(height: DesignTokens.space4),
                      if (estado.respondida)
                        KeyedSubtree(
                          key: _claveFeedback,
                          // El margen va dentro de la clave: al bajar hasta
                          // aquí, el veredicto no queda pegado al borde.
                          child: Padding(
                            padding: const EdgeInsets.only(
                              top: DesignTokens.space3,
                            ),
                            child: _PanelFeedback(estado: estado),
                          ),
                        )
                      else
                        _Alternativas(
                          estado: estado,
                          onTap: control.seleccionar,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            _BarraAccion(
              sessionId: sessionId,
              estado: estado,
              control: control,
            ),
          ],
        ),
      ),
    );
  }

  /// Identificador visible en la marca de agua. Se usa el correo además del id
  /// porque un uuid no dice nada a quien recibe la captura filtrada.
  static String _idUsuario(String? id, String? email) {
    final corto = (id ?? 'anon').split('-').first.toUpperCase();
    return '$corto · ${email ?? ""}';
  }

  Future<void> _confirmarSalida(BuildContext context) async {
    final salir = await confirmar(
      context,
      titulo: '¿Salir de la práctica?',
      // RF-15: hay que decirlo, o el usuario asume que pierde el avance.
      mensaje:
          'Tu avance queda guardado. Puedes retomar esta sesión desde el '
          'inicio.',
      confirmar: 'Salir',
      cancelar: 'Seguir practicando',
    );
    if (salir && context.mounted) context.pop();
  }
}

class _Cabecera extends StatelessWidget {
  const _Cabecera({
    required this.estado,
    required this.onCerrar,
    required this.onMarcar,
  });

  final SessionState estado;
  final VoidCallback onCerrar;
  final VoidCallback onMarcar;

  @override
  Widget build(BuildContext context) {
    final total = estado.session.preguntas.length;

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
            onPressed: onCerrar,
          ),
          Expanded(
            child: Column(
              children: [
                // Flexibles: con la letra del sistema ampliada, los dos
                // rótulos no caben enteros y se recortan en vez de desbordar.
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Pregunta ${estado.indice + 1} de $total',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.texts.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: DesignTokens.space2),
                    // Corto y fijo: el que cede espacio es el de la izquierda.
                    Text(
                      estado.session.esSimulacro
                          ? 'Simulacro'
                          : 'Práctica libre',
                      maxLines: 1,
                      style: context.texts.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DesignTokens.space1),
                AnimatedBar(
                  value: estado.progreso,
                  color: context.scheme.primary,
                  height: 4,
                  duration: Motion.fast,
                ),
              ],
            ),
          ),
          Pop(
            trigger: estado.marcada,
            child: IconButton(
              icon: Icon(
                Symbols.bookmark,
                fill: estado.marcada ? 1 : 0,
                color: estado.marcada
                    ? context.states.info.onTint
                    : context.scheme.onSurfaceVariant,
              ),
              tooltip: estado.marcada ? 'Quitar marca' : 'Marcar para repaso',
              onPressed: onMarcar,
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaEnunciado extends StatelessWidget {
  const _TarjetaEnunciado({required this.pregunta});

  final Question pregunta;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space4 + 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // La decisión tipográfica más importante de la app: se lee cansado y
            // son varios párrafos.
            Text(pregunta.enunciado, style: AppTheme.clinicalCase(context)),
            if (pregunta.imagenes.isNotEmpty) ...[
              const SizedBox(height: DesignTokens.space3 + 2),
              _AdjuntoImagen(url: pregunta.imagenes.first),
            ],
          ],
        ),
      ),
    );
  }
}

class _AdjuntoImagen extends StatelessWidget {
  const _AdjuntoImagen({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;

    return InkWell(
      onTap: () => showDialog<void>(
        context: context,
        builder: (context) => _VisorImagen(url: url),
      ),
      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.space2 + 2),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
              ),
              child: Icon(
                Symbols.imagesmode,
                size: 22,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: DesignTokens.space2 + 2),
            Expanded(
              child: Text(
                'Imagen adjunta · toca para ampliar',
                style: context.texts.bodySmall,
              ),
            ),
            Icon(
              Symbols.open_in_full,
              size: 20,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// Visor a pantalla completa con zoom. Radiografías y EKG no se leen en miniatura.
class _VisorImagen extends StatelessWidget {
  const _VisorImagen({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          InteractiveViewer(
            maxScale: 5,
            child: Center(
              child: Icon(
                Symbols.imagesmode,
                size: 96,
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Symbols.close, color: Colors.white),
                tooltip: 'Cerrar',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Alternativas extends StatelessWidget {
  const _Alternativas({required this.estado, required this.onTap});

  final SessionState estado;
  final ValueChanged<String> onTap;

  static const _letras = ['A', 'B', 'C', 'D'];

  @override
  Widget build(BuildContext context) {
    final opciones = estado.pregunta.opciones;

    return Column(
      children: [
        for (var i = 0; i < opciones.length; i++) ...[
          if (i > 0) const SizedBox(height: DesignTokens.space2 + 2),
          OptionCard(
            opcion: opciones[i],
            letra: i < _letras.length ? _letras[i] : '${i + 1}',
            visual: estado.seleccion == opciones[i].id
                ? OptionVisual.seleccionada
                : OptionVisual.normal,
            onTap: () => onTap(opciones[i].id),
          ),
        ],
      ],
    );
  }
}

/// Panel de retroalimentación (RF-13). El momento de aprendizaje de la app.
class _PanelFeedback extends StatelessWidget {
  const _PanelFeedback({required this.estado});

  final SessionState estado;

  static const _letras = ['A', 'B', 'C', 'D'];

  @override
  Widget build(BuildContext context) {
    final pregunta = estado.pregunta;
    final elegida = estado.respuesta?.optionId;
    final opciones = pregunta.opciones;

    // Se muestran solo la correcta y la elegida, en ese orden. Repetir las cuatro
    // obliga a buscar cuál era cuál.
    //
    // Si el servidor todavía no reveló la clave, `correcta` queda en null y no
    // se pinta ninguna en verde. Antes se caía a la primera alternativa, que
    // señalaba como correcta una respuesta cualquiera —enseñando medicina
    // equivocada con toda la confianza del mundo— en vez de no decir nada.
    final correcta = opciones.where((o) => o.esCorrecta == true).firstOrNull;
    final acerto = correcta != null && elegida == correcta.id;

    // Primero el veredicto y la correcta, después la tuya si falló, y después
    // el porqué (plan §6: respuesta y motivo primero, distractores después).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (correcta != null)
          FadeUp(
            child: _Veredicto(
              acerto: acerto,
              enBlanco: elegida == null,
              letraCorrecta: _letra(opciones, correcta.id),
            ),
          ),
        const SizedBox(height: DesignTokens.space3),
        if (correcta != null)
          FadeUp(
            index: 1,
            child: OptionCard(
              opcion: correcta,
              letra: _letra(opciones, correcta.id),
              visual: OptionVisual.correcta,
              onTap: null,
            ),
          ),
        if (!acerto && elegida != null)
          FadeUp(
            index: 1,
            child: Padding(
              padding: const EdgeInsets.only(top: DesignTokens.space2 + 2),
              child: OptionCard(
                opcion: opciones.firstWhere((o) => o.id == elegida),
                letra: _letra(opciones, elegida),
                visual: OptionVisual.incorrecta,
                onTap: null,
              ),
            ),
          ),
        const SizedBox(height: DesignTokens.space4),
        FadeUp(index: 2, child: _Explicacion(estado: estado)),
      ],
    );
  }

  static String _letra(List<QuestionOption> opciones, String id) {
    final i = opciones.indexWhere((o) => o.id == id);
    return i >= 0 && i < _letras.length ? _letras[i] : '?';
  }
}

/// El resultado de la pregunta, dicho con palabras, icono y color a la vez.
class _Veredicto extends StatelessWidget {
  const _Veredicto({
    required this.acerto,
    required this.enBlanco,
    required this.letraCorrecta,
  });

  final bool acerto;
  final bool enBlanco;
  final String letraCorrecta;

  @override
  Widget build(BuildContext context) {
    final c = acerto ? context.states.success : context.states.error;
    final titulo = acerto
        ? 'Correcto'
        : enBlanco
        ? 'Sin responder'
        : 'Incorrecto';
    final detalle = acerto
        ? 'Elegiste la $letraCorrecta.'
        : 'La correcta es la $letraCorrecta.';

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space4,
          vertical: DesignTokens.space3,
        ),
        decoration: BoxDecoration(
          color: c.tint,
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        ),
        child: Row(
          children: [
            Icon(
              acerto ? Symbols.check_circle : Symbols.cancel,
              size: 26,
              fill: 1,
              color: c.onTint,
            ),
            const SizedBox(width: DesignTokens.space3),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$titulo. ',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    TextSpan(text: detalle),
                  ],
                ),
                style: context.texts.bodyLarge?.copyWith(color: c.onTint),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Explicacion extends StatelessWidget {
  const _Explicacion({required this.estado});

  final SessionState estado;

  @override
  Widget build(BuildContext context) {
    final pregunta = estado.pregunta;
    final states = context.states;
    final scheme = context.scheme;
    final global = pregunta.porcentajeAciertoGlobal;

    final distractores = pregunta.opciones
        .where((o) => o.esCorrecta != true && o.explicacion != null)
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // La clasificación se revela recién aquí (RN-09).
            if (pregunta.areaId != null) ...[
              _MigasPregunta(pregunta: pregunta),
              const SizedBox(height: DesignTokens.space3),
            ],
            Row(
              children: [
                Icon(Symbols.school, size: 18, color: states.success.onTint),
                const SizedBox(width: DesignTokens.space1 + 2),
                Expanded(
                  child: Text(
                    'Por qué es esta',
                    style: context.texts.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: states.success.onTint,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.space2 + 2),
            Text(
              pregunta.explicacion ?? 'Sin explicación disponible.',
              style: context.texts.bodyLarge?.copyWith(
                height: DesignTokens.lineHeightRelaxed,
              ),
            ),
            if (distractores.isNotEmpty) ...[
              const SizedBox(height: DesignTokens.space4),
              Divider(color: scheme.outlineVariant),
              const SizedBox(height: DesignTokens.space3),
              // Los distractores después de la clave: primero se aprende lo
              // correcto, después por qué lo demás no era. A 16 y con la letra
              // delante: antes iban a 12, pegados al texto de la alternativa, y
              // no se distinguía dónde acababa una y empezaba el motivo.
              Text(
                'Por qué no las demás',
                style: context.texts.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: DesignTokens.space2),
              for (final d in distractores)
                Padding(
                  padding: const EdgeInsets.only(bottom: DesignTokens.space3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        child: Text(
                          _letraDe(pregunta.opciones, d.id),
                          style: context.texts.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${d.texto}. ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(text: d.explicacion),
                            ],
                          ),
                          style: context.texts.bodyLarge?.copyWith(
                            height: 1.5,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            if (global != null) ...[
              const SizedBox(height: DesignTokens.space2),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.space3,
                  vertical: DesignTokens.space2,
                ),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(
                    DesignTokens.radiusSm + 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Symbols.group,
                      size: 16,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: DesignTokens.space2),
                    Expanded(
                      child: Text(
                        'El ${(global * 100).round()} % respondió bien esta '
                        'pregunta',
                        style: context.texts.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _letraDe(List<QuestionOption> opciones, String id) {
  const letras = ['A', 'B', 'C', 'D'];
  final i = opciones.indexWhere((o) => o.id == id);
  return i >= 0 && i < letras.length ? letras[i] : '·';
}

class _MigasPregunta extends ConsumerWidget {
  const _MigasPregunta({required this.pregunta});

  final Question pregunta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: DesignTokens.space1 + 2,
      runSpacing: DesignTokens.space1 + 2,
      children: [
        // El nombre del temario, no el identificador: «medicina-infecciosos»
        // es una clave interna. Sin catálogo cargado se cae al id, que al
        // menos dice algo.
        for (final texto in [
          ref.watch(nodoProvider(pregunta.areaId!))?.nodo.nombre ??
              pregunta.areaId!,
          if (pregunta.subtemaId case final sub?)
            ref.watch(nodoProvider(sub))?.nodo.nombre ?? sub,
        ])
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.space2 + 1,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color: context.scheme.surfaceContainerHighest,
              border: Border.all(color: context.scheme.outlineVariant),
              borderRadius: BorderRadius.circular(DesignTokens.radiusSm + 1),
            ),
            child: Text(
              texto,
              style: context.texts.bodySmall?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _BarraAccion extends ConsumerWidget {
  const _BarraAccion({
    required this.sessionId,
    required this.estado,
    required this.control,
  });

  final String sessionId;
  final SessionState estado;
  final SessionController control;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      child: estado.respondida
          ? Row(
              children: [
                // Reportar es una acción secundaria y se ve así: con borde,
                // icono y a un lado. Marcar para repaso vive arriba, en la
                // cabecera; siguiente, en el botón principal. Tres acciones que
                // no se pueden confundir (plan §6).
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: () => _reportar(context, ref),
                    icon: const Icon(Symbols.flag, size: 18),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 56),
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.space3,
                      ),
                    ),
                    label: const Text(
                      'Reportar',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: DesignTokens.space2 + 2),
                Expanded(
                  flex: 3,
                  child: EnamButton(
                    label: estado.esUltima ? 'Ver resultados' : 'Siguiente',
                    icon: estado.esUltima ? null : Symbols.arrow_forward,
                    loading: estado.esUltima && estado.enviando,
                    onPressed: () async {
                      if (estado.esUltima) {
                        await control.enviar();
                        if (context.mounted) {
                          context.go(Routes.practiceResultsOf(sessionId));
                        }
                      } else {
                        control.siguiente();
                      }
                    },
                  ),
                ),
              ],
            )
          : EnamButton(
              label: 'Responder',
              loading: estado.enviando,
              // Sin selección queda deshabilitado: seleccionar y confirmar son
              // pasos distintos a propósito.
              onPressed: estado.seleccion == null
                  ? null
                  : () {
                      // Una vibración corta, solo en la confirmación explícita
                      // (plan §7). Seleccionar no vibra: es un paso reversible.
                      HapticFeedback.lightImpact();
                      control.responder();
                    },
            ),
    );
  }

  /// Motivos de reporte, con el código que usará el endpoint cuando exista.
  static const motivos = <(String codigo, String texto)>[
    ('clave', 'La clave me parece equivocada'),
    ('texto', 'Hay un error en el texto'),
    ('imagen', 'La imagen no carga o no corresponde'),
    ('explicacion', 'La explicación no se entiende'),
  ];

  /// Reportar una pregunta con posible clave errónea (RN-06).
  ///
  /// Va a `POST /questions/{id}/reports`. Si el servidor todavía no tiene el
  /// endpoint (responde 404) o no se puede llegar a él, el reporte cae al
  /// WhatsApp de soporte con el código de la pregunta y el motivo ya escritos:
  /// así funciona igual antes y después de desplegar el backend, y ningún
  /// reporte se pierde en silencio.
  ///
  /// Hubo un tiempo en que esto enseñaba «Gracias. Un editor va a revisarla.»
  /// sin mandar nada a nadie. Lo que se dice ahora es lo que pasó: «Reporte
  /// enviado» solo si el servidor respondió que lo recibió.
  Future<void> _reportar(BuildContext context, WidgetRef ref) async {
    final motivo = await showModalBottomSheet<(String, String)>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.space4,
                0,
                DesignTokens.space4,
                DesignTokens.space1,
              ),
              child: Text(
                '¿Qué pasa con esta pregunta?',
                style: context.texts.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.space4,
                0,
                DesignTokens.space4,
                DesignTokens.space2,
              ),
              child: Text(
                'Lo enviamos a soporte con el código de la pregunta.',
                style: context.texts.bodyMedium,
              ),
            ),
            for (final m in motivos)
              ListTile(
                title: Text(m.$2),
                trailing: const Icon(Symbols.chevron_right),
                onTap: () => Navigator.of(context).pop(m),
              ),
            const SizedBox(height: DesignTokens.space2),
          ],
        ),
      ),
    );

    if (motivo == null || !context.mounted) return;

    try {
      await ref
          .read(reportesRepositoryProvider)
          .reportar(
            preguntaId: estado.pregunta.id,
            motivo: motivo.$1,
            sessionId: sessionId,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('Reporte enviado. Gracias por avisar.')),
        );
      return;
    } on RateLimitFailure catch (e) {
      // Varios seguidos: no es un fallo del canal, es esperar. Mandarlo por
      // WhatsApp saltaría el límite que puso el servidor.
      if (context.mounted) showErrorSnack(context, e.message);
      return;
    } on Failure {
      // Backend sin el endpoint, sin red, caído: se sigue por WhatsApp.
    }

    if (!context.mounted) return;
    await _reportarPorWhatsApp(context, motivo.$2);
  }

  /// El canal de respaldo: WhatsApp de soporte con el reporte escrito.
  Future<void> _reportarPorWhatsApp(BuildContext context, String motivo) async {
    final enlace = Contacto.soporte(
      mensaje:
          'Reporte de pregunta ${estado.pregunta.id}: $motivo. '
          '(Sesión $sessionId)',
    );
    final abierto = await Contacto.abrir(enlace);

    if (!abierto && context.mounted) {
      showErrorSnack(
        context,
        'No pudimos enviar el reporte. Escríbenos a '
        '${Contacto.soporteVisible} con el código ${estado.pregunta.id}.',
      );
    }
  }
}
