import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../../core/domain/taxonomy.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/providers.dart';
import '../../../../core/router/navegar.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/state_colors.dart';
import '../../../../shared/widgets/brand_mark.dart';
import '../../../../shared/widgets/state_banner.dart';
import '../../../session/domain/session_models.dart';
import '../../../session/presentation/widgets/option_card.dart';
import '../../../subscription/presentation/muro_de_venta_screen.dart';
import '../../domain/marcadores.dart';
import '../../domain/tutor_models.dart';
import '../tutor_controller.dart';

/// La cara del tutor: la marca de ENAM Prep, no una mascota.
///
/// Mientras piensa, late. Es lo único que se mueve: el tutor no tiene
/// personaje (Jerry todavía no lo eligió), así que no se le inventan gestos.
class AvatarDelTutor extends StatefulWidget {
  const AvatarDelTutor({this.pensando = false, this.size = 28, super.key});

  final bool pensando;
  final double size;

  @override
  State<AvatarDelTutor> createState() => _AvatarDelTutorState();
}

class _AvatarDelTutorState extends State<AvatarDelTutor>
    with SingleTickerProviderStateMixin {
  late final _latido = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sincronizar();
  }

  @override
  void didUpdateWidget(AvatarDelTutor old) {
    super.didUpdateWidget(old);
    _sincronizar();
  }

  void _sincronizar() {
    final quieto = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (widget.pensando && !quieto) {
      if (!_latido.isAnimating) _latido.repeat(reverse: true);
    } else {
      _latido
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _latido.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: ScaleTransition(
        scale: Tween(
          begin: 1.0,
          end: 0.86,
        ).animate(CurvedAnimation(parent: _latido, curve: Curves.easeInOut)),
        child: BrandMarkTile(size: widget.size),
      ),
    );
  }
}

/// «Practicar ahora»: la tarjeta de `[comp:practica:{…}]`.
///
/// La práctica se crea **al tocar**, nunca al aparecer: el tutor propone, el
/// alumno decide. Lo que el servidor de sesiones rechace (el cupo gratis, una
/// función de pago) se atiende como en cualquier práctica: con el muro.
class TarjetaPracticar extends ConsumerStatefulWidget {
  const TarjetaPracticar({required this.practica, super.key});

  final PracticaPropuesta practica;

  @override
  ConsumerState<TarjetaPracticar> createState() => _TarjetaPracticarState();
}

class _TarjetaPracticarState extends ConsumerState<TarjetaPracticar> {
  var _creando = false;

  String get _tema {
    final p = widget.practica;
    final nodo = Taxonomy.byId(p.temaId ?? p.areaId ?? '');
    return nodo?.nombre ?? 'todas las áreas';
  }

  Future<void> _empezar() async {
    if (_creando) return;
    setState(() => _creando = true);
    final p = widget.practica;
    try {
      final sesion = await ref
          .read(sessionRepositoryProvider)
          .startPractice(
            PracticeConfig(
              areaIds: [?p.areaId],
              subtemaIds: [?p.temaId],
              cantidadPreguntas: p.cantidad,
            ),
          );
      if (mounted) context.irA(Routes.practiceSessionOf(sesion.id));
    } on Failure catch (e) {
      if (!mounted) return;
      if (!atenderFaltaDeAcceso(context, ref, e)) {
        showErrorSnack(context, e.message);
      }
    } finally {
      if (mounted) setState(() => _creando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final success = context.states.success;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space3 + 2),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: success.tint,
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              ),
              child: Icon(Symbols.quiz, size: 22, color: success.onTint),
            ),
            const SizedBox(width: DesignTokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Practicar ahora',
                    style: context.texts.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.practica.cantidad} preguntas de $_tema',
                    style: context.texts.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: DesignTokens.space2),
            FilledButton(
              onPressed: _creando ? null : _empezar,
              child: _creando
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Empezar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// La pregunta de un chip `[pregunta:…]`, con la clave y su explicación.
Future<void> abrirPreguntaCitada(BuildContext context, String id) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scroll) => _PreguntaCitada(id: id, controller: scroll),
    ),
  );
}

final _preguntaCitadaProvider = FutureProvider.autoDispose
    .family<Question, String>(
      (ref, id) => ref.watch(tutorRepositoryProvider).pregunta(id),
    );

class _PreguntaCitada extends ConsumerWidget {
  const _PreguntaCitada({required this.id, required this.controller});

  final String id;
  final ScrollController controller;

  static const _letras = ['A', 'B', 'C', 'D', 'E'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pregunta = ref.watch(_preguntaCitadaProvider(id));
    const padding = EdgeInsets.fromLTRB(
      DesignTokens.space5,
      0,
      DesignTokens.space5,
      DesignTokens.space6,
    );

    return switch (pregunta) {
      AsyncData(value: final p) => ListView(
        controller: controller,
        padding: padding,
        children: [
          Text(
            p.enunciado,
            style: context.texts.bodyLarge?.copyWith(
              height: DesignTokens.lineHeightClinical,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: DesignTokens.space4),
          for (var i = 0; i < p.opciones.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: DesignTokens.space2),
              child: OptionCard(
                opcion: p.opciones[i],
                letra: i < _letras.length ? _letras[i] : '?',
                visual: p.opciones[i].esCorrecta == true
                    ? OptionVisual.correcta
                    : OptionVisual.normal,
                onTap: null,
              ),
            ),
          if (p.explicacion case final explicacion?) ...[
            const SizedBox(height: DesignTokens.space3),
            Text(
              'Por qué es esta',
              style: context.texts.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: context.states.success.onTint,
              ),
            ),
            const SizedBox(height: DesignTokens.space2),
            Text(
              explicacion,
              style: context.texts.bodyLarge?.copyWith(
                height: DesignTokens.lineHeightRelaxed,
              ),
            ),
          ],
        ],
      ),
      AsyncError() => const Padding(
        padding: padding,
        child: Align(
          alignment: Alignment.topCenter,
          child: StateBanner(
            kind: BannerKind.warning,
            message: 'No pudimos abrir esta pregunta.',
          ),
        ),
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

/// «Pregúntale al tutor», bajo la explicación de una pregunta.
///
/// Es la entrada con más valor: el tutor ya sabe de qué pregunta se habla. No
/// ocupa sitio cuando el tutor no está disponible.
class PreguntaleAlTutor extends ConsumerWidget {
  const PreguntaleAlTutor({
    required this.preguntaId,
    this.enunciado,
    this.espacioArriba = DesignTokens.space3,
    super.key,
  });

  final String preguntaId;
  final String? enunciado;
  final double espacioArriba;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(tutorVisibleProvider)) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(top: espacioArriba),
      child: OutlinedButton.icon(
        icon: const Icon(Symbols.forum, size: 20),
        label: const Text('Pregúntale al tutor'),
        onPressed: () => context.irA(
          Routes.tutor,
          extra: ContextoDelTutor.pregunta(
            id: preguntaId,
            enunciado: enunciado,
          ),
        ),
      ),
    );
  }
}
