import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/domain/blueprint.dart';
import '../../../core/domain/taxonomy.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/area_colors.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/state_colors.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/enam_button.dart';
import '../domain/session_models.dart';
import 'session_controller.dart';

/// Pantalla 5.6 — resultados del simulacro (RF-18, RN-01).
///
/// La nota es el elemento dominante. Aprobado y desaprobado se ven distintos,
/// pero **el desaprobado no castiga**: color de advertencia, no de error, y el
/// copy apunta a qué hacer, no a lo que pasó. Cerca del 43 % del público ya
/// desaprobó el examen real una vez.
class SimulacroResultsScreen extends ConsumerWidget {
  const SimulacroResultsScreen({required this.sessionId, super.key});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(sessionControllerProvider(sessionId));

    return Scaffold(
      body: estado.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(
          child: Text('No pudimos cargar los resultados.'),
        ),
        data: (s) => _Contenido(session: s.session),
      ),
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({required this.session});

  final StudySession session;

  double get _nota =>
      session.nota ??
      Blueprint.toVigesimal(session.correctas, total: session.totalPreguntas);

  bool get _aprueba => Blueprint.isPassing(_nota);

  Duration get _duracion =>
      (session.finalizadaEn ?? DateTime.now()).difference(session.iniciadaEn);

  /// Aciertos por área, para el desglose. La clasificación se revela recién
  /// aquí (RN-09), así que este cálculo solo es posible después del submit.
  Map<String, ({int correctas, int total})> get _porArea {
    final mapa = <String, ({int correctas, int total})>{};
    for (final pregunta in session.preguntas) {
      final area = pregunta.areaId;
      if (area == null) continue;
      final previo = mapa[area] ?? (correctas: 0, total: 0);
      final acerto = session.respuestas[pregunta.id]?.esCorrecta == true;
      mapa[area] = (
        correctas: previo.correctas + (acerto ? 1 : 0),
        total: previo.total + 1,
      );
    }
    return mapa;
  }

  @override
  Widget build(BuildContext context) {
    final states = context.states;
    final color = _aprueba ? states.success : states.warning;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          DesignTokens.space5,
          DesignTokens.space6,
          DesignTokens.space5,
          DesignTokens.space8,
        ),
        children: [
          FadeUp(
            child: Column(
              children: [
                Text(
                  'TU NOTA',
                  style: context.texts.bodySmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: context.scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: DesignTokens.space2),
                AnimatedNumber(
                  value: _nota,
                  style: context.texts.displaySmall?.copyWith(
                    fontSize: 56,
                    fontWeight: FontWeight.w800,
                    color: color.onTint,
                    height: 1,
                  ),
                ),
                const SizedBox(height: DesignTokens.space1),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.space3,
                    vertical: DesignTokens.space1 + 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.tint,
                    borderRadius: BorderRadius.circular(
                      DesignTokens.radiusFull,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _aprueba ? Symbols.check_circle : Symbols.trending_up,
                        size: 17,
                        fill: 1,
                        color: color.onTint,
                      ),
                      const SizedBox(width: DesignTokens.space1 + 2),
                      Text(
                        _aprueba
                            ? 'Aprobado'
                            // No "desaprobado": dice cuánto falta, que es
                            // accionable.
                            : 'Te faltan '
                                  '${(Blueprint.passingGrade - _nota).toStringAsFixed(2)} '
                                  'para aprobar',
                        style: context.texts.bodySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: color.onTint,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: DesignTokens.space3),
                Text(
                  '${session.correctas} de ${session.totalPreguntas} '
                  'correctas · ${_duracion.inMinutes} min',
                  style: context.texts.bodyMedium,
                ),
                Text(
                  'Se aprueba con '
                  '${Blueprint.passingGrade.toStringAsFixed(2)}',
                  style: context.texts.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.space6),
          FadeUp(index: 1, child: _Desglose(porArea: _porArea)),
          const SizedBox(height: DesignTokens.space6),
          FadeUp(
            index: 2,
            child: EnamButton(
              label: 'Revisar las ${session.totalPreguntas} preguntas',
              icon: Symbols.fact_check,
              onPressed: () =>
                  context.push(Routes.simulacroReviewOf(session.id)),
            ),
          ),
          const SizedBox(height: DesignTokens.space2 + 2),
          FadeUp(
            index: 3,
            child: EnamOutlinedButton(
              label: 'Ver mi progreso',
              height: 52,
              onPressed: () => context.go(Routes.stats),
            ),
          ),
          const SizedBox(height: DesignTokens.space2),
          FadeUp(
            index: 4,
            child: TextButton(
              onPressed: () => context.go(Routes.simulacroSelection),
              child: Text(
                'Volver a simulacros',
                style: TextStyle(color: context.scheme.onSurfaceVariant),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Desglose por área, con el peso del blueprint visible.
///
/// Sin el peso, un 40 % en Ética se ve igual de mal que un 40 % en Medicina, y
/// no lo es: una son 2 preguntas del examen y la otra 40.
class _Desglose extends StatelessWidget {
  const _Desglose({required this.porArea});

  final Map<String, ({int correctas, int total})> porArea;

  @override
  Widget build(BuildContext context) {
    if (porArea.isEmpty) return const SizedBox.shrink();

    // Ordenado por peso en el examen: lo que más importa, primero.
    final entradas = porArea.entries.toList()
      ..sort((a, b) {
        final pa = Taxonomy.byId(a.key)?.peso ?? 0;
        final pb = Taxonomy.byId(b.key)?.peso ?? 0;
        return pb.compareTo(pa);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'POR ÁREA',
          style: context.texts.bodySmall?.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: context.scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: DesignTokens.space3),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.space4),
            child: Column(
              children: [
                for (var i = 0; i < entradas.length; i++)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: i == entradas.length - 1
                          ? 0
                          : DesignTokens.space3 + 1,
                    ),
                    child: _FilaArea(
                      areaId: entradas[i].key,
                      correctas: entradas[i].value.correctas,
                      total: entradas[i].value.total,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FilaArea extends StatelessWidget {
  const _FilaArea({
    required this.areaId,
    required this.correctas,
    required this.total,
  });

  final String areaId;
  final int correctas;
  final int total;

  @override
  Widget build(BuildContext context) {
    final area = Taxonomy.byId(areaId);
    final color = AreaColors.of(areaId, Theme.of(context).brightness);
    final acierto = total == 0 ? 0.0 : correctas / total;
    final refuerza = acierto < 0.5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: DesignTokens.space2),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Text(
                area?.nombre ?? areaId,
                style: context.texts.bodySmall?.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '$correctas/$total',
              style: context.texts.bodySmall?.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: context.scheme.onSurface,
              ),
            ),
            if (refuerza) ...[
              const SizedBox(width: DesignTokens.space2),
              Text(
                'refuerza',
                style: context.texts.bodySmall?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: context.states.warning.onTint,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: DesignTokens.space1 + 2),
        AnimatedBar(value: acierto, color: color, height: 8),
      ],
    );
  }
}
