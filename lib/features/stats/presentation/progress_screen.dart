import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/domain/blueprint.dart';
import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/area_colors.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/state_colors.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../../shared/widgets/state_banner.dart';
import '../../catalog/domain/catalog_models.dart';
import '../../catalog/presentation/catalog_providers.dart';
import '../domain/stats_models.dart';

/// Pantalla 6.1 — dashboard de progreso (RF-21, RN-04).
///
/// El gráfico por área usa **doble codificación**: el ancho de la pista es el
/// peso del área en el examen y el relleno es el acierto. Un 44 % en Emergencias
/// (16 preguntas) se ve pequeño pero rojo; importa, y el texto lo dice sin
/// depender del color.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardProvider);

    return Scaffold(
      body: Column(
        children: [
          const GradientHeader(
            titulo: 'Tu progreso',
            mostrarVolver: false,
          ),
          Expanded(
            child: stats.when(
              loading: () => const _Cargando(),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(DesignTokens.space4),
                  child: StateBanner(
                    kind: BannerKind.error,
                    message: 'No pudimos cargar tu progreso.',
                    action: TextButton(
                      onPressed: () => ref.invalidate(dashboardProvider),
                      child: const Text('Reintentar'),
                    ),
                  ),
                ),
              ),
              data: (data) => RefreshIndicator(
                onRefresh: () async => ref.invalidate(dashboardProvider),
                child: _Contenido(stats: data),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Contenido extends ConsumerWidget {
  const _Contenido({required this.stats});

  final DashboardStats stats;

  /// Con menos de esto la proyección es ruido y no se muestra.
  static const _minRespuestas = 50;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final respondidas = stats.porArea.fold(0, (s, a) => s + a.respondidas);
    final hayDatos = respondidas >= _minRespuestas;
    final prioridades = ref.watch(prioridadEstudioProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.space4,
        DesignTokens.space4,
        DesignTokens.space4,
        DesignTokens.space8,
      ),
      children: [
        _TarjetaNota(stats: stats, hayDatos: hayDatos),
        const SizedBox(height: DesignTokens.space3 + 2),
        _Cifras(stats: stats, respondidas: respondidas),
        const SizedBox(height: DesignTokens.space3 + 2),
        const _AccesosDirectos(),
        if (prioridades.isNotEmpty) ...[
          const SizedBox(height: DesignTokens.space3 + 2),
          _Sugerencia(area: prioridades.first.area),
        ],
        const SizedBox(height: DesignTokens.space5),
        _PorArea(porArea: stats.porArea),
        if (stats.evolucion.length > 1) ...[
          const SizedBox(height: DesignTokens.space5),
          _Evolucion(puntos: stats.evolucion),
        ],
      ],
    );
  }
}

class _TarjetaNota extends StatelessWidget {
  const _TarjetaNota({required this.stats, required this.hayDatos});

  final DashboardStats stats;
  final bool hayDatos;

  @override
  Widget build(BuildContext context) {
    final states = context.states;
    final aprueba = Blueprint.isPassing(stats.notaProyectada);
    final color = aprueba ? states.success : states.warning;

    return FadeUp(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.space4 + 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'NOTA PROYECTADA',
                style: context.texts.bodySmall?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: context.scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: DesignTokens.space2),
              if (hayDatos)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    AnimatedNumber(
                      value: stats.notaProyectada,
                      style: context.texts.displaySmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    Text(
                      ' / 20',
                      style: context.texts.titleMedium?.copyWith(
                        color: context.scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                )
              else
                Text(
                  '—',
                  style: context.texts.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: context.scheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: DesignTokens.space3),
              if (hayDatos) ...[
                _EscalaVigesimal(nota: stats.notaProyectada, color: color.base),
                const SizedBox(height: DesignTokens.space3),
              ],
              // La advertencia es obligatoria: es una estimación, no un
              // pronóstico del resultado real (RN-04).
              StateBanner(
                kind: hayDatos ? BannerKind.warning : BannerKind.info,
                message: hayDatos
                    ? 'Es una estimación sobre tu práctica reciente, no una '
                          'predicción del resultado real.'
                    : 'Se calcula con tus primeras '
                          '${_Contenido._minRespuestas} respuestas.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// La escala de 0 a 20 con la marca del 11. Sin la referencia, un 12.40 no dice
/// nada a quien no conoce la escala.
class _EscalaVigesimal extends StatelessWidget {
  const _EscalaVigesimal({required this.nota, required this.color});

  final double nota;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const aprobado = Blueprint.passingGrade / Blueprint.maxGrade;

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) => Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedBar(value: nota / Blueprint.maxGrade, color: color),
              Positioned(
                left: constraints.maxWidth * aprobado - 1.5,
                top: -3,
                child: Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    color: context.scheme.onSurface,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: DesignTokens.space2),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('0', style: context.texts.bodySmall),
            Text(
              '11 · aprobado',
              style: context.texts.bodySmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: context.scheme.onSurface,
              ),
            ),
            Text('20', style: context.texts.bodySmall),
          ],
        ),
      ],
    );
  }
}

class _Cifras extends StatelessWidget {
  const _Cifras({required this.stats, required this.respondidas});

  final DashboardStats stats;
  final int respondidas;

  @override
  Widget build(BuildContext context) {
    final formato = NumberFormat.decimalPattern('es_PE');
    final correctas = stats.porArea.fold(0, (s, a) => s + a.correctas);
    final acierto = respondidas == 0 ? null : correctas / respondidas;

    return FadeUp(
      index: 1,
      child: Row(
        children: [
          Expanded(
            child: _Cifra(
              valor: formato.format(stats.preguntasVistas),
              etiqueta: 'preguntas vistas',
            ),
          ),
          const SizedBox(width: DesignTokens.space2 + 2),
          Expanded(
            child: _Cifra(
              valor: acierto == null ? '—' : '${(acierto * 100).round()} %',
              etiqueta: 'acierto global',
            ),
          ),
          const SizedBox(width: DesignTokens.space2 + 2),
          Expanded(
            child: _Cifra(
              valor: '${stats.simulacrosCompletados}',
              etiqueta: 'simulacros',
            ),
          ),
        ],
      ),
    );
  }
}

class _Cifra extends StatelessWidget {
  const _Cifra({required this.valor, required this.etiqueta});

  final String valor;
  final String etiqueta;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space3 + 1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              valor,
              style: context.texts.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              etiqueta,
              maxLines: 2,
              style: context.texts.bodySmall?.copyWith(fontSize: 11.5),
            ),
          ],
        ),
      ),
    );
  }
}

/// Accesos a ranking, marcadas y descargas. Visibles arriba y no escondidos al
/// final del desplazamiento.
class _AccesosDirectos extends StatelessWidget {
  const _AccesosDirectos();

  @override
  Widget build(BuildContext context) {
    final accesos = <({IconData icon, String texto, String ruta})>[
      (icon: Symbols.trophy, texto: 'Ranking', ruta: Routes.ranking),
      (icon: Symbols.bookmark, texto: 'Marcadas', ruta: Routes.markedQuestions),
      (icon: Symbols.download, texto: 'Descargas', ruta: Routes.downloads),
    ];

    return FadeUp(
      index: 2,
      child: Row(
        children: [
          for (var i = 0; i < accesos.length; i++) ...[
            if (i > 0) const SizedBox(width: DesignTokens.space2 + 2),
            Expanded(
              child: Card(
                child: InkWell(
                  onTap: () => context.push(accesos[i].ruta),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: DesignTokens.space3 + 1,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          accesos[i].icon,
                          size: 22,
                          fill: 1,
                          color: context.states.info.onTint,
                        ),
                        const SizedBox(height: DesignTokens.space1 + 2),
                        Text(
                          accesos[i].texto,
                          style: context.texts.bodySmall?.copyWith(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Sugerencia extends StatelessWidget {
  const _Sugerencia({required this.area});

  final CatalogNode area;

  @override
  Widget build(BuildContext context) {
    final states = context.states;
    final nombre = area.nombre;
    final acierto = area.porcentajeAcierto;
    final peso = area.peso;

    return FadeUp(
      index: 3,
      child: InkWell(
        onTap: () => context.push(Routes.studyPriority),
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(DesignTokens.space4),
          decoration: BoxDecoration(
            color: states.info.tint,
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Symbols.bolt, size: 22, fill: 1, color: states.info.onTint),
              const SizedBox(width: DesignTokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        style: context.texts.bodySmall?.copyWith(
                          height: 1.5,
                          color: states.info.onTint,
                        ),
                        children: [
                          const TextSpan(
                            text: 'Dónde invertir tu tiempo: ',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          TextSpan(
                            text:
                                '$nombre pesa $peso preguntas y vas en '
                                '${acierto == null ? "sin datos" : "${(acierto * 100).round()} %"}. '
                                'Refuérzala primero.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space2),
                    Text(
                      'Ver el análisis completo',
                      style: context.texts.bodySmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: states.info.onTint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PorArea extends StatelessWidget {
  const _PorArea({required this.porArea});

  final List<AreaPerformance> porArea;

  @override
  Widget build(BuildContext context) {
    // Ordenado por peso: lo que más mueve la nota, primero.
    final ordenadas = [...porArea]
      ..sort((a, b) => b.preguntasBlueprint.compareTo(a.preguntasBlueprint));

    return FadeUp(
      index: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  'ACIERTO POR ÁREA VS SU PESO',
                  style: context.texts.bodySmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: context.scheme.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                'ancho = peso',
                style: context.texts.bodySmall?.copyWith(fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.space3),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(DesignTokens.space4),
              child: Column(
                children: [
                  for (var i = 0; i < ordenadas.length; i++)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: i == ordenadas.length - 1
                            ? 0
                            : DesignTokens.space3 + 1,
                      ),
                      child: _FilaArea(area: ordenadas[i]),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaArea extends StatelessWidget {
  const _FilaArea({required this.area});

  final AreaPerformance area;

  /// El área más grande del examen, para escalar el ancho de la pista.
  static const _pesoMaximo = 40;

  @override
  Widget build(BuildContext context) {
    final color = AreaColors.of(area.areaId, Theme.of(context).brightness);
    final acierto = area.porcentajeAcierto;
    final refuerza = acierto != null && acierto < 0.5;
    final anchoRelativo = (area.preguntasBlueprint / _pesoMaximo).clamp(
      0.18,
      1.0,
    );

    return InkWell(
      onTap: () => context.push(Routes.temarioAreaOf(area.areaId)),
      borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
      child: Column(
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
                  '${area.areaNombre} · ${area.preguntasBlueprint}',
                  style: context.texts.bodySmall?.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                acierto == null ? 'sin datos' : '${(acierto * 100).round()} %',
                style: context.texts.bodySmall?.copyWith(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: refuerza
                      ? context.states.warning.onTint
                      : context.scheme.onSurface,
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
          Row(
            children: [
              Expanded(
                flex: (anchoRelativo * 100).round(),
                child: AnimatedBar(value: acierto ?? 0, color: color, height: 8),
              ),
              if (anchoRelativo < 1)
                Expanded(
                  flex: ((1 - anchoRelativo) * 100).round(),
                  child: const SizedBox(),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Evolución de la nota en el tiempo (RF-21).
class _Evolucion extends StatelessWidget {
  const _Evolucion({required this.puntos});

  final List<GradePoint> puntos;

  @override
  Widget build(BuildContext context) {
    return FadeUp(
      index: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'EVOLUCIÓN DE TU NOTA',
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
                  SizedBox(
                    height: 120,
                    child: CustomPaint(
                      painter: _LineaPainter(
                        puntos: puntos,
                        color: context.scheme.primary,
                        referencia: context.scheme.outlineVariant,
                        aprobado: context.scheme.onSurfaceVariant,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.space2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('d MMM', 'es').format(puntos.first.fecha),
                        style: context.texts.bodySmall?.copyWith(fontSize: 11),
                      ),
                      Text(
                        // El último valor, que es el dato que se busca.
                        'última: ${puntos.last.nota.toStringAsFixed(2)}',
                        style: context.texts.bodySmall?.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: context.scheme.onSurface,
                        ),
                      ),
                      Text(
                        DateFormat('d MMM', 'es').format(puntos.last.fecha),
                        style: context.texts.bodySmall?.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineaPainter extends CustomPainter {
  const _LineaPainter({
    required this.puntos,
    required this.color,
    required this.referencia,
    required this.aprobado,
  });

  final List<GradePoint> puntos;
  final Color color;
  final Color referencia;
  final Color aprobado;

  @override
  void paint(Canvas canvas, Size size) {
    if (puntos.length < 2) return;

    // La escala arranca en 0 y llega a 20 para que la posición sea comparable
    // entre gráficos y no se exagere una mejora pequeña.
    double y(double nota) =>
        size.height - (nota / Blueprint.maxGrade) * size.height;
    double x(int i) => (i / (puntos.length - 1)) * size.width;

    // Línea del 11: sin ella no se ve si la tendencia cruza el aprobado.
    final yAprobado = y(Blueprint.passingGrade);
    final dashed = Paint()
      ..color = aprobado
      ..strokeWidth = 1;
    for (var dx = 0.0; dx < size.width; dx += 8) {
      canvas.drawLine(
        Offset(dx, yAprobado),
        Offset(dx + 4, yAprobado),
        dashed,
      );
    }

    final path = Path();
    for (var i = 0; i < puntos.length; i++) {
      final p = Offset(x(i), y(puntos[i].nota));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    for (var i = 0; i < puntos.length; i++) {
      canvas.drawCircle(
        Offset(x(i), y(puntos[i].nota)),
        i == puntos.length - 1 ? 5 : 3,
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_LineaPainter old) => old.puntos != puntos;
}

class _Cargando extends StatelessWidget {
  const _Cargando();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(DesignTokens.space4),
      children: [
        const SkeletonBox(height: 190, radius: DesignTokens.radiusLg),
        const SizedBox(height: DesignTokens.space3),
        const SkeletonBox(height: 72, radius: DesignTokens.radiusLg),
        const SizedBox(height: DesignTokens.space3),
        const SkeletonBox(height: 300, radius: DesignTokens.radiusLg),
      ],
    );
  }
}
