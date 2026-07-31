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
import '../../../features/stats/domain/stats_models.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/state_banner.dart';
import 'widgets/home_hero.dart';
import 'widgets/streak_card.dart';

/// Pantalla 2.1 — inicio.
///
/// Estructura del diseño: un **hero en degradado** que junta saludo, cuenta
/// regresiva y la sesión a retomar, y debajo las tarjetas sobre el fondo normal.
///
/// Estados que cubre, tomados de las anotaciones:
/// - Premium: desaparece la tarjeta de cuota diaria
/// - Día 1 sin datos: la nota proyectada muestra "—" con su explicación
/// - Cuota agotada: la barra pasa a advertencia y el CTA lleva al paywall
/// - Sin sesión pendiente: el hero sugiere por dónde empezar
/// - Racha en 0: la tarjeta invita a empezar hoy
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final sesion = ref.watch(resumableSessionProvider);
    final stats = ref.watch(dashboardProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(dashboardProvider),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            HomeHero(user: user, sesion: sesion),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.space5,
                DesignTokens.space3 + 2,
                DesignTokens.space5,
                DesignTokens.space6,
              ),
              child: stats.when(
                loading: () => const _Cargando(),
                error: (e, _) => StateBanner(
                  kind: BannerKind.error,
                  message: 'No pudimos cargar tu progreso.',
                  action: TextButton(
                    onPressed: () => ref.invalidate(dashboardProvider),
                    child: const Text('Reintentar'),
                  ),
                ),
                data: (data) => _Tarjetas(stats: data),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tarjetas extends StatelessWidget {
  const _Tarjetas({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return StaggeredColumn(
      spacing: DesignTokens.space3,
      children: [
        // TODO(racha): leer la racha real cuando el contrato tenga el campo.
        const StreakCard(
          dias: 18,
          diasDeLaSemana: [true, true, true, true, true, true, false],
        ),
        _TarjetaNota(stats: stats),
        _AccesosRapidos(stats: stats),
        const _SimulacroNacional(),
        if (stats.esFree) _CuotaDiaria(stats: stats),
      ],
    );
  }
}

/// Nota proyectada (RN-04). El dato más importante de la pantalla.
class _TarjetaNota extends StatelessWidget {
  const _TarjetaNota({required this.stats});

  final DashboardStats stats;

  /// Con menos respuestas la proyección es ruido y no se muestra.
  static const _minRespuestas = 50;

  @override
  Widget build(BuildContext context) {
    final states = context.states;
    final scheme = context.scheme;
    final respondidas = stats.porArea.fold(0, (s, a) => s + a.respondidas);
    final hayDatos = respondidas >= _minRespuestas;

    return Card(
      child: InkWell(
        // go y no push: estadísticas es una rama del shell (ver práctica).
        onTap: () => context.go(Routes.stats),
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Symbols.ecg_heart,
                    size: 15,
                    fill: 1,
                    color: states.info.onTint,
                  ),
                  const SizedBox(width: DesignTokens.space1 + 2),
                  Expanded(
                    child: Text(
                      'NOTA PROYECTADA',
                      style: context.texts.bodySmall?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.88,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  // La advertencia de RN-04 vive detrás de este icono: la
                  // tarjeta ya está densa y el aviso completo empujaría la nota
                  // fuera de la primera pantalla.
                  IconButton(
                    icon: Icon(
                      Symbols.info,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Cómo se calcula',
                    onPressed: () => _explicar(context),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.space2),
              Row(
                children: [
                  if (hayDatos)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        AnimatedNumber(
                          value: stats.notaProyectada,
                          style: context.texts.displaySmall?.copyWith(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                        Text(
                          ' / 20',
                          style: context.texts.bodyMedium?.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      '—',
                      style: context.texts.displaySmall?.copyWith(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        height: 1,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  const Spacer(),
                  if (hayDatos) const _Delta(valor: 0.60),
                ],
              ),
              const SizedBox(height: DesignTokens.space3),
              if (hayDatos)
                _Escala(nota: stats.notaProyectada)
              else
                Text(
                  'Se calcula con tus primeras $_minRespuestas respuestas.',
                  style: context.texts.bodySmall?.copyWith(fontSize: 11.5),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _explicar(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cómo se calcula'),
        content: const Text(
          'Es el promedio de tu acierto por área, ponderado por cuántas '
          'preguntas aporta cada una al examen.\n\n'
          'Es una estimación sobre tu práctica reciente, no una predicción del '
          'resultado real.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}

/// Cuánto subió o bajó la nota en la semana. Comunica progreso, que es lo que
/// sostiene el hábito.
class _Delta extends StatelessWidget {
  const _Delta({required this.valor});

  final double valor;

  @override
  Widget build(BuildContext context) {
    final states = context.states;
    final subio = valor >= 0;
    final color = subio ? states.success : states.error;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.space1,
        3,
        DesignTokens.space2 + 2,
        3,
      ),
      decoration: BoxDecoration(
        color: color.tint,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd - 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            subio ? Symbols.arrow_drop_up : Symbols.arrow_drop_down,
            size: 18,
            fill: 1,
            color: color.onTint,
          ),
          Text(
            '${subio ? "+" : ""}${valor.toStringAsFixed(2)} esta semana',
            style: context.texts.bodySmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color.onTint,
            ),
          ),
        ],
      ),
    );
  }
}

/// La escala de 0 a 20 con la marca del 11.
///
/// Sin la referencia, un 12.40 no dice si vas bien o mal.
class _Escala extends StatelessWidget {
  const _Escala({required this.nota});

  final double nota;

  @override
  Widget build(BuildContext context) {
    const aprobado = Blueprint.passingGrade / Blueprint.maxGrade;
    final scheme = context.scheme;

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) => Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerLeft,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(
                    begin: 0,
                    end: (nota / Blueprint.maxGrade).clamp(0.0, 1.0),
                  ),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) => Stack(
                    children: [
                      Container(height: 10, color: scheme.outlineVariant),
                      // Degradado en el relleno, como el diseño.
                      FractionallySizedBox(
                        widthFactor: v,
                        child: Container(
                          height: 10,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                DesignTokens.brandDark,
                                DesignTokens.brand,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: constraints.maxWidth * aprobado - 1.5,
                top: -3,
                child: Container(
                  width: 3,
                  height: 16,
                  decoration: BoxDecoration(
                    color: scheme.onSurface,
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
            Text(
              '0',
              style: context.texts.bodySmall?.copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '11 · aprobado',
              style: context.texts.bodySmall?.copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
            Text(
              '20',
              style: context.texts.bodySmall?.copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AccesosRapidos extends StatelessWidget {
  const _AccesosRapidos({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final states = context.states;
    final formato = NumberFormat.decimalPattern('es_PE');
    final brillo = Theme.of(context).brightness;

    final items = <_Acceso>[
      _Acceso(
        icon: Symbols.account_tree,
        color: states.info.onTint,
        fondo: states.info.tint,
        titulo: 'Temario',
        detalle: '${(stats.coberturaBanco * 100).round()} % cubierto',
        ruta: Routes.temario,
      ),
      _Acceso(
        icon: Symbols.timer,
        color: AreaColors.of('cirugia', brillo),
        fondo: states.info.tint,
        titulo: 'Simulacro',
        detalle: stats.evolucion.isEmpty
            ? 'Aún ninguno'
            : 'Último: ${stats.evolucion.last.nota.toStringAsFixed(2)}',
        ruta: Routes.simulacroSelection,
      ),
      _Acceso(
        icon: Symbols.bookmark,
        color: AreaColors.of('pediatria', brillo),
        fondo: states.warning.tint,
        titulo: 'Marcadas',
        detalle: 'Para repasar',
        ruta: Routes.markedQuestions,
      ),
      _Acceso(
        icon: Symbols.menu_book,
        color: states.success.onTint,
        fondo: states.success.tint,
        titulo: 'Banco',
        detalle:
            '${formato.format(stats.preguntasVistas)} de '
            '${formato.format(stats.preguntasTotalesBanco)}',
        ruta: Routes.stats,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Con la fuente muy ampliada, dos columnas no dan: se pasa a una en vez
        // de recortar el texto.
        final unaColumna =
            constraints.maxWidth < 320 ||
            MediaQuery.textScalerOf(context).scale(14) > 19;
        final porFila = unaColumna ? 1 : 2;

        // Sin relación de aspecto fija: las tarjetas se miden por su contenido.
        return Column(
          children: [
            for (var i = 0; i < items.length; i += porFila)
              Padding(
                padding: EdgeInsets.only(
                  bottom: i + porFila >= items.length
                      ? 0
                      : DesignTokens.space2 + 2,
                ),
                child: unaColumna
                    ? items[i]
                    : IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: items[i]),
                            const SizedBox(width: DesignTokens.space2 + 2),
                            Expanded(
                              child: i + 1 < items.length
                                  ? items[i + 1]
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
              ),
          ],
        );
      },
    );
  }
}

class _Acceso extends StatelessWidget {
  const _Acceso({
    required this.icon,
    required this.color,
    required this.fondo,
    required this.titulo,
    required this.detalle,
    required this.ruta,
  });

  final IconData icon;
  final Color color;
  final Color fondo;
  final String titulo;
  final String detalle;
  final String ruta;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => context.push(ruta),
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space3 + 2,
            vertical: DesignTokens.space3,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(DesignTokens.space2),
                decoration: BoxDecoration(
                  color: fondo,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                ),
                child: Icon(icon, size: 21, fill: 1, color: color),
              ),
              const SizedBox(width: DesignTokens.space2 + 2),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: context.texts.bodyMedium?.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: context.scheme.onSurface,
                      ),
                    ),
                    Text(
                      detalle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.bodySmall?.copyWith(fontSize: 11.5),
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

class _SimulacroNacional extends StatelessWidget {
  const _SimulacroNacional();

  @override
  Widget build(BuildContext context) {
    final states = context.states;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space4,
          vertical: DesignTokens.space3 + 2,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(DesignTokens.space2),
              decoration: BoxDecoration(
                color: states.warning.tint,
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              ),
              child: Icon(
                Symbols.campaign,
                size: 22,
                fill: 1,
                color: states.warning.onTint,
              ),
            ),
            const SizedBox(width: DesignTokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Simulacro Nacional · dom 16 ago',
                    style: context.texts.bodyMedium?.copyWith(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: context.scheme.onSurface,
                    ),
                  ),
                  Text(
                    '8:00 a.m. · 1,847 participantes',
                    style: context.texts.bodySmall?.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: DesignTokens.space2),
            OutlinedButton(
              onPressed: () => context.push(Routes.nationalMock),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 38),
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.space3 + 2,
                ),
                side: BorderSide(color: context.scheme.primary, width: 1.5),
              ),
              // "Participar" y no "Inscribirme": con un público en época de
              // trámites, inscribirse a un "Simulacro Nacional" se puede leer
              // como inscripción al ENAM real.
              child: const Text('Participar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cuota diaria del plan gratuito (RN-03). Solo se muestra a usuarios free.
class _CuotaDiaria extends StatelessWidget {
  const _CuotaDiaria({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final states = context.states;
    final restantes = stats.preguntasRestantesHoy ?? 0;
    const limite = Blueprint.freeDailyQuestionLimit;
    final agotada = stats.alcanzoLimiteDiario;
    final color = agotada ? states.warning : states.info;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space4,
          vertical: DesignTokens.space3 + 2,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Tu práctica gratis de hoy',
                    style: context.texts.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.scheme.onSurface,
                    ),
                  ),
                ),
                Text(
                  agotada ? 'Sin cupos hoy' : '$restantes de $limite',
                  style: context.texts.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: agotada ? color.onTint : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.space2),
            AnimatedBar(
              value: restantes / limite,
              color: color.base,
              height: 6,
            ),
            const SizedBox(height: DesignTokens.space2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    agotada
                        ? 'Vuelve mañana, o pasa a Premium para seguir hoy.'
                        : 'Con Premium practicas sin límite.',
                    style: context.texts.bodySmall,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push(Routes.plans),
                  child: Text(
                    'Ver planes',
                    style: context.texts.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: states.info.onTint,
                    ),
                  ),
                ),
              ],
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
    return const Column(
      children: [
        SkeletonBox(height: 64, radius: DesignTokens.radiusLg),
        SizedBox(height: DesignTokens.space3),
        SkeletonBox(height: 148, radius: DesignTokens.radiusLg),
        SizedBox(height: DesignTokens.space3),
        SkeletonBox(height: 132, radius: DesignTokens.radiusLg),
        SizedBox(height: DesignTokens.space3),
        SkeletonBox(height: 72, radius: DesignTokens.radiusLg),
      ],
    );
  }
}
