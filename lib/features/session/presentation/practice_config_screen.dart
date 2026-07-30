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
import '../../../shared/widgets/paywall_sheet.dart';
import '../../../shared/widgets/state_banner.dart';
import '../../catalog/domain/catalog_models.dart';
import '../../catalog/presentation/catalog_providers.dart';
import '../domain/session_models.dart';

/// Pantalla 4.1 — configurador de práctica (RF-12).
///
/// Llega desde el temario con el nodo ya puesto (RF-38), o desde el inicio sin
/// nodo. Muestra cuántas preguntas hay disponibles en el nodo elegido: pedir 50
/// donde solo hay 12 tiene que verse antes de empezar, no después.
class PracticeConfigScreen extends ConsumerStatefulWidget {
  const PracticeConfigScreen({this.nodoId, this.origenInicial, super.key});

  /// Nodo preseleccionado desde el temario.
  final String? nodoId;

  /// Origen preseleccionado. Un nodo agotado llega con `falladas`.
  final String? origenInicial;

  @override
  ConsumerState<PracticeConfigScreen> createState() =>
      _PracticeConfigScreenState();
}

class _PracticeConfigScreenState extends ConsumerState<PracticeConfigScreen> {
  late int _cantidad = 20;
  late QuestionSource _origen = QuestionSource.values.firstWhere(
    (o) => o.name == widget.origenInicial,
    orElse: () => QuestionSource.todas,
  );
  bool _creando = false;

  @override
  Widget build(BuildContext context) {
    final nodo = widget.nodoId == null
        ? null
        : ref.watch(nodoProvider(widget.nodoId!));
    final stats = ref.watch(dashboardProvider).value;

    // Tope del plan gratuito. Se muestra, pero la validación real es del
    // servidor (RN-03): la app no puede ser la que decide.
    final restantesHoy = stats?.preguntasRestantesHoy;
    final tope = restantesHoy == null
        ? Blueprint.practiceMaxQuestions
        : restantesHoy.clamp(0, Blueprint.practiceMaxQuestions);
    final sinCupo = restantesHoy != null && restantesHoy <= 0;

    final disponibles = nodo?.nodo.preguntasDisponibles;
    final cantidadEfectiva = _cantidadEfectiva(tope, disponibles);

    return Scaffold(
      body: Column(
        children: [
          const GradientHeader(titulo: 'Nueva práctica'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.space5,
                DesignTokens.space4,
                DesignTokens.space5,
                DesignTokens.space8,
              ),
              children: [
                _Seccion(
                  titulo: 'QUÉ VAS A PRACTICAR',
                  child: _SelectorNodo(nodo: nodo?.nodo, ruta: nodo?.ruta),
                ),
                const SizedBox(height: DesignTokens.space5),
                _Seccion(
                  titulo: 'CANTIDAD',
                  trailing: Text(
                    '$cantidadEfectiva '
                    '${cantidadEfectiva == 1 ? "pregunta" : "preguntas"}',
                    style: context.texts.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: context.states.info.onTint,
                    ),
                  ),
                  child: _SliderCantidad(
                    valor: _cantidad.toDouble(),
                    tope: tope,
                    onChanged: (v) => setState(() => _cantidad = v.round()),
                    onTopeAlcanzado: sinCupo
                        ? null
                        : () => _avisarTope(context, tope),
                  ),
                ),
                const SizedBox(height: DesignTokens.space5),
                _Seccion(
                  titulo: 'QUÉ PREGUNTAS',
                  child: _SelectorOrigen(
                    valor: _origen,
                    onChanged: (v) => setState(() => _origen = v),
                  ),
                ),
                if (nodo != null) ...[
                  const SizedBox(height: DesignTokens.space4),
                  _ResumenDisponibles(nodo: nodo.nodo),
                ],
                if (disponibles != null && disponibles < _cantidad) ...[
                  const SizedBox(height: DesignTokens.space4),
                  StateBanner(
                    kind: BannerKind.info,
                    message:
                        'En este nodo hay $disponibles preguntas. La sesión va '
                        'a tener esas.',
                  ),
                ],
              ],
            ),
          ),
          _BarraEmpezar(
            sinCupo: sinCupo,
            cantidad: cantidadEfectiva,
            creando: _creando,
            onEmpezar: () => _empezar(cantidadEfectiva),
            onVerPlanes: () => mostrarPaywall(context, motivo: PaywallMotivo.cuotaDiaria),
          ),
        ],
      ),
    );
  }

  /// La cantidad que realmente se va a pedir: lo elegido, topado por el cupo del
  /// plan y por lo que hay en el nodo.
  int _cantidadEfectiva(int tope, int? disponibles) {
    var n = _cantidad.clamp(Blueprint.practiceMinQuestions, tope);
    if (disponibles != null && disponibles > 0) n = n.clamp(1, disponibles);
    return n;
  }

  void _avisarTope(BuildContext context, int tope) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text('Tu tope de hoy es $tope preguntas.')),
      );
  }

  Future<void> _empezar(int cantidad) async {
    if (_creando) return;
    setState(() => _creando = true);

    try {
      final nodoId = widget.nodoId;
      final session = await ref.read(sessionRepositoryProvider).startPractice(
        PracticeConfig(
          // El nodo puede ser área, sub área o tema; el servidor resuelve el
          // subárbol. Se manda en `subtemaIds` salvo que sea un área.
          areaIds: nodoId != null && !nodoId.contains('-') ? [nodoId] : const [],
          subtemaIds: nodoId != null && nodoId.contains('-')
              ? [nodoId]
              : const [],
          cantidadPreguntas: cantidad,
          origen: _origen,
        ),
      );
      if (mounted) context.pushReplacement(Routes.practiceSessionOf(session.id));
    } on ForbiddenFailure catch (e) {
      // RN-03: el servidor es el que impone el límite. Si lo rechaza, se muestra
      // el paywall en vez de un error genérico.
      if (!mounted) return;
      if (e.isPlanLimit) {
        await mostrarPaywall(context, motivo: PaywallMotivo.cuotaDiaria);
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

class _Seccion extends StatelessWidget {
  const _Seccion({required this.titulo, required this.child, this.trailing});

  final String titulo;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return FadeUp(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  titulo,
                  style: context.texts.bodySmall?.copyWith(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: context.scheme.onSurfaceVariant,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: DesignTokens.space2 + 2),
          child,
        ],
      ),
    );
  }
}

class _SelectorNodo extends StatelessWidget {
  const _SelectorNodo({this.nodo, this.ruta});

  final CatalogNode? nodo;
  final List<CatalogNode>? ruta;

  @override
  Widget build(BuildContext context) {
    final sinNodo = nodo == null;
    final migas = ruta != null && ruta!.length > 1
        ? ruta!.take(ruta!.length - 1).map((n) => n.nombre).join(' › ')
        : null;

    return Card(
      child: InkWell(
        onTap: () => context.push(Routes.temario),
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.space4),
          child: Row(
            children: [
              Icon(
                sinNodo ? Symbols.shuffle : Symbols.account_tree,
                size: 24,
                fill: 1,
                color: context.states.info.onTint,
              ),
              const SizedBox(width: DesignTokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (migas != null)
                      Text(
                        migas,
                        style: context.texts.bodySmall?.copyWith(fontSize: 11.5),
                      ),
                    Text(
                      sinNodo ? 'Todo el temario' : nodo!.nombre,
                      style: context.texts.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: DesignTokens.space2),
              Text(
                'Cambiar',
                style: context.texts.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.states.info.onTint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliderCantidad extends StatelessWidget {
  const _SliderCantidad({
    required this.valor,
    required this.tope,
    required this.onChanged,
    required this.onTopeAlcanzado,
  });

  final double valor;
  final int tope;
  final ValueChanged<double> onChanged;
  final VoidCallback? onTopeAlcanzado;

  @override
  Widget build(BuildContext context) {
    const min = Blueprint.practiceMinQuestions;
    const max = Blueprint.practiceMaxQuestions;
    final topeRelativo = (tope - min) / (max - min);

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Marca visual del tope del plan, para que el usuario entienda por
            // qué el control se frena antes del final.
            if (tope < max)
              Align(
                alignment: Alignment(topeRelativo * 2 - 1, 0),
                child: Container(
                  width: 2,
                  height: 18,
                  color: context.states.warning.base,
                ),
              ),
            Slider(
              value: valor.clamp(min.toDouble(), max.toDouble()),
              min: min.toDouble(),
              max: max.toDouble(),
              divisions: max - min,
              label: '${valor.round()}',
              onChanged: (v) {
                if (v > tope) {
                  onTopeAlcanzado?.call();
                  onChanged(tope.toDouble());
                } else {
                  onChanged(v);
                }
              },
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$min', style: context.texts.bodySmall),
            if (tope < max)
              Text(
                'tu tope de hoy: $tope',
                style: context.texts.bodySmall?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: context.states.warning.onTint,
                ),
              ),
            Text('$max', style: context.texts.bodySmall),
          ],
        ),
      ],
    );
  }
}

class _SelectorOrigen extends StatelessWidget {
  const _SelectorOrigen({required this.valor, required this.onChanged});

  final QuestionSource valor;
  final ValueChanged<QuestionSource> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<QuestionSource>(
      segments: [
        for (final origen in QuestionSource.values)
          ButtonSegment(value: origen, label: Text(origen.label)),
      ],
      selected: {valor},
      showSelectedIcon: false,
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

class _ResumenDisponibles extends StatelessWidget {
  const _ResumenDisponibles({required this.nodo});

  final CatalogNode nodo;

  @override
  Widget build(BuildContext context) {
    return FadeUp(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space4,
            vertical: DesignTokens.space3 + 1,
          ),
          child: Column(
            children: [
              _Fila(
                etiqueta: 'Disponibles aquí',
                valor: '${nodo.preguntasDisponibles} preguntas',
              ),
              const SizedBox(height: DesignTokens.space1 + 2),
              _Fila(etiqueta: 'Ya viste', valor: '${nodo.preguntasVistas}'),
            ],
          ),
        ),
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
    return Row(
      children: [
        Expanded(child: Text(etiqueta, style: context.texts.bodySmall)),
        Text(
          valor,
          style: context.texts.bodySmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: context.scheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _BarraEmpezar extends StatelessWidget {
  const _BarraEmpezar({
    required this.sinCupo,
    required this.cantidad,
    required this.creando,
    required this.onEmpezar,
    required this.onVerPlanes,
  });

  final bool sinCupo;
  final int cantidad;
  final bool creando;
  final VoidCallback onEmpezar;
  final VoidCallback onVerPlanes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        DesignTokens.space5,
        DesignTokens.space3,
        DesignTokens.space5,
        DesignTokens.space3 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: context.scheme.surface,
        border: Border(top: BorderSide(color: context.scheme.outlineVariant)),
      ),
      child: EnamButton(
        // Sin cupo el botón no falla: lleva a lo único que desbloquea seguir.
        label: sinCupo ? 'Mejorar a Premium' : 'Empezar · $cantidad preguntas',
        icon: sinCupo ? Symbols.workspace_premium : Symbols.play_arrow,
        loading: creando,
        onPressed: sinCupo ? onVerPlanes : onEmpezar,
      ),
    );
  }
}
