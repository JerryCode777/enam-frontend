import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/domain/blueprint.dart';
import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/state_colors.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/enam_button.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../../shared/widgets/state_banner.dart';

/// Datos del simulacro nacional programado. Vienen del admin (RF-19).
///
/// Hoy son fijos: el contrato todavía no tiene endpoint para listarlos. Falta un
/// `GET /mock-exams/next` con fecha, duración, inscritos y si el usuario ya está.
typedef SimulacroNacional = ({
  String id,
  String nombre,
  DateTime inicio,
  Duration duracion,
  int participantes,
  bool inscrito,
});

/// Inscripciones del usuario en simulacros nacionales.
///
/// Vive fuera de la pantalla a propósito: cuando el estado era un `bool` del
/// widget, salir y volver lo reiniciaba y se podía "participar" otra vez en el
/// mismo simulacro.
class InscripcionesNacionales extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() =>
      ref.read(appPrefsProvider).nacionalesInscritos();

  Future<void> inscribir(String id) async {
    await ref.read(appPrefsProvider).marcarInscritoEnNacional(id);
    state = AsyncData({...?state.value, id});
  }
}

final inscripcionesNacionalesProvider =
    AsyncNotifierProvider<InscripcionesNacionales, Set<String>>(
      InscripcionesNacionales.new,
    );

/// Si el usuario ya se anotó en el próximo nacional.
final inscritoEnNacionalProvider = Provider<bool>((ref) {
  final evento = ref.watch(nacionalProvider);
  final inscritos = ref.watch(inscripcionesNacionalesProvider).value ?? {};
  return evento.inscrito || inscritos.contains(evento.id);
});

final nacionalProvider = Provider<SimulacroNacional>((ref) {
  // Fecha calculada a futuro para que la cuenta regresiva siempre tenga sentido
  // durante el desarrollo.
  final inicio = DateTime.now().add(const Duration(days: 17, hours: 3));
  return (
    id: 'nacional-2026-08',
    nombre: 'Simulacro Nacional de agosto',
    inicio: DateTime(inicio.year, inicio.month, inicio.day, 8),
    duracion: Blueprint.examDuration,
    participantes: 1847,
    inscrito: false,
  );
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
    final evento = ref.watch(nacionalProvider);
    final inscrito = ref.watch(inscritoEnNacionalProvider);
    final ahora = DateTime.now();
    final falta = evento.inicio.difference(ahora);
    final enCurso =
        falta.isNegative && ahora.isBefore(evento.inicio.add(evento.duracion));
    final terminado = ahora.isAfter(evento.inicio.add(evento.duracion));

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
    await ref
        .read(inscripcionesNacionalesProvider.notifier)
        .inscribir(evento.id);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Listo. Te avisamos antes de que empiece.'),
      ),
    );
  }
}

class _Antes extends StatelessWidget {
  const _Antes({required this.evento, required this.falta});

  final SimulacroNacional evento;
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
                  fontSize: 11,
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

  final SimulacroNacional evento;

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

  final SimulacroNacional evento;

  @override
  Widget build(BuildContext context) {
    final filas = <({IconData icon, String texto})>[
      (
        icon: Symbols.quiz,
        texto: '${Blueprint.totalQuestions} preguntas con el blueprint oficial',
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
