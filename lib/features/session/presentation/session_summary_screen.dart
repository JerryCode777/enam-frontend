import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/domain/blueprint.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/state_colors.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/enam_button.dart';
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
        error: (e, _) => const Center(
          child: Text('No pudimos cargar el resumen.'),
        ),
        data: (s) => _Contenido(session: s.session),
      ),
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({required this.session});

  final StudySession session;

  int get _correctas => session.correctas;
  int get _total => session.totalPreguntas;
  int get _falladas => session.respuestas.values
      .where((r) => r.esCorrecta == false)
      .length;
  int get _marcadas => session.marcadas;

  double get _acierto => _total == 0 ? 0 : _correctas / _total;

  Duration get _duracion {
    final fin = session.finalizadaEn ?? DateTime.now();
    return fin.difference(session.iniciadaEn);
  }

  /// El titular. Cuatro tramos, ninguno culpabilizador.
  String get _titular => switch (_acierto) {
    >= 0.85 => 'Sesión excelente',
    >= 0.65 => 'Buena sesión',
    >= 0.45 => 'Sesión para revisar',
    // "Difícil" describe el material, no al usuario.
    _ => 'Sesión difícil',
  };

  @override
  Widget build(BuildContext context) {
    final states = context.states;
    final aprobaria = Blueprint.isPassing(
      Blueprint.toVigesimal(_correctas, total: _total),
    );

    return SafeArea(
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
                AnimatedRing(
                  value: _acierto,
                  size: 120,
                  stroke: 10,
                  color: aprobaria ? states.success.base : states.warning.base,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          AnimatedNumber(
                            value: _correctas.toDouble(),
                            decimals: 0,
                            style: context.texts.headlineLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '/$_total',
                            style: context.texts.titleMedium?.copyWith(
                              color: context.scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${(_acierto * 100).round()} %',
                        style: context.texts.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: DesignTokens.space3),
                Text(
                  _titular,
                  style: context.texts.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: DesignTokens.space1),
                Text(
                  '${_duracion.inMinutes} min · '
                  '${_total == 0 ? 0 : (_duracion.inSeconds / _total).round()} s '
                  'por pregunta',
                  style: context.texts.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.space5),
          FadeUp(
            index: 1,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(DesignTokens.space4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'PARA VOLVER',
                      style: context.texts.bodySmall?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: context.scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space2 + 2),
                    _Fila(
                      etiqueta: 'Fallaste',
                      valor: '$_falladas '
                          '${_falladas == 1 ? "pregunta" : "preguntas"}',
                    ),
                    _Fila(
                      etiqueta: 'Marcaste para repaso',
                      valor: '$_marcadas '
                          '${_marcadas == 1 ? "pregunta" : "preguntas"}',
                    ),
                    _Fila(
                      etiqueta: 'Dejaste en blanco',
                      valor: '${_total - session.respondidas}',
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.space5),
          if (_falladas > 0)
            FadeUp(
              index: 2,
              child: EnamButton(
                label: 'Repasar las $_falladas falladas',
                icon: Symbols.replay,
                onPressed: () => context.pushReplacement(
                  '${Routes.practiceConfig}?origen=falladas',
                ),
              ),
            ),
          const SizedBox(height: DesignTokens.space2 + 2),
          FadeUp(
            index: 3,
            child: EnamOutlinedButton(
              label: 'Revisar pregunta por pregunta',
              height: 52,
              onPressed: () => context.push(
                Routes.simulacroReviewOf(session.id),
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.space2),
          FadeUp(
            index: 4,
            child: TextButton(
              onPressed: () => context.go(Routes.temario),
              child: Text(
                'Volver al temario',
                style: TextStyle(color: context.scheme.onSurfaceVariant),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.space2),
      child: Row(
        children: [
          Expanded(child: Text(etiqueta, style: context.texts.bodyMedium)),
          Text(
            valor,
            style: context.texts.bodyMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: context.scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
