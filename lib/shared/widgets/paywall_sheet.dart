import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../core/domain/blueprint.dart';
import '../../core/router/routes.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/state_colors.dart';
import 'animations.dart';
import 'enam_button.dart';

/// Por qué apareció el paywall. Cambia el titular, no el resto.
enum PaywallMotivo {
  /// Agotó sus 20 preguntas del día (RN-03).
  cuotaDiaria,

  /// Intentó abrir un simulacro completo con plan free.
  simulacroCompleto,

  /// Intentó descargar contenido para offline.
  descargaOffline,
}

/// Pantalla 4.6 — bloqueo por plan gratuito (RN-03), como hoja inferior.
///
/// Reglas de tono, que son la parte que importa:
/// - **Reconoce lo hecho antes de vender.** "Completaste tus 20 de hoy" no es lo
///   mismo que "alcanzaste el límite".
/// - **Dice qué sigue siendo gratis** antes del botón de pago. Sin eso se lee
///   como castigo, y el público ya viene golpeado.
/// - **Nunca atrapa.** "Quizá después" cierra y devuelve donde estaba.
///
/// Navegar el temario, ver estadísticas y releer explicaciones nunca se bloquean:
/// el límite aplica al **iniciar** práctica, no a consultar.
Future<void> mostrarPaywall(
  BuildContext context, {
  PaywallMotivo motivo = PaywallMotivo.cuotaDiaria,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _PaywallSheet(motivo: motivo),
  );
}

class _PaywallSheet extends StatefulWidget {
  const _PaywallSheet({required this.motivo});

  final PaywallMotivo motivo;

  static const _beneficios = [
    (
      icon: Symbols.all_inclusive,
      texto: 'Práctica ilimitada del banco completo',
    ),
    (icon: Symbols.timer, texto: 'Simulacros de 180 y nacionales con ranking'),
    (icon: Symbols.download, texto: 'Modo offline para la guardia'),
  ];

  @override
  State<_PaywallSheet> createState() => _PaywallSheetState();
}

class _PaywallSheetState extends State<_PaywallSheet> {
  /// El sheet se abre explicando y recién después ofrece.
  ///
  /// Alguien que topa un límite está en medio de otra cosa: primero necesita
  /// entender qué pasó. Si lo primero que ve es una lista de precios, el
  /// mensaje se lee como un cobro y no como una explicación.
  bool _mostrarPlanes = false;

  static const _esperaAntesDeOfrecer = Duration(milliseconds: 2200);

  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_mostrarPlanes || _timer != null) return;

    // Con el movimiento reducido no se hace esperar a nadie: se muestra todo
    // de una vez. La pausa es un recurso de ritmo, no información.
    if (Motion.reduced(context)) {
      _mostrarPlanes = true;
      return;
    }
    _timer = Timer(_esperaAntesDeOfrecer, _revelar);
  }

  void _revelar() {
    _timer?.cancel();
    _timer = null;
    if (mounted && !_mostrarPlanes) setState(() => _mostrarPlanes = true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final states = context.states;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final motivo = widget.motivo;

    final (titular, bajada) = switch (motivo) {
      PaywallMotivo.cuotaDiaria => (
        'Completaste tus ${Blueprint.freeDailyQuestionLimit} de hoy',
        'Buen ritmo. Sigue sin límites con Premium.',
      ),
      PaywallMotivo.simulacroCompleto => (
        'Los simulacros completos son de Premium',
        'Tu simulacro de muestra de ${Blueprint.sampleExamQuestions} sigue '
            'disponible.',
      ),
      PaywallMotivo.descargaOffline => (
        'Estudiar sin conexión es de Premium',
        'Descarga áreas completas y practica sin internet.',
      ),
    };

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cabecera en degradado: el bloqueo no debe parecer un error.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.space6,
              DesignTokens.space4,
              DesignTokens.space6,
              DesignTokens.space5,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isLight
                    ? DesignTokens.headerGradientLight
                    : DesignTokens.headerGradientDark,
                stops: DesignTokens.headerGradientStops,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(DesignTokens.space3 - 1),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(
                      DesignTokens.radiusMd + 3,
                    ),
                  ),
                  child: const Icon(
                    Symbols.workspace_premium,
                    size: 26,
                    fill: 1,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: DesignTokens.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titular,
                        style: context.texts.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          height: DesignTokens.lineHeightTight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        bajada,
                        style: context.texts.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: Motion.duration(context, Motion.slow),
            curve: Motion.enter,
            alignment: Alignment.topCenter,
            child: !_mostrarPlanes
                ? _Esperando(onSaltar: _revelar)
                : _Oferta(states: states, motivo: motivo),
          ),
        ],
      ),
    );
  }
}

/// Fase 1: solo la explicación, con una salida inmediata para quien no quiera
/// esperar los dos segundos.
class _Esperando extends StatelessWidget {
  const _Esperando({required this.onSaltar});

  final VoidCallback onSaltar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.space6,
        DesignTokens.space5,
        DesignTokens.space6,
        DesignTokens.space6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Es una función de Premium.',
            textAlign: TextAlign.center,
            style: context.texts.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: context.scheme.onSurface,
            ),
          ),
          const SizedBox(height: DesignTokens.space3),
          TextButton(onPressed: onSaltar, child: const Text('Ver qué incluye')),
        ],
      ),
    );
  }
}

/// Fase 2: los beneficios, lo que sigue siendo gratis y el paso a los planes.
class _Oferta extends StatelessWidget {
  const _Oferta({required this.states, required this.motivo});

  final StateColors states;
  final PaywallMotivo motivo;

  @override
  Widget build(BuildContext context) {
    return FadeUp(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final b in _PaywallSheet._beneficios)
              Padding(
                padding: const EdgeInsets.only(bottom: DesignTokens.space3),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(DesignTokens.space2 + 1),
                      decoration: BoxDecoration(
                        color: states.info.tint,
                        borderRadius: BorderRadius.circular(
                          DesignTokens.radiusMd,
                        ),
                      ),
                      child: Icon(
                        b.icon,
                        size: 20,
                        fill: 1,
                        color: states.info.onTint,
                      ),
                    ),
                    const SizedBox(width: DesignTokens.space3),
                    Expanded(
                      child: Text(
                        b.texto,
                        style: context.texts.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: context.scheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: DesignTokens.space2),
            // Lo que sigue siendo gratis, antes del botón de pago.
            Container(
              padding: const EdgeInsets.all(DesignTokens.space3 + 1),
              decoration: BoxDecoration(
                color: context.scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd + 2),
              ),
              child: Text(
                'Tu plan gratis se mantiene: '
                '${Blueprint.freeDailyQuestionLimit} preguntas al día y un '
                'simulacro de muestra, para siempre.',
                style: context.texts.bodySmall?.copyWith(height: 1.5),
              ),
            ),
            const SizedBox(height: DesignTokens.space5),
            EnamButton(
              label: 'Ver los planes',
              onPressed: () {
                Navigator.of(context).pop();
                context.push(Routes.plans);
              },
            ),
            const SizedBox(height: DesignTokens.space2),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Quizá después',
                style: TextStyle(color: context.scheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
