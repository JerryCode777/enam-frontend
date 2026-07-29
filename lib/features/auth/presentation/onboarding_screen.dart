import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/state_colors.dart';
import '../../../shared/widgets/enam_button.dart';

/// Pantalla 1.2 — onboarding de 3 pasos.
///
/// Se muestra una sola vez. "Saltar" va directo al login.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _steps = <_Step>[
    _Step(
      titulo: 'Simulacros fieles al examen real',
      cuerpo:
          '180 preguntas en 3 horas, con la proporción exacta de la Tabla de '
          'Especificaciones. Calificación vigesimal y sin puntaje en contra, '
          'igual que el día del examen.',
      icons: [Symbols.timer, Symbols.assignment, Symbols.grading],
      etiqueta: 'SIMULACRO OFICIAL',
    ),
    _Step(
      titulo: 'Estudia sobre el temario oficial, no sobre una bolsa de preguntas',
      cuerpo:
          'Las 10 áreas, 58 sub áreas y 343 temas de la Tabla de '
          'Especificaciones de ASPEFAM, con tu avance encima. El mismo documento '
          'del que se construye el examen.',
      icons: [Symbols.stethoscope, Symbols.ecg_heart, Symbols.pediatrics],
      etiqueta: 'TEMARIO OFICIAL',
    ),
    _Step(
      titulo: 'Estudia sin conexión',
      cuerpo:
          'Descarga las áreas que estás trabajando y practica en el hospital, '
          'en el bus o donde no llegue la señal. Tus respuestas se sincronizan '
          'al reconectar.',
      icons: [Symbols.cloud_download, Symbols.wifi_off, Symbols.sync],
      etiqueta: 'MODO OFFLINE',
    ),
  ];

  bool get _isLast => _page == _steps.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_isLast) {
      context.go(Routes.register);
    } else {
      _controller.nextPage(
        duration: DesignTokens.durationNormal,
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.space2,
                  vertical: DesignTokens.space2,
                ),
                child: TextButton(
                  onPressed: () => context.go(Routes.login),
                  child: Text(
                    'Saltar',
                    style: context.texts.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _steps.length,
                itemBuilder: (context, i) => _StepView(step: _steps[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.space6 + 4,
                DesignTokens.space5,
                DesignTokens.space6 + 4,
                DesignTokens.space8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _Dots(count: _steps.length, active: _page),
                  EnamButton(
                    label: _isLast ? 'Crear cuenta' : 'Siguiente',
                    icon: _isLast ? null : Symbols.arrow_forward,
                    onPressed: _next,
                    expanded: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step {
  const _Step({
    required this.titulo,
    required this.cuerpo,
    required this.icons,
    required this.etiqueta,
  });

  final String titulo;
  final String cuerpo;
  final List<IconData> icons;
  final String etiqueta;
}

class _StepView extends StatelessWidget {
  const _StepView({required this.step});

  final _Step step;

  @override
  Widget build(BuildContext context) {
    final states = context.states;

    // Desplazable a propósito: con la fuente del sistema al máximo, un título de
    // tres líneas más el cuerpo no entran en 360 × 640.
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space6 + 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 230,
            decoration: BoxDecoration(
              color: states.info.tint,
              borderRadius: BorderRadius.circular(DesignTokens.radiusXl - 4),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < step.icons.length; i++) ...[
                      if (i > 0) const SizedBox(width: DesignTokens.space5),
                      Icon(
                        step.icons[i],
                        size: i == 1 ? 48 : 40,
                        fill: i == 1 ? 1 : 0,
                        color: states.info.onTint,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: DesignTokens.space2 + 2),
                Text(
                  step.etiqueta,
                  style: context.texts.bodySmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.66,
                    color: states.info.onTint.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.space6),
          Text(
            step.titulo,
            style: context.texts.headlineMedium?.copyWith(
              fontSize: DesignTokens.fontSize2xl + 2,
              fontWeight: FontWeight.w800,
              height: DesignTokens.lineHeightTight,
            ),
          ),
          const SizedBox(height: DesignTokens.space4),
          Text(
            step.cuerpo,
            style: context.texts.bodyLarge?.copyWith(
              fontSize: 15,
              color: context.scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Row(
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: DesignTokens.space1 + 2),
          AnimatedContainer(
            duration: DesignTokens.durationFast,
            width: i == active ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == active ? scheme.primary : scheme.outline,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ],
    );
  }
}
