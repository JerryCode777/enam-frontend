import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/domain/blueprint.dart';
import '../../../core/error/failure.dart';
import '../../../core/providers.dart';
import '../../../core/router/navegar.dart';
import '../../../core/router/routes.dart';
import '../../../core/sonido/proveedor_sonidos.dart';
import '../../../core/sonido/sonidos.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/state_colors.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/enam_button.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../../shared/widgets/state_banner.dart';
import '../../catalog/domain/catalog_models.dart';
import '../../catalog/presentation/catalog_providers.dart';
import '../../subscription/domain/acceso.dart';
import '../../subscription/presentation/muro_de_venta_screen.dart';
import '../../subscription/presentation/widgets/etiqueta_premium.dart';
import '../domain/session_models.dart';
import 'area_picker_screen.dart';

/// Pantalla 4.1 — configurador de práctica (RF-12).
///
/// Llega desde el temario con el nodo ya puesto (RF-38), o desde el inicio sin
/// nodo. Muestra cuántas preguntas hay disponibles en el nodo elegido: pedir 50
/// donde solo hay 12 tiene que verse antes de empezar, no después.
class PracticeConfigScreen extends ConsumerStatefulWidget {
  const PracticeConfigScreen({
    this.nodoId,
    this.origenInicial,
    this.cantidadInicial,
    super.key,
  });

  /// Nodo preseleccionado desde el temario.
  final String? nodoId;

  /// Origen preseleccionado. Un nodo agotado llega con `falladas`.
  final String? origenInicial;

  /// Cantidad con la que arranca el selector. El inicio manda 10 a quien
  /// todavía no ha practicado nunca: una primera práctica corta. Sigue siendo
  /// editable.
  final int? cantidadInicial;

  @override
  ConsumerState<PracticeConfigScreen> createState() =>
      _PracticeConfigScreenState();
}

class _PracticeConfigScreenState extends ConsumerState<PracticeConfigScreen> {
  late int _cantidad = (widget.cantidadInicial ?? 20).clamp(
    Blueprint.practiceMinQuestions,
    Blueprint.practiceMaxQuestions,
  );
  late QuestionSource _origen = QuestionSource.values.firstWhere(
    (o) => o.name == widget.origenInicial,
    orElse: () => QuestionSource.todas,
  );

  /// Nodo elegido en esta pantalla. Arranca con el que llegó por la ruta desde
  /// el temario (RF-38) y cambia si el usuario elige otro.
  late String? _nodoId = widget.nodoId;

  bool _creando = false;

  @override
  Widget build(BuildContext context) {
    if (ref.watch(cupoGratisProvider) case final gratis?) {
      return _enGratis(gratis);
    }

    final nodo = _nodoId == null ? null : ref.watch(nodoProvider(_nodoId!));

    // El rango es el de RF-12, sin toparlo por lo que hay en el nodo: el
    // tamaño del banco no se muestra en ninguna pantalla (pedido del usuario,
    // 06/10/2026), y una barra que se acorta lo diría igual. Si el nodo tiene
    // menos, el servidor crea la sesión con las que hay.
    const tope = Blueprint.practiceMaxQuestions;
    final cantidadEfectiva = _cantidadEfectiva(tope);

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
                  child: _SelectorNodo(
                    nodo: nodo?.nodo,
                    ruta: nodo?.ruta,
                    onElegir: _elegirNodo,
                  ),
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
                  _Resumen(nodo: nodo.nodo),
                ],
              ],
            ),
          ),
          _BarraEmpezar(
            etiqueta: 'Empezar · $cantidadEfectiva preguntas',
            creando: _creando,
            onEmpezar: () => _empezar(cantidadEfectiva),
          ),
        ],
      ),
    );
  }

  /// En gratis no hay nada que configurar: todo el banco, `todas` y hasta el
  /// cupo que queda. Lo que se elegiría se ve, con su candado, y abre el muro.
  /// El servidor fuerza lo mismo (`min(10, restantesHoy)`), así que esto solo
  /// evita prometer una práctica que no va a crear.
  Widget _enGratis(AccesoGratis gratis) {
    final porDia = gratis.preguntasPorDia;
    final cantidad = gratis.restantesHoy.clamp(0, porDia);
    void aPremium() => abrirMuro(
      context,
      ref,
      const FuncionDePago(FuncionPremium.practicaAMedida),
    );

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
                // Llegó con un tema elegido (desde el temario): se dice por
                // qué la práctica no va a ser de ese tema.
                if (widget.nodoId != null || widget.origenInicial != null) ...[
                  StateBanner(
                    kind: BannerKind.info,
                    message:
                        'Elegir área o tema es Premium. Tu práctica gratis es '
                        'de todas las áreas.',
                    action: TextButton(
                      onPressed: aPremium,
                      child: const Text('Ver Premium'),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.space5),
                ],
                _Seccion(
                  titulo: 'QUÉ VAS A PRACTICAR',
                  child: _FilaPremium(
                    icono: Symbols.shuffle,
                    texto: 'Todo el temario',
                    onTap: aPremium,
                  ),
                ),
                const SizedBox(height: DesignTokens.space5),
                _Seccion(
                  titulo: 'CANTIDAD',
                  trailing: Text(
                    '$cantidad ${cantidad == 1 ? "pregunta" : "preguntas"}',
                    style: context.texts.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: context.states.info.onTint,
                    ),
                  ),
                  child: Text(
                    gratis.agotado
                        ? 'Ya usaste tus $porDia preguntas gratis de hoy. '
                              'Mañana tienes $porDia más.'
                        : 'Gratis tienes $porDia preguntas al día. Te quedan '
                              '${gratis.restantesHoy} hoy.',
                    style: context.texts.bodyMedium?.copyWith(height: 1.5),
                  ),
                ),
                const SizedBox(height: DesignTokens.space5),
                _Seccion(
                  titulo: 'QUÉ PREGUNTAS',
                  child: _FilaPremium(
                    icono: Symbols.filter_list,
                    texto: 'Todas, vistas o no',
                    onTap: aPremium,
                  ),
                ),
              ],
            ),
          ),
          if (gratis.agotado)
            _BarraEmpezar(
              etiqueta: 'Ver Premium',
              icono: Symbols.workspace_premium,
              creando: false,
              onEmpezar: () => abrirMuro(context, ref, const CupoAgotado()),
            )
          else
            _BarraEmpezar(
              etiqueta: 'Empezar · $cantidad preguntas',
              creando: _creando,
              onEmpezar: () => _empezar(cantidad, gratis: true),
            ),
        ],
      ),
    );
  }

  /// Abre el selector de área y aplica lo elegido.
  ///
  /// Se abre como pantalla propia y no navegando a `/temario`: esa ruta vive en
  /// el shell de pestañas, y hacerle `push` desde aquí montaba un segundo
  /// Navigator con la misma GlobalKey — pantalla roja y sin vuelta atrás.
  Future<void> _elegirNodo() async {
    final elegido = await context.irAPorUnResultado<Object?>(
      Routes.practiceAreas,
    );
    if (!mounted || elegido == null) return;

    setState(() {
      _nodoId = esPracticarDeTodo(elegido)
          ? null
          : (elegido as CatalogNode).id;
    });
  }

  /// La cantidad que se va a pedir: lo elegido, dentro del rango de RF-12.
  int _cantidadEfectiva(int tope) =>
      _cantidad.clamp(Blueprint.practiceMinQuestions, tope);

  /// [gratis]: sin área ni filtro, que en gratis son Premium.
  Future<void> _empezar(int cantidad, {bool gratis = false}) async {
    if (_creando) return;
    setState(() => _creando = true);

    try {
      final nodoId = gratis ? null : _nodoId;
      final session = await ref.read(sessionRepositoryProvider).startPractice(
        PracticeConfig(
          // El nodo puede ser área, sub área o tema; el servidor resuelve el
          // subárbol. Se manda en `subtemaIds` salvo que sea un área.
          areaIds: nodoId != null && !nodoId.contains('-') ? [nodoId] : const [],
          subtemaIds: nodoId != null && nodoId.contains('-')
              ? [nodoId]
              : const [],
          cantidadPreguntas: cantidad,
          origen: gratis ? QuestionSource.todas : _origen,
        ),
      );

      // Hay una sesión abierta nueva: el inicio tiene que poder ofrecerla.
      ref.invalidate(sesionesAbiertasProvider);
      // Empieza: el mismo sonido que en Rumbo al abrir un quiz.
      ref.sonar(Sonido.empiezaQuiz);

      if (mounted) context.pushReplacement(Routes.practiceSessionOf(session.id));
    } on ForbiddenFailure catch (e) {
      // RN-03: el servidor es el que decide. Es también el caso de la prueba
      // que vence justo aquí — empezar una práctica es lo que arranca el reloj
      // (D-02), así que este 403 es el desenlace normal del modelo, no un
      // error raro.
      //
      // En gratis llega `LIMITE_DIARIO` o, si se eligió área u origen,
      // `FUNCION_PREMIUM`: los dos son el muro, no un error.
      if (!mounted) return;
      if (!atenderFaltaDeAcceso(context, ref, e)) {
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
                    fontSize: 13,
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
  const _SelectorNodo({required this.onElegir, this.nodo, this.ruta});

  final CatalogNode? nodo;
  final List<CatalogNode>? ruta;
  final VoidCallback onElegir;

  @override
  Widget build(BuildContext context) {
    final sinNodo = nodo == null;
    final migas = ruta != null && ruta!.length > 1
        ? ruta!.take(ruta!.length - 1).map((n) => n.nombre).join(' › ')
        : null;

    return Card(
      child: InkWell(
        onTap: onElegir,
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
                        style: context.texts.bodySmall?.copyWith(fontSize: 13),
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

/// El rango de RF-12, sin más recortes.
///
/// Tenía una marca del "tope de hoy" para el cupo del plan gratuito. Con la v2
/// no hay cupo: o tienes acceso y practicas lo que quieras, o no llegas a esta
/// pantalla.
class _SliderCantidad extends StatelessWidget {
  const _SliderCantidad({
    required this.valor,
    required this.tope,
    required this.onChanged,
  });

  final double valor;
  final int tope;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    const min = Blueprint.practiceMinQuestions;
    const max = Blueprint.practiceMaxQuestions;

    return Column(
      children: [
        Slider(
          value: valor.clamp(min.toDouble(), tope.toDouble()),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          label: '${valor.round()}',
          onChanged: onChanged,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$min', style: context.texts.bodySmall),
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
    final scheme = context.scheme;

    // Segmentado propio y no `SegmentedButton`: ese mide cada segmento por su
    // texto, así que "Todas", "Nuevas" y "Falladas" salían de anchos distintos
    // y el grupo se veía torcido. Aquí cada opción ocupa exactamente un tercio.
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd + 2),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          for (final origen in QuestionSource.values)
            Expanded(
              child: _Segmento(
                label: origen.label,
                activo: origen == valor,
                onTap: () => onChanged(origen),
              ),
            ),
        ],
      ),
    );
  }
}

class _Segmento extends StatelessWidget {
  const _Segmento({
    required this.label,
    required this.activo,
    required this.onTap,
  });

  final String label;
  final bool activo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final radio = BorderRadius.circular(DesignTokens.radiusMd);

    return Semantics(
      button: true,
      selected: activo,
      child: Material(
        color: activo ? scheme.primary : Colors.transparent,
        borderRadius: radio,
        child: InkWell(
          onTap: onTap,
          borderRadius: radio,
          child: Container(
            height: 40,
            alignment: Alignment.center,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.texts.bodyMedium?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: activo ? scheme.onPrimary : scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Lo que pesa en el ENAM y lo que ya viste. No cuántas preguntas tiene el
/// banco: eso no se muestra en ninguna pantalla (pedido del usuario,
/// 06/10/2026).
class _Resumen extends StatelessWidget {
  const _Resumen({required this.nodo});

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
              if (nodo.peso case final peso? when peso > 0) ...[
                _Fila(
                  etiqueta: 'En el ENAM',
                  valor: '$peso de ${Blueprint.totalQuestions} preguntas',
                ),
                const SizedBox(height: DesignTokens.space1 + 2),
              ],
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
    required this.etiqueta,
    required this.creando,
    required this.onEmpezar,
    this.icono = Symbols.play_arrow,
  });

  final String etiqueta;
  final IconData icono;
  final bool creando;
  final VoidCallback onEmpezar;

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
        label: etiqueta,
        icon: icono,
        loading: creando,
        onPressed: onEmpezar,
      ),
    );
  }
}

/// Una opción que en gratis no se elige: se ve con su candado, y tocarla
/// abre el muro con la vista previa.
class _FilaPremium extends StatelessWidget {
  const _FilaPremium({
    required this.icono,
    required this.texto,
    required this.onTap,
  });

  final IconData icono;
  final String texto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.space4),
          child: Row(
            children: [
              Icon(icono, size: 24, color: context.states.info.onTint),
              const SizedBox(width: DesignTokens.space3),
              Expanded(
                child: Text(
                  texto,
                  style: context.texts.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: DesignTokens.space2),
              const EtiquetaPremium(),
            ],
          ),
        ),
      ),
    );
  }
}
