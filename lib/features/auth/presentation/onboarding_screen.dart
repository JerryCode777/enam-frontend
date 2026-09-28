import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/domain/blueprint.dart';
import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/state_colors.dart';
import '../../../shared/widgets/brand_gradient.dart';
import '../../../shared/widgets/brand_mark.dart';

/// Pantalla 1.2 — presentación, **una sola pantalla**.
///
/// Era un carrusel de tres pasos: para llegar a crear la cuenta había que
/// deslizar o pulsar «Siguiente» dos veces, y lo que se aprendía por el camino
/// eran viñetas. El plan de rediseño (§6) pide lo contrario: el beneficio y un
/// ejemplo en una pantalla, y la acción directa. Quien quiera saber más lo
/// verá usando la app, que es donde se entiende.
///
/// Se muestra **una sola vez**: al salir por cualquier vía se marca como visto
/// y el router ya no vuelve a traer aquí.
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  /// Sale para no volver. Se marca como visto **antes** de navegar: si se
  /// hiciera después, el redirect del router se dispararía con la bandera aún
  /// en falso y traería al usuario de vuelta aquí.
  Future<void> _salir(
    WidgetRef ref,
    BuildContext context,
    String destino,
  ) async {
    await ref.read(startupProvider.notifier).marcarOnboardingVisto();
    if (context.mounted) context.go(destino);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: BrandGradient(
        circuloSecundarioArriba: false,
        formaInferior: false,
        child: SafeArea(
          child: Column(
            children: [
              // El contenido se desplaza; las acciones no. Así «Ya tengo
              // cuenta» se ve en un teléfono bajo o con la letra ampliada.
              const Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    DesignTokens.space6,
                    DesignTokens.space5,
                    DesignTokens.space6,
                    DesignTokens.space4,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Presentacion(),
                      SizedBox(height: DesignTokens.space5),
                      _Ejemplo(),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.space6,
                  DesignTokens.space2,
                  DesignTokens.space6,
                  DesignTokens.space3,
                ),
                child: _Acciones(
                  onCrear: () => _salir(ref, context, Routes.register),
                  onEntrar: () => _salir(ref, context, Routes.login),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Presentacion extends StatelessWidget {
  const _Presentacion();

  @override
  Widget build(BuildContext context) {
    const blanco = Colors.white;
    final suave = Colors.white.withValues(alpha: 0.88);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            BrandMark(size: 32),
            SizedBox(width: DesignTokens.space2),
            Text(
              'ENAM Prep',
              style: TextStyle(
                fontFamily: DesignTokens.fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: blanco,
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.space5),
        Semantics(
          header: true,
          child: const Text(
            'Practica para el ENAM y entiende cada respuesta',
            style: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 28,
              height: 1.15,
              fontWeight: FontWeight.w800,
              color: blanco,
            ),
          ),
        ),
        const SizedBox(height: DesignTokens.space4),
        for (final (icono, texto) in [
          (Symbols.quiz, 'Preguntas con la explicación de cada alternativa'),
          (
            Symbols.timer,
            'Simulacros de ${Blueprint.totalQuestions} preguntas y '
                '${Blueprint.examDuration.inHours} horas, como el examen',
          ),
          (Symbols.download, 'Áreas descargadas para estudiar sin señal'),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: DesignTokens.space2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icono, size: 20, color: suave),
                const SizedBox(width: DesignTokens.space3),
                Expanded(
                  child: Text(
                    texto,
                    style: TextStyle(
                      fontFamily: DesignTokens.fontFamily,
                      fontSize: 16,
                      height: 1.4,
                      color: suave,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Un ejemplo de cómo se ve una pregunta respondida, **rotulado como tal**.
///
/// El contenido es deliberadamente de manual —la adrenalina intramuscular
/// como primera línea en la anafilaxia— para que el ejemplo no pueda enseñar
/// nada discutible. Lo que muestra es la forma: el veredicto y el porqué.
class _Ejemplo extends StatelessWidget {
  const _Ejemplo();

  @override
  Widget build(BuildContext context) {
    final ok = context.states.success;
    final scheme = context.scheme;

    return Semantics(
      label:
          'Ejemplo de pregunta respondida. En la anafilaxia, el tratamiento '
          'de primera línea es la adrenalina intramuscular.',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.space4),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'EJEMPLO',
              style: context.texts.bodySmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: DesignTokens.space2),
            Text(
              '¿Cuál es el tratamiento de primera línea en la anafilaxia?',
              style: context.texts.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: DesignTokens.space3),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.space3,
                vertical: DesignTokens.space2 + 2,
              ),
              decoration: BoxDecoration(
                color: ok.tint,
                border: Border.all(color: ok.base, width: 1.5),
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              ),
              child: Row(
                children: [
                  Icon(
                    Symbols.check_circle,
                    size: 20,
                    fill: 1,
                    color: ok.onTint,
                  ),
                  const SizedBox(width: DesignTokens.space2),
                  Expanded(
                    child: Text(
                      'Adrenalina intramuscular',
                      style: context.texts.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: ok.onTint,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.space3),
            Text(
              'Por qué: revierte la vasodilatación y el broncoespasmo. Los '
              'antihistamínicos y los corticoides no la sustituyen.',
              style: context.texts.bodyMedium?.copyWith(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _Acciones extends StatelessWidget {
  const _Acciones({required this.onCrear, required this.onEntrar});

  final VoidCallback onCrear;
  final VoidCallback onEntrar;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Blanco sobre la marca: es el único botón principal de la pantalla.
        FilledButton(
          onPressed: onCrear,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: DesignTokens.onActionDark,
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            ),
            textStyle: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          child: const Text('Crear cuenta gratis'),
        ),
        const SizedBox(height: DesignTokens.space2),
        // La regla real del servidor (D-02): el día de prueba no empieza al
        // registrarse sino con la primera práctica.
        Text(
          'Tu prueba de 24 horas empieza con tu primera práctica.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: DesignTokens.fontFamily,
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.88),
          ),
        ),
        TextButton(
          onPressed: onEntrar,
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(DesignTokens.minTouchTarget),
            textStyle: const TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: const Text('Ya tengo cuenta'),
        ),
      ],
    );
  }
}
