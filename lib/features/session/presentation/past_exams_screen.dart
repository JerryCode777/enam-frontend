import 'dart:async';

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
import '../domain/session_models.dart';

/// Los exámenes ENAM que ya se rindieron (RF-52).
final pastExamsProvider = FutureProvider<List<PastExam>>((ref) {
  return ref.watch(sessionRepositoryProvider).pastExams();
});

/// Pantalla 5.10 — exámenes pasados.
///
/// Se rinden con la misma metodología del simulacro —reloj, sin feedback, sin
/// pausa— pero con las preguntas **reales** del examen de ese año, no con una
/// selección generada. Por eso todo llega del servidor: nombre, orden, claves
/// y explicaciones.
///
/// Primero se elige el examen y después el modo, y no al revés: el estudiante
/// viene buscando "el de 2025", no "uno de 40 preguntas". El modo se pregunta
/// en una hoja para no perder de vista qué examen se eligió.
class PastExamsScreen extends ConsumerWidget {
  const PastExamsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examenes = ref.watch(pastExamsProvider);

    return Scaffold(
      appBar: const GradientHeader(
        titulo: 'Exámenes pasados',
        subtitulo: 'Los ENAM que ya se rindieron, tal como fueron',
      ),
      body: examenes.when(
        loading: () => const _Cargando(),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(DesignTokens.space4),
          child: StateBanner(
            kind: BannerKind.error,
            message: 'No pudimos cargar los exámenes.',
            action: TextButton(
              onPressed: () => ref.invalidate(pastExamsProvider),
              child: const Text('Reintentar'),
            ),
          ),
        ),
        data: (lista) => lista.isEmpty
            ? const _SinExamenes()
            : _Lista(examenes: lista),
      ),
    );
  }
}

class _Lista extends StatelessWidget {
  const _Lista({required this.examenes});

  final List<PastExam> examenes;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.space5,
        DesignTokens.space4,
        DesignTokens.space5,
        DesignTokens.space8,
      ),
      itemCount: examenes.length,
      separatorBuilder: (_, _) => const SizedBox(height: DesignTokens.space2 + 2),
      itemBuilder: (context, i) {
        final examen = examenes[i];
        // El año solo se anuncia cuando cambia: repetirlo en cada fila es ruido.
        final anterior = i == 0 ? null : examenes[i - 1].anio;
        final nuevoAnio = examen.anio != anterior;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (nuevoAnio) ...[
              if (i > 0) const SizedBox(height: DesignTokens.space3),
              Padding(
                padding: const EdgeInsets.only(bottom: DesignTokens.space2),
                child: Text(
                  '${examen.anio}',
                  style: context.texts.bodySmall?.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.9,
                    color: context.scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
            _FilaExamen(examen: examen),
          ],
        );
      },
    );
  }
}

class _FilaExamen extends StatelessWidget {
  const _FilaExamen({required this.examen});

  final PastExam examen;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final states = context.states;

    return Card(
      child: InkWell(
        onTap: () => _elegirModo(context, examen),
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg + 2),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.space4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(DesignTokens.space2 + 1),
                decoration: BoxDecoration(
                  color: states.info.tint,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                ),
                child: Icon(
                  Symbols.history_edu,
                  size: 22,
                  fill: 1,
                  color: states.info.onTint,
                ),
              ),
              const SizedBox(width: DesignTokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            examen.nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.texts.bodyLarge?.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                        // La convocatoria distingue las dos del mismo año.
                        // Va aparte del nombre para poder pintarla como
                        // distintivo, y viene VACÍA —no nula— cuando ese año
                        // hubo una sola.
                        if (examen.convocatoria.isNotEmpty) ...[
                          const SizedBox(width: DesignTokens.space2),
                          _Distintivo(texto: examen.convocatoria),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        '${examen.totalPreguntas} preguntas',
                        // Cuántas veces lo rindió, no un "ya lo hiciste": un
                        // examen pasado es material de estudio y repetirlo es
                        // justo para lo que sirve.
                        if (examen.intentos == 1) '1 intento',
                        if (examen.intentos > 1) '${examen.intentos} intentos',
                        if (examen.mejorNota != null)
                          'tu mejor: ${examen.mejorNota!.toStringAsFixed(2)}',
                      ].join(' · '),
                      style: context.texts.bodySmall?.copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: DesignTokens.space2),
              if (examen.resuelto)
                Icon(
                  Symbols.check_circle,
                  size: 20,
                  fill: 1,
                  color: states.success.onTint,
                )
              else
                Icon(
                  Symbols.chevron_right,
                  size: 20,
                  color: scheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Distintivo extends StatelessWidget {
  const _Distintivo({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final states = context.states;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.space2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: states.warning.tint,
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
      ),
      child: Text(
        texto,
        style: context.texts.bodySmall?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: states.warning.onTint,
        ),
      ),
    );
  }
}

/// La hoja donde se elige cómo rendirlo.
///
/// Va después del examen y no antes: primero se decide *cuál*, que es lo que
/// el estudiante vino a buscar, y el modo es una decisión de dos opciones que
/// no merece pantalla propia.
Future<void> _elegirModo(BuildContext context, PastExam examen) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _HojaDeModo(examen: examen),
  );
}

class _HojaDeModo extends ConsumerStatefulWidget {
  const _HojaDeModo({required this.examen});

  final PastExam examen;

  @override
  ConsumerState<_HojaDeModo> createState() => _HojaDeModoState();
}

class _HojaDeModoState extends ConsumerState<_HojaDeModo> {
  PastExamMode _modo = PastExamMode.completo;
  bool _empezando = false;

  Future<void> _empezar() async {
    if (_empezando) return;
    setState(() => _empezando = true);

    try {
      final sesion = await ref
          .read(sessionRepositoryProvider)
          .startPastExam(widget.examen.id, modo: _modo);

      // D-02: rendir un examen también consume el día de prueba.
      await ref.read(inicioPruebaProvider.notifier).arrancar();
      ref.invalidate(sesionesAbiertasProvider);

      if (!mounted) return;
      Navigator.of(context).pop();
      unawaited(context.push(Routes.simulacroSessionOf(sesion.id)));
    } on Failure catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _empezando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final examen = widget.examen;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          DesignTokens.space5,
          DesignTokens.space4,
          DesignTokens.space5,
          DesignTokens.space5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.space4),
            Text(
              examen.nombre,
              style: context.texts.headlineMedium?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Elige cómo quieres rendirlo',
              style: context.texts.bodyMedium?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: DesignTokens.space4),

            _OpcionModo(
              modo: PastExamMode.completo,
              seleccionado: _modo == PastExamMode.completo,
              titulo: 'Examen completo',
              detalle:
                  '${examen.totalPreguntas} preguntas · '
                  '${Blueprint.examDuration.inHours} horas',
              apoyo: 'Como el día del examen, de principio a fin',
              onTap: () => setState(() => _modo = PastExamMode.completo),
            ),
            const SizedBox(height: DesignTokens.space2 + 2),
            _OpcionModo(
              modo: PastExamMode.corto,
              seleccionado: _modo == PastExamMode.corto,
              titulo: 'Versión corta',
              detalle:
                  '${Blueprint.sampleExamQuestions} preguntas · '
                  '${Blueprint.sampleExamDuration.inMinutes} minutos',
              apoyo: 'Para medirte cuando no tienes tres horas',
              onTap: () => setState(() => _modo = PastExamMode.corto),
            ),

            const SizedBox(height: DesignTokens.space4),
            // Lo mismo que en el simulacro, y por lo mismo: quien abandona a
            // los 40 minutos pierde el intento, y eso se dice antes.
            const StateBanner(
              kind: BannerKind.warning,
              message: 'Una vez que empieces, el reloj no se detiene.',
            ),
            const SizedBox(height: DesignTokens.space4),
            EnamButton(
              label: 'Empezar',
              loading: _empezando,
              onPressed: _empezar,
            ),
          ],
        ),
      ),
    );
  }
}

class _OpcionModo extends StatelessWidget {
  const _OpcionModo({
    required this.modo,
    required this.seleccionado,
    required this.titulo,
    required this.detalle,
    required this.apoyo,
    required this.onTap,
  });

  final PastExamMode modo;
  final bool seleccionado;
  final String titulo;
  final String detalle;
  final String apoyo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final radio = BorderRadius.circular(DesignTokens.radiusLg + 2);

    return Semantics(
      button: true,
      selected: seleccionado,
      child: Material(
        color: seleccionado ? context.states.info.tint : scheme.surface,
        borderRadius: radio,
        child: InkWell(
          onTap: onTap,
          borderRadius: radio,
          child: Container(
            padding: const EdgeInsets.all(DesignTokens.space4),
            decoration: BoxDecoration(
              borderRadius: radio,
              border: Border.all(
                color: seleccionado ? scheme.primary : scheme.outlineVariant,
                width: seleccionado ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  seleccionado
                      ? Symbols.radio_button_checked
                      : Symbols.radio_button_unchecked,
                  size: 22,
                  fill: seleccionado ? 1 : 0,
                  color: seleccionado
                      ? scheme.primary
                      : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: DesignTokens.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: context.texts.bodyLarge?.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                        ),
                      ),
                      Text(
                        detalle,
                        style: context.texts.bodyMedium?.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: context.states.info.onTint,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        apoyo,
                        style: context.texts.bodySmall?.copyWith(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SinExamenes extends StatelessWidget {
  const _SinExamenes();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Symbols.history_edu,
              size: 44,
              color: context.scheme.onSurfaceVariant,
            ),
            const SizedBox(height: DesignTokens.space4),
            Text(
              'Todavía no hay exámenes cargados',
              textAlign: TextAlign.center,
              style: context.texts.bodyLarge?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: DesignTokens.space2),
            Text(
              'Se van sumando conforme se digitalizan. Mientras tanto, el '
              'simulacro arma uno con el mismo peso por área.',
              textAlign: TextAlign.center,
              style: context.texts.bodyMedium?.copyWith(
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Cargando extends StatelessWidget {
  const _Cargando();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.space5,
        DesignTokens.space4,
        DesignTokens.space5,
        DesignTokens.space8,
      ),
      children: [
        for (var i = 0; i < 6; i++)
          const Padding(
            padding: EdgeInsets.only(bottom: DesignTokens.space2 + 2),
            child: SkeletonBox(height: 76, radius: DesignTokens.radiusLg + 2),
          ),
      ],
    );
  }
}
