import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/domain/blueprint.dart';
import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../session/presentation/national_mock_screen.dart';
import '../../catalog/domain/catalog_models.dart';
import '../../catalog/presentation/catalog_providers.dart';
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
/// Responde en orden a "¿qué hago aquí?": retomar lo que dejaste (en el hero),
/// las dos acciones centrales de la app, tu resultado, la racha y los accesos
/// secundarios. La cuenta regresiva es apoyo del saludo, no compite.
///
/// Los tamaños de letra salen del diseño (`enam-01-auth-home.dc.html`) y son
/// **mínimos**: nada baja de 12, y si algo no cabe se recorta contenido o se
/// desplaza, nunca se achica la tipografía.
///
/// **Ya no lleva tarjeta de cuota diaria.** Contaba las 20 preguntas del plan
/// gratuito, que desapareció (SSD-ENAM-002 §1). Tampoco la reemplaza una cuenta
/// atrás de la prueba: RP-01 dice que los límites del plan nunca se anuncian, y
/// el Home es la pantalla que más se abre. Queda anotado como decisión abierta:
/// con 24 h de prueba, no avisar puede leerse como que se corta sin aviso.
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
                DesignTokens.space3,
                DesignTokens.space5,
                DesignTokens.space8,
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
      spacing: DesignTokens.space2 + 1,
      children: [
        // La racha va ARRIBA, pegada a las dos acciones. Es lo que empuja a
        // pulsarlas, y separada de ellas —estaba cuatro tarjetas más abajo, tras
        // la nota proyectada— empujaba a nada.
        //
        // Mismo orden que la web (`InicioScreen.tsx`): racha, acciones, cifras,
        // temario. Las dos pantallas comparten reglas y disposición; lo que
        // puede diferir es el ancho, no el orden.
        //
        // Sin racha en la respuesta no se pinta nada. El 18 que había escrito
        // aquí a mano no era de nadie, y un número que no se corresponde con lo
        // que la persona hizo es peor que no tener racha: premia por algo que
        // no pasó.
        if (stats.racha case final racha?)
          StreakCard(
            dias: racha.dias,
            diasDeLaSemana: racha.diasDeLaSemana,
            practicoHoy: racha.diasDeLaSemana.lastOrNull ?? false,
          ),
        const _EmpiezaAPracticar(),
        _Metricas(stats: stats),
        const _PorDondeSeguir(),
        _TarjetaNota(stats: stats),
        _AccesosRapidos(stats: stats),
        const _SimulacroNacional(),
      ],
    );
  }
}

/// Las dos formas de empezar: práctica libre y simulacro completo.
///
/// Van arriba de todo y más grandes que el resto de accesos porque son la
/// acción que la pantalla existe para provocar. En 360×640 tienen que quedar
/// visibles sin desplazar.
class _EmpiezaAPracticar extends StatelessWidget {
  const _EmpiezaAPracticar();

  /// Alto mínimo que pide el diseño para las dos tarjetas.
  static const _alto = 104.0;

  @override
  Widget build(BuildContext context) {
    const practicar = _TarjetaAccion(
      icono: Symbols.quiz,
      titulo: 'Practicar',
      detalle: 'Elige área y resuelve',
      ruta: Routes.practiceConfig,
      destacada: true,
    );
    final simulacro = _TarjetaAccion(
      icono: Symbols.timer,
      titulo: 'Simulacro',
      detalle:
          '${Blueprint.totalQuestions} preguntas · '
          '${Blueprint.examDuration.inHours} h',
      ruta: Routes.simulacroSelection,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: DesignTokens.space2),
          child: Text(
            'EMPIEZA A PRACTICAR',
            style: context.texts.bodySmall?.copyWith(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.9,
              color: context.scheme.onSurfaceVariant,
            ),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            // Con la fuente muy ampliada dos columnas no dan: se apilan, que es
            // preferible a achicar la letra o recortar el título.
            final apiladas =
                constraints.maxWidth < 320 ||
                MediaQuery.textScalerOf(context).scale(16) > 22;

            if (apiladas) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  practicar,
                  const SizedBox(height: DesignTokens.space2 + 2),
                  simulacro,
                ],
              );
            }

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Expanded(child: practicar),
                  const SizedBox(width: DesignTokens.space2 + 2),
                  Expanded(child: simulacro),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Tarjeta grande de acción.
///
/// [destacada] la pinta con el degradado de marca y sombra: es la acción
/// primaria y tiene que ganarle visualmente a la de al lado, que va en
/// superficie con borde de marca.
class _TarjetaAccion extends StatelessWidget {
  const _TarjetaAccion({
    required this.icono,
    required this.titulo,
    required this.detalle,
    required this.ruta,
    this.destacada = false,
  });

  final IconData icono;
  final String titulo;
  final String detalle;
  final String ruta;
  final bool destacada;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final radio = BorderRadius.circular(DesignTokens.radiusXl - 4);

    // Container + Material transparente, y no `Ink`: `Ink` pinta sobre el
    // Material ancestro y dentro del ListView se quedaba sin fondo.
    return Container(
      decoration: BoxDecoration(
        color: destacada ? null : scheme.surface,
        // El degradado de BOTÓN, no el de cabecera.
        //
        // Esta tarjeta llevaba `headerGradient`: diagonal, tres paradas y
        // arrancando en azul marino casi negro. Era el único elemento pulsable
        // de la app pintado con el degradado de las cabeceras —el resto usa
        // `buttonGradient`, que para eso se llama así— y al lado de la web, que
        // usa el de botón, la tarjeta se veía notablemente más oscura.
        //
        // Es la misma acción en las dos plataformas: tiene que verse igual.
        gradient: destacada
            ? const LinearGradient(colors: DesignTokens.buttonGradient)
            : null,
        border: destacada
            ? null
            : Border.all(color: scheme.primary, width: 1.5),
        borderRadius: radio,
        boxShadow: destacada
            ? const [
                BoxShadow(
                  color: Color(0x471F6F9B),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radio,
        child: InkWell(
          onTap: () => context.push(ruta),
          borderRadius: radio,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: _EmpiezaAPracticar._alto,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: DesignTokens.space3 + 2,
                vertical: DesignTokens.space3 + 1,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    icono,
                    size: 28,
                    fill: 1,
                    color: destacada ? Colors.white : scheme.primary,
                  ),
                  const SizedBox(height: DesignTokens.space2),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: context.texts.titleMedium?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          color: destacada ? Colors.white : scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        detalle,
                        style: context.texts.bodySmall?.copyWith(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                          color: destacada
                              ? Colors.white.withValues(alpha: 0.85)
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Las tres cifras que resumen dónde va el usuario.
///
/// Están aquí y no solo en Progreso porque son la respuesta a "¿cuánto llevo?",
/// que es la pregunta con la que se abre la app. Ninguna se inventa: el acierto
/// global sale de sumar lo respondido por área, y sin respuestas dice "aún sin
/// responder" en vez de un 0 % que se leería como un mal resultado.
class _Metricas extends StatelessWidget {
  const _Metricas({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final respondidas = stats.porArea.fold(0, (s, a) => s + a.respondidas);
    final correctas = stats.porArea.fold(0, (s, a) => s + a.correctas);
    final acierto = respondidas == 0 ? null : correctas / respondidas;
    final formato = NumberFormat.decimalPattern('es_PE');

    // IntrinsicHeight para que las tres tarjetas queden del alto de la más
    // alta: sin él, `stretch` dentro de una columna pide altura infinita.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _Metrica(
              icono: Symbols.menu_book,
              valor: formato.format(stats.preguntasVistas),
              etiqueta: 'vistas',
              detalle: stats.preguntasTotalesBanco > 0
                  ? 'de ${formato.format(stats.preguntasTotalesBanco)}'
                  : 'del banco',
            ),
          ),
          const SizedBox(width: DesignTokens.space2 + 2),
          Expanded(
            child: _Metrica(
              icono: Symbols.target,
              valor: acierto == null ? '—' : '${(acierto * 100).round()} %',
              etiqueta: 'acierto',
              detalle: respondidas > 0
                  ? 'en ${formato.format(respondidas)}'
                  : 'sin responder',
            ),
          ),
          const SizedBox(width: DesignTokens.space2 + 2),
          Expanded(
            child: _Metrica(
              icono: Symbols.checklist,
              valor: '${stats.simulacrosCompletados}',
              etiqueta: 'simulacros',
              detalle: stats.simulacrosCompletados > 0
                  ? 'de 180'
                  : 'ninguno aún',
            ),
          ),
        ],
      ),
    );
  }
}

class _Metrica extends StatelessWidget {
  const _Metrica({
    required this.icono,
    required this.valor,
    required this.etiqueta,
    required this.detalle,
  });

  final IconData icono;
  final String valor;
  final String etiqueta;
  final String detalle;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space2 + 2,
          vertical: DesignTokens.space3,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, size: 19, fill: 1, color: context.states.info.onTint),
            const SizedBox(height: DesignTokens.space2),
            Text(
              valor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.texts.titleLarge?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                height: 1,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              etiqueta,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.texts.bodySmall?.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            Text(
              detalle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.texts.bodySmall?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Las áreas por las que conviene empezar, con acceso directo.
///
/// El inicio no puede ser solo dos botones y una nota: quien lo abre viene a
/// decidir qué estudiar hoy, y esa decisión necesita ver el temario, no un
/// enlace que lleva a verlo. Se muestran cuatro y no las diez porque la lista
/// completa ya tiene su pantalla; aquí sirve como punto de partida.
///
/// El orden es el mismo de la pantalla de prioridades —peso en el examen, lo
/// que falta y cuánto rinde— para que las dos no recomienden cosas distintas.
class _PorDondeSeguir extends ConsumerWidget {
  const _PorDondeSeguir();

  static const _cuantas = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prioridades = ref.watch(prioridadEstudioProvider);
    if (prioridades.isEmpty) return const SizedBox.shrink();

    final areas = prioridades.take(_cuantas).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: DesignTokens.space2),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'POR DÓNDE SEGUIR',
                  style: context.texts.bodySmall?.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.9,
                    color: context.scheme.onSurfaceVariant,
                  ),
                ),
              ),
              InkWell(
                onTap: () => context.push(Routes.temario),
                borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.space1,
                    vertical: 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Ver el temario',
                        style: context.texts.bodySmall?.copyWith(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: context.states.info.onTint,
                        ),
                      ),
                      Icon(
                        Symbols.chevron_right,
                        size: 16,
                        color: context.states.info.onTint,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        for (var i = 0; i < areas.length; i++) ...[
          if (i > 0) const SizedBox(height: DesignTokens.space2),
          _AreaSugerida(area: areas[i].area),
        ],
      ],
    );
  }
}

class _AreaSugerida extends StatelessWidget {
  const _AreaSugerida({required this.area});

  final CatalogNode area;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final color = AreaColors.of(area.id, Theme.of(context).brightness);
    final acierto = area.porcentajeAcierto;

    return Card(
      child: InkWell(
        onTap: () => context.push(Routes.temarioAreaOf(area.id)),
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg + 2),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space3 + 2,
            vertical: DesignTokens.space3,
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: DesignTokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      area.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.bodyLarge?.copyWith(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    // El peso va siempre visible: 40 preguntas y 2 preguntas no
                    // pueden verse igual a la hora de decidir (RN-02).
                    Text(
                      acierto == null
                          ? '${area.peso ?? 0} preguntas · sin datos'
                          : '${area.peso ?? 0} preguntas · '
                                '${(acierto * 100).round()} % de acierto',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.bodySmall?.copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space1 + 2),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: acierto ?? 0,
                        minHeight: 6,
                        backgroundColor: scheme.outlineVariant,
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: DesignTokens.space2),
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
        onTap: () => context.push(Routes.stats),
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg + 2),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space4,
            vertical: DesignTokens.space3 + 1,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      'NOTA PROYECTADA',
                      style: context.texts.bodySmall?.copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.75,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  // La advertencia de RN-04 vive detrás de este icono: la
                  // tarjeta ya está densa y el aviso completo empujaría la nota
                  // fuera de la primera pantalla.
                  Semantics(
                    button: true,
                    label: 'Cómo se calcula',
                    child: InkWell(
                      onTap: () => _explicar(context),
                      borderRadius: BorderRadius.circular(
                        DesignTokens.radiusFull,
                      ),
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: Icon(
                          Symbols.info,
                          size: 19,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
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
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                        Text(
                          ' / 20',
                          style: context.texts.bodyLarge?.copyWith(
                            fontSize: 15,
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
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        height: 1,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  const Spacer(),
                  if (hayDatos) const _Delta(valor: 0.60),
                ],
              ),
              const SizedBox(height: DesignTokens.space2),
              if (hayDatos)
                _Escala(nota: stats.notaProyectada)
              else
                Text(
                  'Se calcula con tus primeras $_minRespuestas respuestas.',
                  style: context.texts.bodySmall?.copyWith(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
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
      padding: const EdgeInsets.fromLTRB(5, 5, DesignTokens.space3 - 1, 5),
      decoration: BoxDecoration(
        color: color.tint,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            subio ? Symbols.arrow_drop_up : Symbols.arrow_drop_down,
            size: 19,
            fill: 1,
            color: color.onTint,
          ),
          Text(
            '${subio ? "+" : ""}${valor.toStringAsFixed(2)} esta semana',
            style: context.texts.bodySmall?.copyWith(
              fontSize: 13,
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
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '11 · aprobado',
              style: context.texts.bodySmall?.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
            Text(
              '20',
              style: context.texts.bodySmall?.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Los dos atajos secundarios: el temario y lo que el usuario guardó.
class _AccesosRapidos extends StatelessWidget {
  const _AccesosRapidos({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final states = context.states;

    final temario = _Acceso(
      icon: Symbols.account_tree,
      color: states.info.onTint,
      fondo: states.info.tint,
      titulo: 'Temario',
      detalle: '${(stats.coberturaBanco * 100).round()} % cubierto',
      ruta: Routes.temario,
    );
    final marcadas = _Acceso(
      icon: Symbols.bookmark,
      color: states.warning.onTint,
      fondo: states.warning.tint,
      titulo: 'Marcadas',
      // Sin número: el dashboard no trae el conteo, y el «12 guardadas» que
      // había aquí no era de nadie. Mismo texto que la web, que ya lo resolvió
      // así en vez de inventar la cifra.
      detalle: 'Las que guardaste',
      ruta: Routes.markedQuestions,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // 400 y no 320. Estas tarjetas son HORIZONTALES —icono, texto y
        // chevron en fila—, así que a media pantalla al texto le quedaban unos
        // 90 px y los títulos salían como «Tem…» y «Marc…», con el detalle en
        // «0 % c…». Un recorte que no deja leer ni la primera palabra no es
        // recortar contenido, es no mostrarlo.
        //
        // Es el mismo umbral que la web (`min-[400px]:grid-cols-2`), donde las
        // dos columnas solo aparecen cuando de verdad hay sitio.
        //
        // Las tarjetas de «Practicar» y «Simulacro» sí aguantan 320 porque son
        // verticales: el texto ocupa el ancho entero de la tarjeta.
        final apiladas =
            constraints.maxWidth < 400 ||
            MediaQuery.textScalerOf(context).scale(16) > 22;

        if (apiladas) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              temario,
              const SizedBox(height: DesignTokens.space2 + 2),
              marcadas,
            ],
          );
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: temario),
              const SizedBox(width: DesignTokens.space2 + 2),
              Expanded(child: marcadas),
            ],
          ),
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
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg + 2),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space3 + 2,
            vertical: DesignTokens.space3 + 1,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(DesignTokens.space2),
                decoration: BoxDecoration(
                  color: fondo,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                ),
                child: Icon(icon, size: 22, fill: 1, color: color),
              ),
              const SizedBox(width: DesignTokens.space2 + 2),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: context.texts.bodyLarge?.copyWith(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        color: context.scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      detalle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.texts.bodySmall?.copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
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

class _SimulacroNacional extends ConsumerWidget {
  const _SimulacroNacional();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final states = context.states;
    final evento = ref.watch(nacionalProvider);

    // Sin nacional programado no se pinta la tarjeta. Antes el evento estaba
    // escrito en el código, así que siempre había uno aunque no existiera.
    if (evento == null) return const SizedBox.shrink();

    final inscrito = evento.inscrito;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.space4,
          vertical: DesignTokens.space3,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(DesignTokens.space2 - 1),
              decoration: BoxDecoration(
                color: states.warning.tint,
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              ),
              child: Icon(
                Symbols.campaign,
                size: 23,
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
                    'Simulacro Nacional · '
                    '${DateFormat('EEE d MMM', 'es').format(evento.inicio)}',
                    style: context.texts.bodyLarge?.copyWith(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                      color: context.scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    // Los datos que hacen falta para decidir si puedes: hora y
                    // cuánta gente va. La hora va en 12 h con a.m./p.m. porque
                    // así se lee en Perú, y `DateFormat.jm` da el de 24 h.
                    '${DateFormat('h:mm', 'es').format(evento.inicio)} '
                    '${evento.inicio.hour < 12 ? "a.m." : "p.m."} · '
                    '${NumberFormat.decimalPattern('es_PE').format(evento.participantes)} '
                    'inscritos',
                    style: context.texts.bodySmall?.copyWith(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                  if (inscrito) ...[
                    const SizedBox(height: DesignTokens.space1 + 2),
                    // Se dice aquí, antes de entrar: al usuario no le sirve
                    // descubrir que ya está anotado recién dentro.
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Symbols.check_circle,
                          size: 16,
                          fill: 1,
                          color: states.success.onTint,
                        ),
                        const SizedBox(width: DesignTokens.space1),
                        Text(
                          'Ya estás participando',
                          style: context.texts.bodySmall?.copyWith(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: states.success.onTint,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: DesignTokens.space2),
            OutlinedButton(
              onPressed: () => context.push(Routes.nationalMock),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.space4 - 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    DesignTokens.radiusXl - 4,
                  ),
                ),
                side: BorderSide(color: context.scheme.primary, width: 1.5),
                textStyle: context.texts.bodySmall?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              // Ojo con este texto: con un público en época de trámites,
              // "Inscribirme" a un "Simulacro Nacional" se puede leer como
              // inscripción al ENAM real. Va así porque lo pide el diseño.
              child: Text(inscrito ? 'Ver' : 'Inscribirme'),
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
        SkeletonBox(height: 128, radius: DesignTokens.radiusXl - 4),
        SizedBox(height: DesignTokens.space2 + 1),
        SkeletonBox(height: 148, radius: DesignTokens.radiusLg + 2),
        SizedBox(height: DesignTokens.space2 + 1),
        SkeletonBox(height: 72, radius: DesignTokens.radiusLg + 2),
        SizedBox(height: DesignTokens.space2 + 1),
        SkeletonBox(height: 72, radius: DesignTokens.radiusLg + 2),
      ],
    );
  }
}
