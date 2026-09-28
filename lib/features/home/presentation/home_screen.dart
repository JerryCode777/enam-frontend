import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/domain/blueprint.dart';
import '../../../core/providers.dart';
import '../../../core/router/navegar.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/state_colors.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/estudio.dart';
import '../../../shared/widgets/state_banner.dart';
import '../../auth/domain/auth_models.dart';
import '../../catalog/presentation/catalog_providers.dart';
import '../../offline/presentation/offline_providers.dart';
import '../../session/presentation/national_mock_screen.dart';
import '../../stats/domain/stats_models.dart';
import '../domain/siguiente_accion.dart';

/// Lo que el inicio propone ahora, o `null` mientras no hay con qué decidirlo.
///
/// Se lee `.value` y no el `AsyncValue` entero: en una recarga el valor
/// anterior se conserva, así que el bloque no desaparece ni se reanima al
/// tirar hacia abajo. Solo la **primera** carga deja esto en `null`.
final siguienteAccionProvider = Provider<SiguienteAccion?>((ref) {
  final abiertas = ref.watch(sesionesAbiertasProvider);
  final dashboard = ref.watch(dashboardProvider);
  final sinRed = ref.watch(hayRedProvider).value == false;

  // Sin respuesta todavía de ninguna de las dos fuentes, no hay nada que
  // decidir: se enseña el esqueleto. Con la de sesiones fallida se sigue
  // adelante sin ella; retomar es un atajo, no un requisito.
  final sesionesListas = abiertas.hasValue || abiertas.hasError;
  final dashboardListo = dashboard.hasValue || dashboard.hasError;
  if (!sinRed && (!sesionesListas || !dashboardListo)) return null;

  final retomar = ref.watch(resumableSessionProvider);
  final prioridades = ref.watch(prioridadEstudioProvider);

  return decidirSiguienteAccion(
    sesionAbierta: retomar == null
        ? null
        : (
            sessionId: retomar.sessionId,
            esSimulacro: retomar.esSimulacro,
            respondidas: retomar.respondidas,
            total: retomar.total,
          ),
    sinRed: sinRed,
    practicasOffline: ref.watch(reservasProvider).value ?? 0,
    stats: dashboard.value,
    prioridades: [
      for (final p in prioridades) (area: p.area, acierto: p.acierto),
    ],
  );
});

/// Pantalla 2.1 — inicio.
///
/// Responde a una sola pregunta antes que a ninguna otra: **¿qué hago ahora?**
/// (plan de rediseño §5). Por eso tiene un bloque dominante —la siguiente
/// acción, distinta según el estado de la persona— y todo lo demás va debajo y
/// más pequeño: los accesos de estudio, el progreso y, al final, el simulacro
/// nacional y el duelo.
///
/// Antes eran once tarjetas de peso parecido, con el duelo en degradado por
/// encima de «Practicar» y una variación semanal de la nota («+0.60 esta
/// semana») que estaba escrita en el código: no salía de ningún dato.
///
/// La web aplica la misma regla y los mismos titulares (`siguiente_accion.dart`).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final accion = ref.watch(siguienteAccionProvider);
    final stats = ref.watch(dashboardProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async => ref
            ..invalidate(dashboardProvider)
            // Tirar hacia abajo también relee lo que quedó a medias: es el
            // gesto con el que la gente pregunta "¿esto está al día?".
            ..invalidate(sesionesAbiertasProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              DesignTokens.space5,
              DesignTokens.space3,
              DesignTokens.space5,
              DesignTokens.space8,
            ),
            children: [
              FadeUp(child: _Cabecera(user: user)),
              const _EstadoDeEnvio(),
              const SizedBox(height: DesignTokens.space5),
              FadeUp(
                index: 1,
                child: accion == null
                    ? const SkeletonBox(
                        height: 232,
                        radius: DesignTokens.radiusXl,
                      )
                    : _SiguienteAccion(accion: accion),
              ),
              const SizedBox(height: DesignTokens.space6),
              const FadeUp(index: 2, child: _Estudiar()),
              const SizedBox(height: DesignTokens.space6),
              FadeUp(
                index: 3,
                child: _TuProgreso(
                  stats: stats.value,
                  cargando: !stats.hasValue && !stats.hasError,
                  fallo: stats.hasError && !stats.hasValue,
                  onReintentar: () => ref.invalidate(dashboardProvider),
                ),
              ),
              const SizedBox(height: DesignTokens.space6),
              const _Mas(),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== CABECERA ====================

/// Saludo y cuenta regresiva, compactos y sobre el fondo de la app.
///
/// Era una portada en degradado de un tercio de pantalla. El saludo no es lo
/// que se viene a buscar, y la acción principal tiene que caber en el primer
/// vistazo de un teléfono de 390 × 844 (plan §6).
class _Cabecera extends StatelessWidget {
  const _Cabecera({this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    final nombre = user?.nombre.split(' ').first ?? '';
    final dias = user?.diasParaExamen;
    final fecha = user?.fechaObjetivo;

    final cuenta = switch (dias) {
      null => null,
      <= 0 => 'Hoy es tu ENAM',
      1 => 'Falta 1 día para tu ENAM',
      _ => 'Faltan $dias días para tu ENAM',
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  nombre.isEmpty ? 'Hola' : 'Hola, $nombre',
                  style: context.texts.headlineMedium,
                ),
              ),
              if (cuenta != null) ...[
                const SizedBox(height: 2),
                Text(
                  fecha == null || (dias ?? 0) <= 0
                      ? cuenta
                      : '$cuenta · ${DateFormat('d MMM', 'es').format(fecha)}',
                  style: context.texts.bodyMedium,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: DesignTokens.space3),
        _Avatar(user: user),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return Semantics(
      label: 'Perfil y ajustes',
      button: true,
      excludeSemantics: true,
      child: Material(
        color: context.states.info.tint,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => context.irA(Routes.settings),
          child: SizedBox.square(
            dimension: DesignTokens.minTouchTarget,
            child: Center(
              child: Text(
                _iniciales(user?.nombre),
                style: context.texts.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _iniciales(String? nombre) {
    if (nombre == null || nombre.trim().isEmpty) return '·';
    return nombre
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
  }
}

/// Lo respondido sin señal que aún no llegó al servidor, dicho en una línea.
///
/// Discreto a propósito (plan §7): no es algo que la persona tenga que
/// resolver, se envía solo al volver la red. Pero tiene que poder saberlo, y
/// nunca se dice «sincronizado» hasta que el servidor lo aceptó: la cifra sale
/// de la bandeja local y baja solo cuando llega la confirmación.
class _EstadoDeEnvio extends ConsumerWidget {
  const _EstadoDeEnvio();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(sincronizacionProvider).value;
    if (sync == null || sync.pendientes == 0) return const SizedBox.shrink();

    final n = sync.pendientes;
    return Padding(
      padding: const EdgeInsets.only(top: DesignTokens.space3),
      child: Align(
        alignment: Alignment.centerLeft,
        child: EtiquetaEstado(
          texto: sync.enMarcha
              ? 'Enviando tus respuestas…'
              : n == 1
              ? '1 respuesta por enviar'
              : '$n respuestas por enviar',
          tipo: BannerKind.warning,
          icono: Symbols.cloud_upload,
        ),
      ),
    );
  }
}

// ==================== SIGUIENTE ACCIÓN ====================

class _SiguienteAccion extends ConsumerWidget {
  const _SiguienteAccion({required this.accion});

  final SiguienteAccion accion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (accion) {
      RetomarSesion(:final esSimulacro, :final sessionId) && final r =>
        BloqueSiguienteAccion(
          antetitulo: esSimulacro
              ? 'Tienes un simulacro a medias'
              : 'Tienes una práctica a medias',
          titulo: esSimulacro ? 'Termina tu simulacro' : 'Continúa tu práctica',
          detalle: 'Pregunta ${r.siguiente} de ${r.total}',
          progreso: r.total == 0 ? null : r.respondidas / r.total,
          icono: esSimulacro ? Symbols.timer : Symbols.play_circle,
          accion: 'Retomar',
          // Un simulacro no se retoma en la pantalla de práctica: tiene
          // cronómetro, grilla de 180 y nada de retroalimentación. Y `go` para
          // el simulacro, que vive dentro del contenedor de pestañas: apilarlo
          // monta un segundo Navigator con la misma clave y tumba la app.
          onAccion: () => esSimulacro
              ? context.go(Routes.simulacroSessionOf(sessionId))
              : context.irA(Routes.practiceSessionOf(sessionId)),
        ),

      EstudiarSinConexion(:final practicasListas) => BloqueSiguienteAccion(
        antetitulo: 'Sin conexión',
        titulo: practicasListas > 0
            ? 'Practica sin conexión'
            : 'Sin conexión por ahora',
        detalle: practicasListas > 0
            ? (practicasListas == 1
                  ? 'Tienes 1 práctica lista en el teléfono. Tus respuestas '
                        'se envían al volver la señal.'
                  : 'Tienes $practicasListas prácticas listas en el '
                        'teléfono. Tus respuestas se envían al volver la '
                        'señal.')
            : 'No tienes áreas descargadas. Cuando vuelvas a tener internet, '
                  'descarga un área para estudiar sin señal.',
        icono: Symbols.cloud_off,
        acento: context.states.warning.base,
        accion: practicasListas > 0 ? 'Ver lo descargado' : 'Ir a descargas',
        onAccion: () => context.irA(Routes.downloads),
      ),

      PrimeraPractica() => BloqueSiguienteAccion(
        antetitulo: 'Tu primer paso',
        titulo: 'Empieza con una práctica corta',
        detalle:
            '${PrimeraPractica.cantidad} preguntas con su explicación. '
            'Puedes cambiar el área y la cantidad antes de empezar.',
        icono: Symbols.flag,
        accion: 'Empezar',
        onAccion: () => context.irA(
          '${Routes.practiceConfig}?cantidad=${PrimeraPractica.cantidad}',
        ),
      ),

      PracticarArea(:final area) && final p => BloqueSiguienteAccion(
        antetitulo: 'Tu siguiente paso',
        titulo: 'Practica ${area.nombre}',
        criterio: p.criterio,
        icono: Symbols.target,
        accion: 'Practicar ${area.nombre}',
        onAccion: () => context.irA(
          '${Routes.practiceConfig}?nodo=${Uri.encodeQueryComponent(area.id)}',
        ),
        secundaria: 'Elegir otra área',
        onSecundaria: () => context.irA(Routes.practiceConfig),
      ),

      ElegirArea() => BloqueSiguienteAccion(
        antetitulo: 'Tu siguiente paso',
        titulo: 'Elige un área para practicar',
        detalle: 'Escoge el área y cuántas preguntas quieres resolver.',
        icono: Symbols.quiz,
        accion: 'Elegir área',
        onAccion: () => context.irA(Routes.practiceConfig),
      ),
    };
  }
}

// ==================== ESTUDIAR ====================

/// Los accesos de estudio, en filas dentro de un solo bloque.
///
/// Subordinados a la siguiente acción: mismo ancho, menos peso. Antes
/// «Practicar» y «Simulacro» eran dos tarjetas grandes que competían con todo
/// lo demás.
class _Estudiar extends StatelessWidget {
  const _Estudiar();

  @override
  Widget build(BuildContext context) {
    final filas = [
      _Fila(
        icono: Symbols.quiz,
        titulo: 'Practicar',
        detalle: 'Elige área, cantidad y tipo de preguntas',
        onTap: () => context.irA(Routes.practiceConfig),
      ),
      _Fila(
        icono: Symbols.timer,
        titulo: 'Simulacro completo',
        detalle:
            '${Blueprint.totalQuestions} preguntas · '
            '${Blueprint.examDuration.inHours} h, como el examen',
        // `go`: los simulacros son otra pestaña.
        onTap: () => context.go(Routes.simulacroSelection),
      ),
      _Fila(
        icono: Symbols.history_edu,
        titulo: 'Exámenes pasados',
        detalle: 'Los ENAM de años anteriores',
        onTap: () => context.irA(Routes.pastExams),
      ),
      _Fila(
        icono: Symbols.bookmark,
        titulo: 'Preguntas marcadas',
        detalle: 'Las que guardaste para repasar',
        onTap: () => context.irA(Routes.markedQuestions),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TituloSeccion('Estudiar'),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < filas.length; i++) ...[
                if (i > 0) const Divider(indent: 64),
                filas[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({
    required this.icono,
    required this.titulo,
    required this.detalle,
    required this.onTap,
    this.extra,
  });

  final IconData icono;
  final String titulo;
  final String detalle;
  final VoidCallback onTap;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.space4,
            vertical: DesignTokens.space3,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: context.states.info.tint,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                ),
                child: Icon(icono, size: 20, color: scheme.primary),
              ),
              const SizedBox(width: DesignTokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: context.texts.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(detalle, style: context.texts.bodyMedium),
                    if (extra != null) ...[
                      const SizedBox(height: DesignTokens.space1),
                      extra!,
                    ],
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

// ==================== TU PROGRESO ====================

/// Tres cifras como máximo, la racha si la hay y la nota solo con datos.
///
/// Ninguna se inventa: el acierto sale de sumar lo respondido por área, y sin
/// respuestas dice «sin responder» en vez de un 0 % que se leería como un mal
/// resultado. La nota proyectada exige 50 respuestas, igual que en la web.
class _TuProgreso extends StatelessWidget {
  const _TuProgreso({
    required this.stats,
    required this.cargando,
    required this.fallo,
    required this.onReintentar,
  });

  final DashboardStats? stats;
  final bool cargando;
  final bool fallo;
  final VoidCallback onReintentar;

  /// Con menos respuestas la proyección es ruido y no se muestra (RN-04).
  static const minRespuestas = 50;

  @override
  Widget build(BuildContext context) {
    final titulo = TituloSeccion(
      'Tu progreso',
      enlace: 'Ver todo',
      // `go`: el progreso es otra pestaña.
      onEnlace: () => context.go(Routes.stats),
    );

    if (cargando) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          titulo,
          const SkeletonBox(height: 104, radius: DesignTokens.radiusLg),
        ],
      );
    }

    final s = stats;
    if (fallo || s == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          titulo,
          StateBanner(
            kind: BannerKind.error,
            message: 'No pudimos cargar tu progreso.',
            action: TextButton(
              onPressed: onReintentar,
              child: const Text('Reintentar'),
            ),
          ),
        ],
      );
    }

    final formato = NumberFormat.decimalPattern('es_PE');
    final respondidas = s.porArea.fold(0, (t, a) => t + a.respondidas);
    final correctas = s.porArea.fold(0, (t, a) => t + a.correctas);
    final acierto = respondidas == 0 ? null : correctas / respondidas;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        titulo,
        ResumenMetrico(
          onTap: () => context.go(Routes.stats),
          metricas: [
            (
              valor: formato.format(s.preguntasVistas),
              etiqueta: 'preguntas vistas',
              detalle: s.preguntasTotalesBanco > 0
                  ? 'de ${formato.format(s.preguntasTotalesBanco)}'
                  : null,
            ),
            (
              valor: acierto == null ? '—' : '${(acierto * 100).round()} %',
              etiqueta: 'de acierto',
              detalle: respondidas > 0
                  ? 'en ${formato.format(respondidas)}'
                  : 'sin responder',
            ),
            (
              valor: '${s.simulacrosCompletados}',
              etiqueta: s.simulacrosCompletados == 1
                  ? 'simulacro'
                  : 'simulacros',
              detalle: s.simulacrosCompletados == 0 ? 'ninguno aún' : null,
            ),
          ],
        ),
        if (s.racha case final racha? when racha.dias > 0) ...[
          const SizedBox(height: DesignTokens.space3),
          _Racha(
            dias: racha.dias,
            practicoHoy: racha.diasDeLaSemana.lastOrNull ?? false,
          ),
        ],
        if (respondidas >= minRespuestas) ...[
          const SizedBox(height: DesignTokens.space3),
          _NotaProyectada(nota: s.notaProyectada),
        ],
      ],
    );
  }
}

class _Racha extends StatelessWidget {
  const _Racha({required this.dias, required this.practicoHoy});

  final int dias;
  final bool practicoHoy;

  @override
  Widget build(BuildContext context) {
    final aviso = context.states.warning;
    return Row(
      children: [
        Icon(
          Symbols.local_fire_department,
          size: 20,
          fill: 1,
          color: aviso.base,
        ),
        const SizedBox(width: DesignTokens.space2),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: dias == 1 ? '1 día seguido' : '$dias días seguidos',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text: practicoHoy
                      ? ' · hoy ya practicaste'
                      : ' · practica hoy para mantenerla',
                ),
              ],
            ),
            style: context.texts.bodyMedium?.copyWith(
              color: context.scheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

/// La nota proyectada, con su escala y sin adornos (RN-04).
///
/// Ya no lleva la variación semanal: aquel «+0.60 esta semana» era un número
/// escrito en el código. Cuando el servidor mande la evolución real se puede
/// volver a poner, calculada.
class _NotaProyectada extends StatelessWidget {
  const _NotaProyectada({required this.nota});

  final double nota;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    const aprobado = Blueprint.passingGrade / Blueprint.maxGrade;

    return Card(
      child: InkWell(
        onTap: () => _explicar(context),
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Nota proyectada',
                      style: context.texts.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    Symbols.info,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                    semanticLabel: 'Cómo se calcula',
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.space1),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: nota.toStringAsFixed(2),
                      style: context.texts.headlineLarge?.copyWith(height: 1),
                    ),
                    TextSpan(
                      text: ' / 20',
                      style: context.texts.bodyLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: DesignTokens.space3),
              LayoutBuilder(
                builder: (context, c) => Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.centerLeft,
                  children: [
                    AnimatedBar(
                      value: nota / Blueprint.maxGrade,
                      color: scheme.primary,
                      height: 8,
                      background: scheme.surfaceContainer,
                    ),
                    Positioned(
                      left: c.maxWidth * aprobado - 1.5,
                      top: -4,
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
              Text(
                'La marca es el 11, la nota aprobatoria. Es una estimación '
                'sobre tu práctica, no una predicción del examen.',
                style: context.texts.bodySmall,
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

// ==================== MÁS ====================

/// El simulacro nacional, solo si hay convocatoria, y el duelo.
///
/// Al final y en el mismo formato de fila que «Estudiar»: son añadidos al
/// estudio, no el estudio. El duelo tenía el degradado de marca y estaba por
/// encima de «Practicar».
class _Mas extends ConsumerWidget {
  const _Mas();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final evento = ref.watch(nacionalProvider);

    final filas = <Widget>[
      if (evento != null)
        _Fila(
          icono: Symbols.campaign,
          titulo:
              'Simulacro Nacional · '
              '${DateFormat('EEE d MMM', 'es').format(evento.inicio)}',
          // La hora en 12 h con a.m./p.m., que es como se lee en Perú.
          detalle:
              '${DateFormat('h:mm', 'es').format(evento.inicio)} '
              '${evento.inicio.hour < 12 ? "a.m." : "p.m."} · '
              '${NumberFormat.decimalPattern('es_PE').format(evento.participantes)} '
              'inscritos',
          extra: evento.inscrito
              ? const EtiquetaEstado(
                  texto: 'Ya estás participando',
                  tipo: BannerKind.success,
                )
              : null,
          // `go`: el nacional cuelga de la pestaña de simulacros.
          onTap: () => context.go(Routes.nationalMock),
        ),
      _Fila(
        icono: Symbols.swords,
        titulo: 'Modo duelo',
        detalle: 'Diez preguntas contra otra persona, en vivo',
        onTap: () => context.irA(Routes.duelo),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TituloSeccion('También puedes'),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < filas.length; i++) ...[
                if (i > 0) const Divider(indent: 64),
                filas[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}
