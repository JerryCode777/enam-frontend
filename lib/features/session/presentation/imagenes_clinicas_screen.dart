import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/domain/blueprint.dart';
import '../../../core/error/failure.dart';
import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/sonido/proveedor_sonidos.dart';
import '../../../core/sonido/sonidos.dart';
import '../../../core/theme/area_colors.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/state_colors.dart';
import '../../../shared/widgets/enam_button.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../../shared/widgets/state_banner.dart';
import '../../catalog/domain/catalog_models.dart';
import '../../catalog/presentation/catalog_providers.dart';
import '../../subscription/domain/acceso.dart';
import '../../subscription/presentation/muro_de_venta_screen.dart';
import '../../subscription/presentation/widgets/etiqueta_premium.dart';
import '../domain/session_models.dart';

/// «Imágenes clínicas»: práctica solo con preguntas que traen un ECG, una
/// radiografía o una foto clínica (`conImagen: true`).
///
/// Es una sección aparte y no un filtro de «Practicar» porque el ENAM no trae
/// imágenes: el servidor tampoco las mezcla en la práctica normal, el
/// simulacro ni los paquetes offline. Aquí sí se dice cuántas hay —en el resto
/// de la app el tamaño del banco no se muestra—, porque es lo que se elige.
///
/// Los límites son los de siempre: en gratis entra en el cupo del día y elegir
/// área o tema es Premium (el servidor responde `FUNCION_PREMIUM`).
class ImagenesClinicasScreen extends ConsumerStatefulWidget {
  const ImagenesClinicasScreen({super.key});

  @override
  ConsumerState<ImagenesClinicasScreen> createState() =>
      _ImagenesClinicasScreenState();
}

class _ImagenesClinicasScreenState
    extends ConsumerState<ImagenesClinicasScreen> {
  /// El área o tema elegido; `null` es todo el temario.
  CatalogNode? _nodo;
  int _cantidad = 20;
  bool _creando = false;

  @override
  Widget build(BuildContext context) {
    final catalogo = ref.watch(catalogProvider);
    final gratis = ref.watch(cupoGratisProvider);

    return Scaffold(
      body: Column(
        children: [
          const GradientHeader(titulo: 'Imágenes clínicas'),
          Expanded(
            child: catalogo.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Padding(
                padding: const EdgeInsets.all(DesignTokens.space4),
                child: StateBanner(
                  kind: BannerKind.error,
                  message: 'No pudimos cargar las preguntas con imagen.',
                  action: TextButton(
                    onPressed: () => ref.invalidate(catalogProvider),
                    child: const Text('Reintentar'),
                  ),
                ),
              ),
              data: (areas) => _contenido(areas, gratis),
            ),
          ),
          if (catalogo.value case final areas?) _barra(areas, gratis),
        ],
      ),
    );
  }

  Widget _contenido(List<CatalogNode> areas, AccesoGratis? gratis) {
    final total = totalConImagen(areas);
    final conImagen = [
      for (final a in areas)
        if (a.preguntasConImagen > 0) a,
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.space5,
        DesignTokens.space4,
        DesignTokens.space5,
        DesignTokens.space8,
      ),
      children: [
        _Presentacion(total: total),
        if (total == 0) ...[
          const SizedBox(height: DesignTokens.space4),
          const StateBanner(
            message:
                'Todavía no hay preguntas con imagen. Estamos cargando las '
                'primeras.',
          ),
        ] else ...[
          const SizedBox(height: DesignTokens.space5),
          const _Titulo('QUÉ VAS A PRACTICAR'),
          const SizedBox(height: DesignTokens.space2 + 2),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _Opcion(
                  titulo: 'Todas las áreas',
                  cantidad: total,
                  elegida: _nodo == null,
                  onTap: () => setState(() => _nodo = null),
                ),
                for (final area in conImagen) ...[
                  const Divider(height: 1),
                  _Area(
                    area: area,
                    elegido: _nodo,
                    bloqueada: gratis != null,
                    onElegir: (n) => gratis != null
                        ? _aPremium()
                        : setState(() => _nodo = n),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.space5),
          const _Titulo('CANTIDAD'),
          const SizedBox(height: DesignTokens.space2 + 2),
          if (gratis != null)
            Text(
              gratis.agotado
                  ? 'Ya usaste tus ${gratis.preguntasPorDia} preguntas gratis '
                        'de hoy. Mañana tienes ${gratis.preguntasPorDia} más.'
                  : 'Entran en tus ${gratis.preguntasPorDia} preguntas gratis '
                        'del día. Te quedan ${gratis.restantesHoy} hoy.',
              style: context.texts.bodyMedium?.copyWith(height: 1.5),
            )
          else
            _Cantidad(
              valor: _cantidadEfectiva(_disponibles(total)),
              disponibles: _disponibles(total),
              onChanged: (v) => setState(() => _cantidad = v),
            ),
        ],
      ],
    );
  }

  Widget _barra(List<CatalogNode> areas, AccesoGratis? gratis) {
    final total = totalConImagen(areas);
    if (total == 0) return const SizedBox.shrink();

    if (gratis case final g? when g.agotado) {
      return _Barra(
        etiqueta: 'Ver Premium',
        icono: Symbols.workspace_premium,
        creando: false,
        onTap: () => abrirMuro(context, ref, const CupoAgotado()),
      );
    }
    final cantidad = gratis != null
        ? gratis.restantesHoy.clamp(0, gratis.preguntasPorDia).clamp(0, total)
        : _cantidadEfectiva(_disponibles(total));
    return _Barra(
      etiqueta: 'Empezar · $cantidad ${cantidad == 1 ? "pregunta" : "preguntas"}',
      icono: Symbols.play_arrow,
      creando: _creando,
      onTap: () => _empezar(cantidad, gratis: gratis != null),
    );
  }

  int _disponibles(int total) => _nodo?.preguntasConImagen ?? total;

  /// Lo elegido en el rango de RF-12, sin pasar de lo que hay.
  int _cantidadEfectiva(int disponibles) => _cantidad
      .clamp(Blueprint.practiceMinQuestions, Blueprint.practiceMaxQuestions)
      .clamp(1, disponibles < 1 ? 1 : disponibles);

  void _aPremium() => abrirMuro(
    context,
    ref,
    const FuncionDePago(FuncionPremium.practicaAMedida),
  );

  Future<void> _empezar(int cantidad, {required bool gratis}) async {
    if (_creando) return;
    setState(() => _creando = true);

    try {
      final nodo = gratis ? null : _nodo;
      final sesion = await ref
          .read(sessionRepositoryProvider)
          .startPractice(
            PracticeConfig(
              // Como en «Practicar»: un área va en `areaIds`, una sub área o un
              // tema en `subtemaIds`.
              areaIds: nodo != null && nodo.nivel == 'area'
                  ? [nodo.id]
                  : const [],
              subtemaIds: nodo != null && nodo.nivel != 'area'
                  ? [nodo.id]
                  : const [],
              cantidadPreguntas: cantidad,
              conImagen: true,
            ),
          );

      ref.invalidate(sesionesAbiertasProvider);
      ref.sonar(Sonido.empiezaQuiz);
      if (mounted) context.pushReplacement(Routes.practiceSessionOf(sesion.id));
    } on ForbiddenFailure catch (e) {
      // `LIMITE_DIARIO` o `FUNCION_PREMIUM`: el muro, no un error.
      if (!mounted) return;
      if (!atenderFaltaDeAcceso(context, ref, e)) {
        showErrorSnack(context, e.message);
      }
    } on Failure catch (e) {
      // `SIN_PREGUNTAS_CON_IMAGEN` trae su propio mensaje.
      if (mounted) showErrorSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _creando = false);
    }
  }
}

class _Presentacion extends StatelessWidget {
  const _Presentacion({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    final info = context.states.info;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: info.tint,
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              ),
              child: Icon(Symbols.image, size: 24, fill: 1, color: info.onTint),
            ),
            const SizedBox(width: DesignTokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    total == 1
                        ? '1 pregunta con imagen'
                        : '$total preguntas con imagen',
                    style: context.texts.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.space1),
                  Text(
                    'ECG, radiografías y fotos clínicas para entrenar el ojo. '
                    'El ENAM no trae imágenes: esta práctica va aparte.',
                    style: context.texts.bodyMedium?.copyWith(height: 1.45),
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

class _Titulo extends StatelessWidget {
  const _Titulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: context.texts.bodySmall?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
        color: context.scheme.onSurfaceVariant,
      ),
    );
  }
}

/// Un área con su cifra; se despliega en sus sub áreas con imágenes.
class _Area extends StatelessWidget {
  const _Area({
    required this.area,
    required this.elegido,
    required this.bloqueada,
    required this.onElegir,
  });

  final CatalogNode area;
  final CatalogNode? elegido;

  /// En gratis: se ve con su cifra y su etiqueta, y tocarla abre el muro.
  final bool bloqueada;
  final ValueChanged<CatalogNode> onElegir;

  @override
  Widget build(BuildContext context) {
    final hijos = [
      for (final h in area.hijos)
        if (h.preguntasConImagen > 0) h,
    ];
    final color = AreaColors.of(area.id, Theme.of(context).brightness);
    final dentro = elegido != null && AreaColors.rootOf(elegido!.id) == area.id;

    if (hijos.isEmpty || bloqueada) {
      return _Opcion(
        titulo: area.nombre,
        cantidad: area.preguntasConImagen,
        color: color,
        elegida: elegido?.id == area.id,
        bloqueada: bloqueada,
        onTap: () => onElegir(area),
      );
    }

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: dentro,
        tilePadding: const EdgeInsets.only(
          left: DesignTokens.space4,
          right: DesignTokens.space3,
        ),
        childrenPadding: const EdgeInsets.only(left: DesignTokens.space4),
        title: Row(
          children: [
            _Barrita(color: color),
            const SizedBox(width: DesignTokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    area.nombre,
                    style: context.texts.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    _cifra(area.preguntasConImagen),
                    style: context.texts.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        children: [
          _Opcion(
            titulo: 'Toda el área',
            cantidad: area.preguntasConImagen,
            elegida: elegido?.id == area.id,
            onTap: () => onElegir(area),
          ),
          for (final h in hijos)
            _Opcion(
              titulo: h.nombre,
              cantidad: h.preguntasConImagen,
              elegida: elegido?.id == h.id,
              onTap: () => onElegir(h),
            ),
        ],
      ),
    );
  }
}

class _Opcion extends StatelessWidget {
  const _Opcion({
    required this.titulo,
    required this.cantidad,
    required this.elegida,
    required this.onTap,
    this.color,
    this.bloqueada = false,
  });

  final String titulo;
  final int cantidad;
  final bool elegida;
  final VoidCallback onTap;

  /// El del área, para la barrita de la izquierda.
  final Color? color;
  final bool bloqueada;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Semantics(
      selected: elegida,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space4,
            vertical: DesignTokens.space3,
          ),
          child: Row(
            children: [
              if (color case final c?) ...[
                _Barrita(color: c),
                const SizedBox(width: DesignTokens.space3),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: context.texts.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(_cifra(cantidad), style: context.texts.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: DesignTokens.space2),
              if (bloqueada)
                const EtiquetaPremium()
              else
                Icon(
                  elegida
                      ? Symbols.radio_button_checked
                      : Symbols.radio_button_unchecked,
                  size: 22,
                  fill: elegida ? 1 : 0,
                  color: elegida ? scheme.primary : scheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Barrita extends StatelessWidget {
  const _Barrita({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      height: 34,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _Cantidad extends StatelessWidget {
  const _Cantidad({
    required this.valor,
    required this.disponibles,
    required this.onChanged,
  });

  final int valor;
  final int disponibles;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const min = Blueprint.practiceMinQuestions;
    final max = disponibles.clamp(1, Blueprint.practiceMaxQuestions);

    // Menos que el mínimo de RF-12: no hay nada que elegir, son todas.
    if (max <= min) {
      return Text(
        max == 1 ? 'Hay 1 pregunta aquí.' : 'Son las $max preguntas de aquí.',
        style: context.texts.bodyMedium,
      );
    }
    return Column(
      children: [
        Slider(
          value: valor.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          label: '$valor',
          onChanged: (v) => onChanged(v.round()),
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

class _Barra extends StatelessWidget {
  const _Barra({
    required this.etiqueta,
    required this.icono,
    required this.creando,
    required this.onTap,
  });

  final String etiqueta;
  final IconData icono;
  final bool creando;
  final VoidCallback onTap;

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
        onPressed: onTap,
      ),
    );
  }
}

String _cifra(int n) => n == 1 ? '1 con imagen' : '$n con imagen';
