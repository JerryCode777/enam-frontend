import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

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

/// Los simulacros nacionales programados (RF-19).
///
/// **Todo viene del servidor**, incluido si el usuario ya entró y en qué
/// momento está el evento. Antes no era así y las dos cosas costaron caro:
///
/// - La inscripción se guardaba en `SharedPreferences`. Cambiar de teléfono la
///   perdía, y el mismo usuario podía "participar" dos veces en el mismo
///   simulacro. Ahora es el campo `inscrito` que manda la API.
/// - Los tres momentos —antes, en curso, terminado— salían del reloj del
///   dispositivo. Con el reloj adelantado la app enseñaba "Entrar al simulacro"
///   para algo que el servidor iba a rechazar. Ahora es el campo `estado`.
final nacionalesProvider = FutureProvider<List<NationalMock>>((ref) {
  return ref.watch(sessionRepositoryProvider).nationalMocks();
});

/// El próximo simulacro nacional, o `null` si no hay ninguno programado.
final nacionalProvider = Provider<NationalMock?>((ref) {
  final lista = ref.watch(nacionalesProvider).value;
  if (lista == null || lista.isEmpty) return null;
  return lista.first;
});

/// Pantalla 5.8 — simulacro nacional (RF-19).
///
/// Tres momentos en una pantalla, según la fecha: **antes** (participar),
/// **sala de espera** el día del evento, y **después** (ver ranking).
///
/// El botón dice "Participar" y no "Inscribirme" a propósito: con un público en
/// época de trámites, "inscribirse" se puede leer como inscripción al ENAM real.
class NationalMockScreen extends ConsumerStatefulWidget {
  const NationalMockScreen({super.key});

  @override
  ConsumerState<NationalMockScreen> createState() => _NationalMockScreenState();
}

class _NationalMockScreenState extends ConsumerState<NationalMockScreen> {
  Timer? _reloj;
  bool _participando = false;

  @override
  void initState() {
    super.initState();
    // Un minuto basta: la cuenta regresiva es de días, no de segundos.
    _reloj = Timer.periodic(
      const Duration(minutes: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _reloj?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final consulta = ref.watch(nacionalesProvider);
    final evento = ref.watch(nacionalProvider);

    if (consulta.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (evento == null) {
      return const _SinNacional();
    }

    // Los tres momentos los decide el SERVIDOR, no el reloj del dispositivo:
    // uno adelantado enseñaría "Entrar al simulacro" para algo que la API va a
    // rechazar, y el usuario no tendría forma de entender el error.
    final inscrito = evento.inscrito;
    final enCurso = evento.estado == NationalMockStatus.enCurso;
    final terminado = evento.estado == NationalMockStatus.cerrado;
    final falta = evento.faltaParaEmpezar ?? Duration.zero;

    return Scaffold(
      body: Column(
        children: [
          GradientHeader(
            titulo: evento.nombre,
            subtitulo: DateFormat(
              "EEEE d 'de' MMMM · h:mm a",
              'es',
            ).format(evento.inicio),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.space5,
                DesignTokens.space5,
                DesignTokens.space5,
                DesignTokens.space8,
              ),
              children: [
                // Aclaración necesaria: el público está en época de trámites y
                // "simulacro nacional" puede leerse como algo oficial.
                const FadeUp(
                  child: StateBanner(
                    icon: Symbols.info,
                    message:
                        'Es un simulacro de práctica dentro de la app. No tiene '
                        'relación con la inscripción oficial al ENAM.',
                  ),
                ),
                const SizedBox(height: DesignTokens.space5),
                if (terminado)
                  const _Terminado()
                else if (enCurso)
                  _EnCurso(evento: evento)
                else
                  _Antes(evento: evento, falta: falta),
                const SizedBox(height: DesignTokens.space5),
                FadeUp(index: 2, child: _Detalles(evento: evento)),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
              DesignTokens.space5,
              DesignTokens.space3,
              DesignTokens.space5,
              DesignTokens.space3 + MediaQuery.paddingOf(context).bottom,
            ),
            decoration: BoxDecoration(
              color: context.scheme.surface,
              border: Border(
                top: BorderSide(color: context.scheme.outlineVariant),
              ),
            ),
            child: switch (null) {
              _ when terminado => EnamButton(
                label: 'Ver el ranking',
                icon: Symbols.trophy,
                onPressed: () => context.push(Routes.ranking),
              ),
              _ when enCurso => EnamButton(
                label: 'Entrar al simulacro',
                icon: Symbols.play_arrow,
                onPressed: () => context.push(Routes.simulacroInstructions),
              ),
              _ => EnamButton(
                label: inscrito ? 'Ya estás participando' : 'Participar',
                loading: _participando,
                icon: inscrito
                    ? Symbols.check
                    : Symbols.how_to_reg,
                onPressed: inscrito
                    ? null
                    : _participar,
              ),
            },
          ),
        ],
      ),
    );
  }

  Future<void> _participar() async {
    final evento = ref.read(nacionalProvider);
    if (evento == null || _participando) return;

    setState(() => _participando = true);
    try {
      await ref.read(sessionRepositoryProvider).joinNationalMock(evento.id);
      // Sin esto el botón seguiría diciendo "Participar": quien vuelve a
      // tocarlo se apunta dos veces, que es justo lo que este cambio arregla.
      ref.invalidate(nacionalesProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Listo. Te avisamos antes de que empiece.'),
        ),
      );
    } on Failure catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _participando = false);
    }
  }
}

/// Cuando no hay ningún nacional programado.
///
/// Antes no podía pasar porque el evento estaba escrito en el código, así que
/// siempre había uno "programado" aunque no existiera.
class _SinNacional extends StatelessWidget {
  const _SinNacional();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const GradientHeader(titulo: 'Simulacro nacional'),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(DesignTokens.space8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Symbols.event_upcoming,
                      size: 40,
                      color: context.scheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: DesignTokens.space4),
                    Text(
                      'No hay ninguno programado',
                      style: context.texts.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: DesignTokens.space3),
                    Text(
                      'Te avisamos cuando anunciemos el siguiente. Mientras '
                      'tanto puedes rendir un simulacro completo cuando '
                      'quieras.',
                      textAlign: TextAlign.center,
                      style: context.texts.bodyMedium?.copyWith(height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Antes extends StatelessWidget {
  const _Antes({required this.evento, required this.falta});

  final NationalMock evento;
  final Duration falta;

  @override
  Widget build(BuildContext context) {
    final states = context.states;

    return FadeUp(
      index: 1,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.space5),
          child: Column(
            children: [
              Text(
                'EMPIEZA EN',
                style: context.texts.bodySmall?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: context.scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: DesignTokens.space2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Unidad(valor: falta.inDays, etiqueta: 'días'),
                  _Unidad(valor: falta.inHours % 24, etiqueta: 'horas'),
                  _Unidad(valor: falta.inMinutes % 60, etiqueta: 'min'),
                ],
              ),
              const SizedBox(height: DesignTokens.space4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Symbols.group, size: 18, color: states.info.onTint),
                  const SizedBox(width: DesignTokens.space2),
                  Text(
                    '${NumberFormat.decimalPattern('es_PE').format(evento.participantes)} '
                    'participantes',
                    style: context.texts.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Unidad extends StatelessWidget {
  const _Unidad({required this.valor, required this.etiqueta});

  final int valor;
  final String etiqueta;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.space3),
      child: Column(
        children: [
          Text(
            '$valor',
            style: context.texts.headlineLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: context.scheme.primary,
            ),
          ),
          Text(etiqueta, style: context.texts.bodySmall),
        ],
      ),
    );
  }
}

class _EnCurso extends StatelessWidget {
  const _EnCurso({required this.evento});

  final NationalMock evento;

  @override
  Widget build(BuildContext context) {
    return const FadeUp(
      index: 1,
      child: StateBanner(
        kind: BannerKind.success,
        icon: Symbols.play_circle,
        message:
            'El simulacro está en curso. Puedes entrar, pero el cronómetro ya '
            'empezó para todos.',
      ),
    );
  }
}

class _Terminado extends StatelessWidget {
  const _Terminado();

  @override
  Widget build(BuildContext context) {
    return const FadeUp(
      index: 1,
      child: StateBanner(
        icon: Symbols.trophy,
        message: 'Este simulacro ya cerró. El ranking está publicado.',
      ),
    );
  }
}

class _Detalles extends StatelessWidget {
  const _Detalles({required this.evento});

  final NationalMock evento;

  @override
  Widget build(BuildContext context) {
    final filas = <({IconData icon, String texto})>[
      (
        icon: Symbols.quiz,
        // Del servidor: un nacional de muestra no tiene 180, y afirmarlo
        // sería prometer un examen distinto del que se va a rendir.
        texto: '${evento.totalPreguntas} preguntas con el blueprint oficial',
      ),
      (
        icon: Symbols.timer,
        texto: '${evento.duracion.inHours} horas, igual que el examen real',
      ),
      (
        icon: Symbols.groups,
        texto: 'Todos rinden el mismo examen al mismo tiempo',
      ),
      (
        icon: Symbols.trophy,
        texto: 'El ranking se publica al cerrar. Desempata el menor tiempo',
      ),
      (
        icon: Symbols.wifi,
        // RF-33: hay que decirlo antes, no cuando ya no haya señal.
        texto: 'Requiere conexión. No funciona con las descargas offline',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final f in filas)
          Padding(
            padding: const EdgeInsets.only(bottom: DesignTokens.space3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  f.icon,
                  size: 20,
                  color: context.scheme.onSurfaceVariant,
                ),
                const SizedBox(width: DesignTokens.space3),
                Expanded(
                  child: Text(
                    f.texto,
                    style: context.texts.bodyMedium?.copyWith(height: 1.5),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
