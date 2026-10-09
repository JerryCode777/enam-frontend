import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/domain/blueprint.dart';
import '../../../core/error/failure.dart';
import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/sonido/proveedor_sonidos.dart';
import '../../../core/sonido/sonidos.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/state_colors.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/enam_button.dart';
import '../../../shared/widgets/sonar_al_aparecer.dart';
import '../../../shared/widgets/state_banner.dart';
import '../domain/session_models.dart';
import 'session_controller.dart';

/// Pantalla 4.4 — resumen de la sesión de práctica.
///
/// Nota de tono: el titular califica la sesión **sin infantilizar y sin
/// castigar**. Nunca "¡Fallaste!". Cerca del 43 % del público ya desaprobó el
/// examen una vez; el resumen tiene que dejarlo con ganas de seguir, no
/// recordarle que va mal.
class SessionSummaryScreen extends ConsumerWidget {
  const SessionSummaryScreen({required this.sessionId, super.key});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(sessionControllerProvider(sessionId));

    return Scaffold(
      body: estado.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            const Center(child: Text('No pudimos cargar el resumen.')),
        // El sonido del resultado, una vez: bueno con 11 o más, malo si no.
        data: (s) => SonarAlAparecer(
          sonido: sonidoDeResultado(nota: _notaDe(s.session)),
          child: _Contenido(session: s.session),
        ),
      ),
    );
  }
}

/// La nota vigesimal de la sesión: la del servidor si la hay, calculada si no.
double _notaDe(StudySession s) =>
    s.nota ?? Blueprint.toVigesimal(s.correctas, total: s.totalPreguntas);

class _Contenido extends ConsumerStatefulWidget {
  const _Contenido({required this.session});

  final StudySession session;

  @override
  ConsumerState<_Contenido> createState() => _ContenidoState();
}

class _ContenidoState extends ConsumerState<_Contenido> {
  bool _repasando = false;

  StudySession get session => widget.session;

  int get _correctas => session.correctas;
  int get _total => session.totalPreguntas;

  /// Respondidas y mal. **No** incluye las que quedaron en blanco: antes las
  /// contaba dos veces —«Fallaste 8» y «Dejaste en blanco 3» con 2 correctas
  /// de 10— y el resumen no cuadraba.
  int get _falladas => session.respuestas.values
      .where((r) => r.optionId != null && r.esCorrecta == false)
      .length;
  int get _enBlanco => session.sinResponder;
  int get _marcadas => session.marcadas;

  double get _acierto => _total == 0 ? 0 : _correctas / _total;

  /// Tiempo dedicado a las preguntas, sumado pregunta a pregunta, y cuántas
  /// lo registraron (las dejadas en blanco también: leerlas llevó su tiempo).
  ///
  /// No es la diferencia entre el inicio y el fin de la sesión: una práctica
  /// que se deja a medias y se retoma al día siguiente daría «1 440 min». Sin
  /// tiempos registrados no se muestra nada, en vez de «0 s por pregunta».
  ({Duration total, int preguntas})? get _tiempo {
    final conTiempo = session.respuestas.values.where((r) => r.tiempoMs > 0);
    if (conTiempo.isEmpty) return null;
    final ms = conTiempo.fold(0, (t, r) => t + r.tiempoMs);
    return (total: Duration(milliseconds: ms), preguntas: conTiempo.length);
  }

  /// El titular. Cuatro tramos, ninguno culpabilizador.
  String get _titular => switch (_acierto) {
    >= 0.85 => 'Sesión excelente',
    >= 0.65 => 'Buena sesión',
    >= 0.45 => 'Sesión para revisar',
    // "Difícil" describe el material, no al usuario.
    _ => 'Sesión difícil',
  };

  /// Arranca una práctica con lo que se falló en **esta** sesión.
  ///
  /// Antes mandaba al configurador con el origen puesto, y ahí se perdían dos
  /// cosas: el nodo que se estaba practicando —así que "repasar las falladas
  /// de Cardiología" acababa ofreciendo todo el temario— y el propio gesto,
  /// porque el usuario ya había decidido qué quería y volvía a una pantalla de
  /// ajustes.
  ///
  /// El nodo no viaja en la sesión, pero sí en las preguntas: al terminar
  /// llegan con su área y su subtema, así que el ámbito sale de las falladas.
  Future<void> _repasarFalladas() async {
    if (_repasando) return;
    setState(() => _repasando = true);

    try {
      final falladas = session.respuestas.values
          .where((r) => r.esCorrecta == false)
          .map((r) => r.questionId)
          .toSet();

      final preguntas = session.preguntas
          .where((q) => falladas.contains(q.id))
          .toList();

      final subtemas = preguntas
          .map((q) => q.subtemaId)
          .nonNulls
          .toSet()
          .toList();
      final areas = preguntas.map((q) => q.areaId).nonNulls.toSet().toList();

      final sesion = await ref
          .read(sessionRepositoryProvider)
          .startPractice(
            PracticeConfig(
              // Con subtemas se acota a ellos; si no llegaron, al área. Sin
              // ninguno de los dos, el servidor busca entre todas las falladas
              // del usuario, que sigue siendo mejor que empezar de cero.
              areaIds: subtemas.isEmpty ? areas : const [],
              subtemaIds: subtemas,
              cantidadPreguntas: falladas.length.clamp(
                Blueprint.practiceMinQuestions,
                Blueprint.practiceMaxQuestions,
              ),
              origen: QuestionSource.falladas,
            ),
          );

      if (!mounted) return;
      ref.sonar(Sonido.empiezaQuiz);
      context.pushReplacement(Routes.practiceSessionOf(sesion.id));
    } on Failure catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _repasando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final states = context.states;
    final tiempo = _tiempo;

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.space5,
              DesignTokens.space6,
              DesignTokens.space5,
              DesignTokens.space6,
            ),
            children: [
              FadeUp(
                child: Column(
                  children: [
                    // Qué fue esto, antes que la cifra: una práctica corta no
                    // es un simulacro ni una nota del ENAM (plan §6).
                    Text(
                      'Resultado de tu práctica · $_total '
                      '${_total == 1 ? "pregunta" : "preguntas"}',
                      style: context.texts.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space4),
                    // Color de acción, no verde o ámbar de aprobado: comparar
                    // diez preguntas con el 11 del examen sería engañoso.
                    AnimatedRing(
                      value: _acierto,
                      size: 128,
                      stroke: 10,
                      color: scheme.primary,
                      child: Semantics(
                        label:
                            '$_correctas de $_total correctas, '
                            '${(_acierto * 100).round()} por ciento',
                        excludeSemantics: true,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: '$_correctas',
                                    style: context.texts.headlineLarge,
                                  ),
                                  TextSpan(
                                    text: ' / $_total',
                                    style: context.texts.titleMedium?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${(_acierto * 100).round()} % de acierto',
                              style: context.texts.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space4),
                    Semantics(
                      header: true,
                      child: Text(
                        _titular,
                        style: context.texts.headlineMedium,
                      ),
                    ),
                    if (tiempo != null) ...[
                      const SizedBox(height: DesignTokens.space1),
                      Text(
                        '${_minutos(tiempo.total)} en total · '
                        '${(tiempo.total.inSeconds / tiempo.preguntas).round()} s '
                        'por pregunta',
                        style: context.texts.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: DesignTokens.space5),
              FadeUp(
                index: 1,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: DesignTokens.space4,
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Cifra(
                            valor: _correctas,
                            etiqueta: _correctas == 1
                                ? 'correcta'
                                : 'correctas',
                            icono: Symbols.check_circle,
                            color: states.success.onTint,
                          ),
                          VerticalDivider(
                            width: 1,
                            color: scheme.outlineVariant,
                          ),
                          _Cifra(
                            valor: _falladas,
                            etiqueta: _falladas == 1
                                ? 'incorrecta'
                                : 'incorrectas',
                            icono: Symbols.cancel,
                            color: states.error.onTint,
                          ),
                          VerticalDivider(
                            width: 1,
                            color: scheme.outlineVariant,
                          ),
                          _Cifra(
                            valor: _enBlanco,
                            etiqueta: 'en blanco',
                            icono: Symbols.radio_button_unchecked,
                            color: scheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (_marcadas > 0) ...[
                const SizedBox(height: DesignTokens.space3),
                FadeUp(
                  index: 1,
                  child: Row(
                    children: [
                      Icon(
                        Symbols.bookmark,
                        size: 18,
                        fill: 1,
                        color: states.info.onTint,
                      ),
                      const SizedBox(width: DesignTokens.space2),
                      Expanded(
                        child: Text(
                          _marcadas == 1
                              ? 'Marcaste 1 pregunta para repasar.'
                              : 'Marcaste $_marcadas preguntas para repasar.',
                          style: context.texts.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: DesignTokens.space6),
              // Una sola acción principal, la que más rinde después de esta
              // sesión: repasar lo fallado si lo hay; si no, otra práctica.
              FadeUp(
                index: 2,
                child: _falladas > 0
                    ? EnamButton(
                        label: 'Repasar las $_falladas incorrectas',
                        icon: Symbols.replay,
                        loading: _repasando,
                        onPressed: _repasarFalladas,
                      )
                    : EnamButton(
                        label: 'Otra práctica',
                        icon: Symbols.arrow_forward,
                        onPressed: () =>
                            context.pushReplacement(Routes.practiceConfig),
                      ),
              ),
              const SizedBox(height: DesignTokens.space2 + 2),
              FadeUp(
                index: 3,
                child: EnamOutlinedButton(
                  label: 'Revisar pregunta por pregunta',
                  // `go`: la revisión cuelga de la pestaña de simulacros y este
                  // resumen vive fuera del contenedor.
                  onPressed: () =>
                      context.go(Routes.simulacroReviewOf(session.id)),
                ),
              ),
              const SizedBox(height: DesignTokens.space2),
              FadeUp(
                index: 3,
                child: TextButton(
                  onPressed: () => context.go(Routes.home),
                  child: const Text('Volver al inicio'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _minutos(Duration d) =>
      d.inMinutes < 1 ? 'menos de 1 min' : '${d.inMinutes} min';
}

/// Una de las tres cifras del desglose.
class _Cifra extends StatelessWidget {
  const _Cifra({
    required this.valor,
    required this.etiqueta,
    required this.icono,
    required this.color,
  });

  final int valor;
  final String etiqueta;
  final IconData icono;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        label: '$valor $etiqueta',
        excludeSemantics: true,
        child: Column(
          children: [
            Icon(icono, size: 20, fill: 1, color: color),
            const SizedBox(height: DesignTokens.space1),
            Text('$valor', style: context.texts.headlineMedium),
            Text(etiqueta, style: context.texts.bodyMedium),
          ],
        ),
      ),
    );
  }
}
