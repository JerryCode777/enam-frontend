import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/domain/blueprint.dart';
import '../../../core/error/failure.dart';
import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/state_colors.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/enam_button.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../../shared/widgets/state_banner.dart';
import '../../subscription/presentation/access_ended_screen.dart';

/// Pantalla 5.2 — antes de empezar el simulacro.
///
/// Tiene una sola función: que nadie entre sin saber que **no se puede pausar**.
/// Un usuario que abandona a los 40 minutos pierde el intento, y eso hay que
/// decirlo antes, no después.
class SimulacroInstructionsScreen extends ConsumerStatefulWidget {
  const SimulacroInstructionsScreen({this.esMuestra = false, super.key});

  final bool esMuestra;

  @override
  ConsumerState<SimulacroInstructionsScreen> createState() =>
      _SimulacroInstructionsScreenState();
}

class _SimulacroInstructionsScreenState
    extends ConsumerState<SimulacroInstructionsScreen> {
  bool _creando = false;

  int get _preguntas => widget.esMuestra
      ? Blueprint.sampleExamQuestions
      : Blueprint.totalQuestions;

  Duration get _duracion => widget.esMuestra
      // La muestra mantiene el ritmo del examen real: 1 minuto por pregunta.
      ? const Duration(minutes: Blueprint.sampleExamQuestions)
      : Blueprint.examDuration;

  @override
  Widget build(BuildContext context) {
    final reglas = <({IconData icon, String titulo, String detalle})>[
      (
        icon: Symbols.quiz,
        titulo: '$_preguntas preguntas, 4 alternativas',
        detalle: 'Una sola correcta. Igual que el examen real.',
      ),
      (
        icon: Symbols.timer,
        titulo: _formatoDuracion,
        detalle:
            'El cronómetro corre aunque cierres la app. Al agotarse, se envía '
            'automáticamente.',
      ),
      (
        icon: Symbols.visibility_off,
        titulo: 'Sin retroalimentación durante el examen',
        detalle:
            'No verás si acertaste, ni de qué área es cada pregunta. Todo se '
            'revela al terminar.',
      ),
      (
        icon: Symbols.remove_circle_outline,
        titulo: 'Sin puntaje en contra',
        detalle:
            'Dejar en blanco vale lo mismo que fallar: 0. Conviene responder '
            'todo.',
      ),
      (
        icon: Symbols.grade,
        titulo: 'Nota vigesimal',
        detalle:
            'Se aprueba con ${Blueprint.passingGrade.toStringAsFixed(2)}. Al '
            'final ves el desglose por área.',
      ),
    ];

    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            titulo: widget.esMuestra
                ? 'Simulacro de muestra'
                : 'Antes de empezar',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.space5,
                DesignTokens.space4,
                DesignTokens.space5,
                DesignTokens.space8,
              ),
              children: [
                // Lo primero y más importante.
                FadeUp(
                  child: StateBanner(
                    kind: BannerKind.warning,
                    icon: Symbols.pause_circle,
                    message:
                        'Una vez que empieces no se puede pausar. Asegúrate de '
                        'tener ${_formatoDuracion.toLowerCase()} libres.',
                  ),
                ),
                const SizedBox(height: DesignTokens.space5),
                for (var i = 0; i < reglas.length; i++)
                  FadeUp(
                    index: i + 1,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        bottom: DesignTokens.space4,
                      ),
                      child: _Regla(regla: reglas[i]),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
              DesignTokens.space5,
              DesignTokens.space3,
              DesignTokens.space5,
              DesignTokens.space3 + MediaQuery.paddingOf(context).bottom,
            ),
            decoration: BoxDecoration(
              color: context.scheme.surface,
              border: Border(
                top: BorderSide(color: context.scheme.outlineVariant),
              ),
            ),
            child: EnamButton(
              label: 'Empezar el simulacro',
              icon: Symbols.play_arrow,
              loading: _creando,
              onPressed: _empezar,
            ),
          ),
        ],
      ),
    );
  }

  String get _formatoDuracion {
    final h = _duracion.inHours;
    final m = _duracion.inMinutes % 60;
    if (h == 0) return '$m minutos';
    return m == 0 ? '$h ${h == 1 ? "hora" : "horas"}' : '$h h $m min';
  }

  Future<void> _empezar() async {
    if (_creando) return;
    setState(() => _creando = true);

    try {
      final session = await ref
          .read(sessionRepositoryProvider)
          .startSimulacro(esMuestra: widget.esMuestra);

      // D-02: el reloj de las 24 h arranca aquí también.
      await ref.read(inicioPruebaProvider.notifier).arrancar();
      if (mounted) {
        context.pushReplacement(Routes.simulacroSessionOf(session.id));
      }
    } on ForbiddenFailure catch (e) {
      // Empezar un simulacro también arranca el reloj de la prueba (D-02), así
      // que este 403 puede ser la prueba venciendo justo aquí.
      if (!mounted) return;
      if (e.requiereSuscripcion) {
        irAlPago(ref, context);
      } else {
        showErrorSnack(context, e.message);
      }
    } on Failure catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _creando = false);
    }
  }
}

class _Regla extends StatelessWidget {
  const _Regla({required this.regla});

  final ({IconData icon, String titulo, String detalle}) regla;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(DesignTokens.space2 + 1),
          decoration: BoxDecoration(
            color: context.states.info.tint,
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          ),
          child: Icon(regla.icon, size: 20, color: context.states.info.onTint),
        ),
        const SizedBox(width: DesignTokens.space3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                regla.titulo,
                style: context.texts.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                regla.detalle,
                style: context.texts.bodySmall?.copyWith(height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
