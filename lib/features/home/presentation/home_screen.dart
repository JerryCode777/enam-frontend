import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/domain/blueprint.dart';
import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/motion.dart';
import '../../../core/theme/state_colors.dart';
import '../../../features/auth/domain/auth_models.dart';
import '../../../features/stats/domain/stats_models.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/state_banner.dart';

/// Pantalla 2.1 — inicio.
///
/// Estados que cubre, tomados de las anotaciones del diseño:
/// - Premium: desaparece la tarjeta de cuota diaria
/// - Día 1 sin datos: la nota proyectada muestra "—" con su explicación
/// - Cuota agotada: la barra pasa a advertencia y el CTA lleva al paywall
/// - Sin sesión pendiente: en vez de "Continuar" se sugiere por dónde empezar
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final stats = ref.watch(dashboardProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(dashboardProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.space5,
              DesignTokens.space3,
              DesignTokens.space5,
              DesignTokens.space6,
            ),
            children: [
              _Header(user: user),
              const SizedBox(height: DesignTokens.space4),
              stats.when(
                loading: () => const _LoadingBody(),
                error: (e, _) => _ErrorBody(
                  onRetry: () => ref.invalidate(dashboardProvider),
                ),
                data: (data) => _Body(stats: data),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    final states = context.states;
    final dias = user?.diasParaExamen;
    final fecha = user?.fechaObjetivo;
    final nombre = user?.nombre.split(' ').first ?? '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nombre.isEmpty ? 'Hola' : 'Hola, $nombre',
                style: context.texts.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                switch (dias) {
                  null => 'Tu preparación',
                  <= 0 => 'Hoy es el día',
                  1 => 'Falta 1 día',
                  _ => 'Faltan $dias días',
                },
                style: context.texts.titleLarge?.copyWith(
                  fontSize: DesignTokens.fontSizeXl + 2,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.22,
                ),
              ),
              if (fecha != null)
                Text(
                  DateFormat("'ENAM' · d MMM yyyy", 'es').format(fecha),
                  style: context.texts.bodySmall,
                ),
            ],
          ),
        ),
        const SizedBox(width: DesignTokens.space3),
        Semantics(
          label: 'Perfil y ajustes',
          button: true,
          child: InkWell(
            onTap: () => context.push(Routes.settings),
            borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
            child: Container(
              width: DesignTokens.minTouchTarget,
              height: DesignTokens.minTouchTarget,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: states.info.tint,
                shape: BoxShape.circle,
              ),
              child: Text(
                _initials(user?.nombre),
                style: context.texts.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: states.info.onTint,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static String _initials(String? nombre) {
    if (nombre == null || nombre.trim().isEmpty) return '·';
    final partes = nombre.trim().split(RegExp(r'\s+'));
    final letras = partes.take(2).map((p) => p[0].toUpperCase()).join();
    return letras;
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return StaggeredColumn(
      spacing: DesignTokens.space3 + 2,
      children: [
        _ProjectedGradeCard(stats: stats),
        const _ContinueCard(),
        _QuickActions(stats: stats),
        const _NationalMockCard(),
        if (stats.esFree) _FreeQuotaCard(stats: stats),
      ],
    );
  }
}

/// Nota proyectada (RN-04). El dato más importante de la pantalla.
class _ProjectedGradeCard extends StatelessWidget {
  const _ProjectedGradeCard({required this.stats});

  final DashboardStats stats;

  /// Con muy pocas respuestas la proyección es ruido, así que no se muestra.
  static const _minRespuestas = 50;

  @override
  Widget build(BuildContext context) {
    final states = context.states;
    final respondidas = stats.porArea.fold(0, (s, a) => s + a.respondidas);
    final hayDatos = respondidas >= _minRespuestas;
    final aprueba = Blueprint.isPassing(stats.notaProyectada);

    return Card(
      child: InkWell(
        onTap: () => context.push(Routes.stats),
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.space4),
          child: Row(
            children: [
              _GradeRing(
                nota: hayDatos ? stats.notaProyectada : null,
                color: hayDatos && !aprueba
                    ? states.warning.base
                    : context.scheme.primary,
              ),
              const SizedBox(width: DesignTokens.space3 + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Symbols.ecg_heart,
                          size: 17,
                          fill: 1,
                          color: states.info.onTint,
                        ),
                        const SizedBox(width: DesignTokens.space1 + 2),
                        Expanded(
                          child: Text(
                            'Nota proyectada',
                            style: context.texts.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: context.scheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: DesignTokens.space1),
                    Text(
                      hayDatos
                          // La advertencia de que es estimación es obligatoria.
                          ? 'Estimación sobre tu práctica y simulacros. '
                                'Se aprueba con 11.00.'
                          : 'Se calcula con tus primeras $_minRespuestas '
                                'respuestas.',
                      style: context.texts.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(
                Symbols.chevron_right,
                size: 22,
                color: context.scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradeRing extends StatelessWidget {
  const _GradeRing({required this.nota, required this.color});

  /// `null` cuando aún no hay datos suficientes.
  final double? nota;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final nota = this.nota;

    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: TweenAnimationBuilder<double>(
              // RN-01: la escala es sobre 20.
              tween: Tween(
                begin: 0,
                end: nota == null ? 0 : nota / Blueprint.maxGrade,
              ),
              duration: Motion.duration(context, Motion.counter),
              curve: Motion.enter,
              builder: (context, v, _) => CircularProgressIndicator(
                value: v,
                strokeWidth: 6,
                strokeCap: StrokeCap.round,
                backgroundColor: context.scheme.outlineVariant,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          if (nota == null)
            Text(
              '—',
              style: context.texts.bodyMedium?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: context.scheme.onSurface,
              ),
            )
          else
            // Siempre 2 decimales: la vigesimal se lee "12.40", no "12.4".
            AnimatedNumber(
              value: nota,
              style: context.texts.bodyMedium?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: context.scheme.onSurface,
              ),
            ),
        ],
      ),
    );
  }
}

/// Reanudar sesión (RF-15). Si no hay ninguna, sugiere por dónde empezar.
class _ContinueCard extends ConsumerWidget {
  const _ContinueCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final states = context.states;
    final sesion = ref.watch(resumableSessionProvider);
    final sesionPendiente = sesion != null;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.space4),
      decoration: BoxDecoration(
        color: states.info.tint,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg + 2),
      ),
      child: Row(
        children: [
          Icon(
            sesionPendiente ? Symbols.play_circle : Symbols.lightbulb,
            size: 26,
            fill: 1,
            color: states.info.onTint,
          ),
          const SizedBox(width: DesignTokens.space3 + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sesion?.titulo ?? 'Empieza por lo que más pesa',
                  style: context.texts.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: context.scheme.onSurface,
                  ),
                ),
                Text(
                  sesion?.detalle ?? 'Medicina son 40 de las 180 preguntas',
                  style: context.texts.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: DesignTokens.space2),
          FilledButton(
            onPressed: () => context.push(Routes.practiceConfig),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.space4 + 2,
              ),
            ),
            child: Text(sesionPendiente ? 'Seguir' : 'Practicar'),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final formato = NumberFormat.decimalPattern('es_PE');
    final cobertura = (stats.coberturaBanco * 100).round();

    final items = <_QuickAction>[
      _QuickAction(
        icon: Symbols.account_tree,
        titulo: 'Temario',
        detalle: '$cobertura % cubierto',
        ruta: Routes.temario,
      ),
      _QuickAction(
        icon: Symbols.timer,
        titulo: 'Simulacro',
        detalle: stats.evolucion.isEmpty
            ? 'Aún ninguno'
            : 'Último: ${stats.evolucion.last.nota.toStringAsFixed(2)}',
        ruta: Routes.simulacroSelection,
      ),
      const _QuickAction(
        icon: Symbols.bookmark,
        titulo: 'Marcadas',
        detalle: 'Para repasar',
        ruta: Routes.markedQuestions,
      ),
      _QuickAction(
        icon: Symbols.menu_book,
        titulo: 'Banco',
        detalle:
            '${formato.format(stats.preguntasVistas)} de '
            '${formato.format(stats.preguntasTotalesBanco)} vistas',
        ruta: Routes.stats,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // A 360 px las dos columnas dejan ~168 px por tarjeta: alcanza. Si el
        // usuario amplía la fuente, se pasa a una sola columna en vez de
        // recortar el texto.
        final unaColumna =
            constraints.maxWidth < 320 ||
            MediaQuery.textScalerOf(context).scale(14) > 19;

        // Sin `childAspectRatio`: las tarjetas se miden por su contenido. Una
        // relación de aspecto fija se desborda en cuanto crece la fuente del
        // sistema, y el alto correcto depende de cuántas líneas ocupe el texto.
        if (unaColumna) {
          return Column(
            children: [
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: DesignTokens.space2 + 2),
                  child: item,
                ),
            ],
          );
        }

        return Column(
          children: [
            for (var i = 0; i < items.length; i += 2)
              Padding(
                padding: const EdgeInsets.only(bottom: DesignTokens.space2 + 2),
                // IntrinsicHeight iguala el alto de las dos tarjetas de la fila
                // sin fijarlo: la más alta manda.
                child: IntrinsicHeight(
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

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.titulo,
    required this.detalle,
    required this.ruta,
  });

  final IconData icon;
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
              Icon(icon, size: 22, color: context.states.info.onTint),
              const SizedBox(width: DesignTokens.space2 + 2),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: context.texts.bodyMedium?.copyWith(
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

class _NationalMockCard extends StatelessWidget {
  const _NationalMockCard();

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
            Icon(Symbols.campaign, size: 22, color: states.warning.onTint),
            const SizedBox(width: DesignTokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Simulacro Nacional · dom 16 ago, 8:00 a.m.',
                    style: context.texts.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: context.scheme.onSurface,
                    ),
                  ),
                  Text('1,847 inscritos', style: context.texts.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: DesignTokens.space2),
            OutlinedButton(
              onPressed: () => context.push(Routes.nationalMock),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.space3 + 2,
                ),
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
class _FreeQuotaCard extends StatelessWidget {
  const _FreeQuotaCard({required this.stats});

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
                  agotada ? 'Sin cupos hoy' : '$restantes de $limite disponibles',
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

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 4; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: DesignTokens.space3 + 2),
            child: SkeletonBox(
              height: i == 0 ? 96 : 72,
              radius: DesignTokens.radiusLg,
            ),
          ),
      ],
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        StateBanner(
          kind: BannerKind.error,
          message: 'No pudimos cargar tu progreso.',
          action: TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ),
      ],
    );
  }
}
