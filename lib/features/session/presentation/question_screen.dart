import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/motion.dart';
import '../../../core/theme/state_colors.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/enam_button.dart';
import '../../../shared/widgets/state_banner.dart';
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
/// - Enunciado a 16 px con interlineado 1.625 (el 81 % son casos clínicos)
/// - **Seleccionar no responde**: hace falta confirmar, porque leyendo un texto
///   largo es fácil tocar de más
/// - **No se muestra de qué área es** hasta responder (RN-09)
class QuestionScreen extends ConsumerWidget {
  const QuestionScreen({required this.sessionId, super.key});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(sessionControllerProvider(sessionId));

    return estado.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
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

class _Contenido extends ConsumerWidget {
  const _Contenido({required this.sessionId, required this.estado});

  final String sessionId;
  final SessionState estado;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.space5,
                  DesignTokens.space2,
                  DesignTokens.space5,
                  DesignTokens.space4,
                ),
                children: [
                  // La marca de agua solo envuelve el enunciado, que es lo que
                  // alguien capturaría (RNF-05).
                  Watermark(
                    texto: _idUsuario(usuario?.id, usuario?.email),
                    child: _TarjetaEnunciado(pregunta: pregunta),
                  ),
                  const SizedBox(height: DesignTokens.space4),
                  if (estado.respondida)
                    _PanelFeedback(estado: estado)
                  else
                    _Alternativas(estado: estado, onTap: control.seleccionar),
                ],
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
    final salir = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Salir de la práctica?'),
        // RF-15: hay que decirlo, o el usuario asume que pierde el avance.
        content: const Text(
          'Tu avance queda guardado. Puedes retomar esta sesión desde el inicio.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Seguir practicando'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    if (salir == true && context.mounted) context.pop();
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pregunta ${estado.indice + 1} de $total',
                      style: context.texts.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      estado.session.esSimulacro ? 'Simulacro' : 'Práctica libre',
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
            Text(
              pregunta.enunciado,
              style: context.texts.bodyLarge?.copyWith(
                fontSize: DesignTokens.fontSizeMd,
                height: DesignTokens.lineHeightRelaxed,
                letterSpacing: 0.1,
              ),
            ),
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
    final correcta = opciones
        .where((o) => o.esCorrecta == true)
        .firstOrNull;
    final acerto = correcta != null && elegida == correcta.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!acerto && elegida != null)
          FadeUp(
            child: Padding(
              padding: const EdgeInsets.only(bottom: DesignTokens.space2 + 2),
              child: OptionCard(
                opcion: opciones.firstWhere((o) => o.id == elegida),
                letra: _letra(opciones, elegida),
                visual: OptionVisual.incorrecta,
                onTap: null,
              ),
            ),
          ),
        if (correcta != null)
          FadeUp(
            index: acerto ? 0 : 1,
            child: OptionCard(
              opcion: correcta,
              letra: _letra(opciones, correcta.id),
              visual: OptionVisual.correcta,
              onTap: null,
            ),
          ),
        const SizedBox(height: DesignTokens.space3 + 2),
        FadeUp(index: 2, child: _Explicacion(estado: estado)),
      ],
    );
  }

  static String _letra(List<QuestionOption> opciones, String id) {
    final i = opciones.indexWhere((o) => o.id == id);
    return i >= 0 && i < _letras.length ? _letras[i] : '?';
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
                fontSize: 15,
                height: DesignTokens.lineHeightRelaxed,
              ),
            ),
            if (distractores.isNotEmpty) ...[
              const SizedBox(height: DesignTokens.space3),
              Divider(color: scheme.outlineVariant),
              const SizedBox(height: DesignTokens.space2),
              // Los distractores después de la clave: primero se aprende lo
              // correcto, después por qué lo demás no era.
              for (final d in distractores)
                Padding(
                  padding: const EdgeInsets.only(bottom: DesignTokens.space2),
                  child: Text(
                    '${d.texto}: ${d.explicacion}',
                    style: context.texts.bodySmall?.copyWith(height: 1.55),
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
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSm + 2),
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

class _MigasPregunta extends ConsumerWidget {
  const _MigasPregunta({required this.pregunta});

  final Question pregunta;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: DesignTokens.space1 + 2,
      runSpacing: DesignTokens.space1 + 2,
      children: [
        for (final texto in [pregunta.areaId!, ?pregunta.subtemaId])
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

class _BarraAccion extends StatelessWidget {
  const _BarraAccion({
    required this.sessionId,
    required this.estado,
    required this.control,
  });

  final String sessionId;
  final SessionState estado;
  final SessionController control;

  @override
  Widget build(BuildContext context) {
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
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _reportar(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 52),
                    ),
                    child: const Text('Reportar'),
                  ),
                ),
                const SizedBox(width: DesignTokens.space2 + 2),
                Expanded(
                  flex: 2,
                  child: EnamButton(
                    label: estado.esUltima ? 'Ver resultados' : 'Siguiente',
                    icon: estado.esUltima ? null : Symbols.arrow_forward,
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
              onPressed: estado.seleccion == null ? null : control.responder,
            ),
    );
  }

  /// Reportar una pregunta con posible clave errónea. Alimenta RN-06.
  Future<void> _reportar(BuildContext context) async {
    final motivo = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.space4,
                vertical: DesignTokens.space2,
              ),
              child: Text(
                '¿Qué pasa con esta pregunta?',
                style: context.texts.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            for (final motivo in const [
              'La clave me parece equivocada',
              'Hay un error en el texto',
              'La imagen no carga o no corresponde',
              'La explicación no se entiende',
            ])
              ListTile(
                title: Text(motivo),
                onTap: () => Navigator.of(context).pop(motivo),
              ),
            const SizedBox(height: DesignTokens.space2),
          ],
        ),
      ),
    );

    if (motivo != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gracias. Un editor va a revisarla.'),
        ),
      );
    }
  }
}
