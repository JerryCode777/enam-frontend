import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/error/failure.dart';
import '../../../core/providers.dart';
import '../../../core/router/navegar.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/area_colors.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/theme/state_colors.dart';
import '../../../shared/widgets/animations.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/enam_button.dart';
import '../../../shared/widgets/gradient_header.dart';
import '../../../shared/widgets/state_banner.dart';
import '../../session/domain/session_models.dart';
import '../../subscription/presentation/access_ended_screen.dart';
import '../domain/offline_models.dart';
import 'offline_providers.dart';

/// Pantalla 8.1 — estudiar sin conexión (RF-30).
///
/// Lo que hay que entender de un vistazo es **si puedo practicar en el bus**, y
/// eso no lo contesta el número de megas: lo contesta si hay una práctica lista.
/// Por eso lo primero de la pantalla es esa tarjeta y no el espacio ocupado.
///
/// El contenido descargado es premium y viaja con sus claves, así que se guarda
/// cifrado y atado a la cuenta (ver `CifradoLocal`). La comprobación de plan la
/// hace el servidor: si no corresponde, la descarga vuelve con un 403 y aquí
/// solo se cuenta lo que dijo.
class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paquetes = ref.watch(descargasProvider);
    final hayRed = ref.watch(hayRedProvider).value ?? true;

    return Scaffold(
      body: Column(
        children: [
          const GradientHeader(titulo: 'Estudiar sin conexión'),
          Expanded(
            child: paquetes.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const Center(
                child: Padding(
                  padding: EdgeInsets.all(DesignTokens.space5),
                  child: Text(
                    'No pudimos cargar la lista de áreas. Si estás sin '
                    'conexión, tus descargas siguen ahí: vuelve a entrar '
                    'cuando tengas internet.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              data: (lista) => _Contenido(paquetes: lista, hayRed: hayRed),
            ),
          ),
        ],
      ),
    );
  }
}

class _Contenido extends ConsumerWidget {
  const _Contenido({required this.paquetes, required this.hayRed});

  final List<PaqueteEnPantalla> paquetes;
  final bool hayRed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bytes = paquetes.fold(0, (suma, p) => suma + p.bytes);
    final descargadas = paquetes.where((p) => p.bytes > 0).length;
    final reservas = ref.watch(reservasProvider).value ?? 0;
    final sync = ref.watch(sincronizacionProvider).value;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.space4,
        DesignTokens.space4,
        DesignTokens.space4,
        DesignTokens.space8,
      ),
      children: [
        if (!hayRed) ...[
          const FadeUp(
            child: StateBanner(
              kind: BannerKind.warning,
              icon: Symbols.wifi_off,
              message:
                  'Estás sin conexión. Puedes practicar con lo que ya tienes '
                  'descargado; para bajar más áreas hace falta internet.',
            ),
          ),
          const SizedBox(height: DesignTokens.space4),
        ],
        FadeUp(
          child: Text(
            'Descarga áreas para practicar sin internet — en la guardia, en el '
            'bus. Lo que respondas se guarda y viaja solo al reconectar.',
            style: context.texts.bodyMedium?.copyWith(height: 1.55),
          ),
        ),
        const SizedBox(height: DesignTokens.space4),
        FadeUp(
          index: 1,
          child: _ListasParaElViaje(
            cuantas: reservas,
            areasDescargadas: descargadas,
          ),
        ),
        if (sync != null && sync.pendientes > 0) ...[
          const SizedBox(height: DesignTokens.space3),
          FadeUp(index: 2, child: _PorEnviar(estado: sync)),
        ],
        const SizedBox(height: DesignTokens.space4),
        FadeUp(
          index: 3,
          child: _Espacio(bytes: bytes, areas: descargadas),
        ),
        const SizedBox(height: DesignTokens.space4),
        Card(
          child: Column(
            children: [
              for (var i = 0; i < paquetes.length; i++)
                _FilaPaquete(
                  paquete: paquetes[i],
                  index: i,
                  esUltima: i == paquetes.length - 1,
                  hayRed: hayRed,
                ),
            ],
          ),
        ),
        const SizedBox(height: DesignTokens.space4),
        const FadeUp(
          index: 4,
          child: StateBanner(
            message:
                'Los simulacros —y los nacionales— siempre necesitan conexión: '
                'el reloj y el ranking los lleva el servidor.',
          ),
        ),
      ],
    );
  }
}

/// La respuesta a «¿puedo practicar ahora mismo sin señal?».
///
/// Y el botón para hacerlo, que es lo que faltaba: llegar a practicar sin
/// conexión pasando por el inicio y el selector de áreas depende de pantallas
/// que piden datos al servidor. Desde aquí se empieza en un toque.
class _ListasParaElViaje extends ConsumerStatefulWidget {
  const _ListasParaElViaje({
    required this.cuantas,
    required this.areasDescargadas,
  });

  final int cuantas;

  /// Cuántas áreas hay guardadas en el teléfono.
  ///
  /// Hace falta para no mentir: con áreas descargadas y sin práctica lista, el
  /// texto de antes —«descarga un área y te dejamos una preparada»— le pedía a
  /// alguien que hiciera justo lo que acababa de hacer.
  final int areasDescargadas;

  @override
  ConsumerState<_ListasParaElViaje> createState() => _ListasParaElViajeState();
}

class _ListasParaElViajeState extends ConsumerState<_ListasParaElViaje> {
  bool _empezando = false;

  Future<void> _empezar() async {
    if (_empezando) return;
    setState(() => _empezando = true);

    try {
      final sesion = await ref
          .read(sessionRepositoryProvider)
          .startPractice(const PracticeConfig(cantidadPreguntas: 20));

      // D-02: el reloj de las 24 h arranca al practicar, no al registrarse.
      await ref.read(inicioPruebaProvider.notifier).arrancar();
      ref.invalidate(sesionesAbiertasProvider);
      ref.invalidate(reservasProvider);

      if (mounted) context.irA(Routes.practiceSessionOf(sesion.id));
    } on Failure catch (e) {
      if (mounted) showErrorSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _empezando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cuantas = widget.cuantas;
    final states = context.states;
    final hay = cuantas > 0;
    final yaDescargo = widget.areasDescargadas > 0;
    final color = hay ? states.success : states.info;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.space4),
      decoration: BoxDecoration(
        color: color.tint,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg + 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                hay ? Symbols.offline_bolt : Symbols.download_for_offline,
                size: 26,
                fill: 1,
                color: color.onTint,
              ),
              const SizedBox(width: DesignTokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hay
                          ? '$cuantas ${cuantas == 1 ? 'práctica lista' : 'prácticas listas'} sin conexión'
                          : yaDescargo
                          ? 'Tu práctica se prepara sola'
                          : 'Todavía no hay prácticas listas',
                      style: context.texts.bodyLarge?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: color.onTint,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hay
                          ? 'Veinte preguntas con corrección al instante, aunque no '
                                'haya internet.'
                          : yaDescargo
                          ? 'Ya tienes el área guardada. En cuanto practiques una '
                                'vez con internet, te dejamos veinte preguntas '
                                'listas para el viaje.'
                          : 'Descarga un área y te dejamos una preparada.',
                      style: context.texts.bodySmall?.copyWith(
                        fontSize: 13,
                        height: 1.4,
                        color: color.onTint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hay) ...[
            const SizedBox(height: DesignTokens.space3),
            EnamButton(
              label: 'Empezar una práctica',
              icon: Symbols.play_arrow,
              loading: _empezando,
              onPressed: _empezar,
            ),
          ],
        ],
      ),
    );
  }
}

/// Lo que se respondió sin señal y todavía no llegó al servidor.
class _PorEnviar extends ConsumerWidget {
  const _PorEnviar({required this.estado});

  final EstadoDeSync estado;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final states = context.states;

    return Container(
      padding: const EdgeInsets.all(DesignTokens.space4),
      decoration: BoxDecoration(
        color: states.warning.tint,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg + 2),
      ),
      child: Row(
        children: [
          Icon(
            Symbols.cloud_upload,
            size: 24,
            fill: 1,
            color: states.warning.onTint,
          ),
          const SizedBox(width: DesignTokens.space3),
          Expanded(
            child: Text(
              '${estado.pendientes} '
              '${estado.pendientes == 1 ? 'respuesta' : 'respuestas'} por '
              'enviar. Se mandan solas cuando vuelva el internet.',
              style: context.texts.bodySmall?.copyWith(
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: states.warning.onTint,
              ),
            ),
          ),
          if (estado.enMarcha)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            TextButton(
              onPressed: () =>
                  ref.read(sincronizacionProvider.notifier).sincronizar(),
              child: const Text('Enviar'),
            ),
        ],
      ),
    );
  }
}

class _Espacio extends StatelessWidget {
  const _Espacio({required this.bytes, required this.areas});

  final int bytes;
  final int areas;

  /// Referencia para la barra. No es el espacio libre del teléfono —eso habría
  /// que preguntárselo al sistema— sino una magnitud para dar contexto.
  static const _referenciaMb = 300;

  @override
  Widget build(BuildContext context) {
    final mb = bytes / (1024 * 1024);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Espacio usado',
                    style: context.texts.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  areas == 0
                      ? 'Nada descargado'
                      : '${formatearTamano(bytes)} · '
                            '$areas ${areas == 1 ? 'área' : 'áreas'}',
                  style: context.texts.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.space2),
            AnimatedBar(
              value: (mb / _referenciaMb).clamp(0, 1),
              color: context.scheme.primary,
              height: 6,
            ),
          ],
        ),
      ),
    );
  }
}

/// Tamaño legible. En KB hasta el mega, porque un área de 40 preguntas pesa
/// menos de uno y «0 MB» parecería que no se descargó nada.
String formatearTamano(int bytes) {
  if (bytes <= 0) return '0 KB';
  final kb = bytes / 1024;
  if (kb < 1024) return '${kb.round()} KB';
  return '${(kb / 1024).toStringAsFixed(1)} MB';
}

class _FilaPaquete extends ConsumerWidget {
  const _FilaPaquete({
    required this.paquete,
    required this.index,
    required this.esUltima,
    required this.hayRed,
  });

  final PaqueteEnPantalla paquete;
  final int index;
  final bool esUltima;
  final bool hayRed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final states = context.states;
    final color = AreaColors.of(paquete.areaId, Theme.of(context).brightness);

    final (icono, colorIcono, tooltip) = switch (paquete.estado) {
      EstadoDescarga.descargada => (
        Symbols.delete,
        context.scheme.onSurfaceVariant,
        'Eliminar del teléfono',
      ),
      EstadoDescarga.descargando => (
        Symbols.hourglass_top,
        context.scheme.onSurfaceVariant,
        'Descargando',
      ),
      EstadoDescarga.actualizable => (
        Symbols.sync,
        states.info.onTint,
        'Actualizar',
      ),
      EstadoDescarga.noDescargada => (
        Symbols.download,
        states.info.onTint,
        'Descargar',
      ),
    };

    final detalle = switch (paquete.estado) {
      EstadoDescarga.descargada =>
        '${paquete.guardadas} preguntas · ${formatearTamano(paquete.bytes)} · al día',
      EstadoDescarga.descargando =>
        paquete.progreso > 0
            ? 'Descargando · ${(paquete.progreso * 100).round()} %'
            : 'Descargando…',
      EstadoDescarga.actualizable =>
        'Hay ${paquete.disponibles - paquete.guardadas} preguntas nuevas',
      EstadoDescarga.noDescargada =>
        '${paquete.disponibles} preguntas disponibles',
    };

    final descargando = paquete.estado == EstadoDescarga.descargando;

    return FadeUp(
      index: index,
      child: Container(
        decoration: BoxDecoration(
          border: esUltima
              ? null
              : Border(
                  bottom: BorderSide(color: context.scheme.outlineVariant),
                ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.space4),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: DesignTokens.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      paquete.nombre,
                      style: context.texts.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      detalle,
                      style: context.texts.bodySmall?.copyWith(
                        fontSize: 13,
                        fontWeight:
                            paquete.estado == EstadoDescarga.actualizable
                            ? FontWeight.w700
                            : null,
                        color: paquete.estado == EstadoDescarga.actualizable
                            ? states.warning.onTint
                            : null,
                      ),
                    ),
                    if (descargando) ...[
                      const SizedBox(height: DesignTokens.space1 + 2),
                      // Sin porcentaje la barra va indeterminada: es lo honesto
                      // cuando el servidor no dice cuánto pesa la respuesta.
                      LinearProgressIndicator(
                        value: paquete.progreso > 0 ? paquete.progreso : null,
                        minHeight: 4,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: DesignTokens.space2),
              IconButton(
                icon: Icon(icono, size: 22, color: colorIcono),
                tooltip: tooltip,
                onPressed: descargando ? null : () => _actuar(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _actuar(BuildContext context, WidgetRef ref) async {
    if (paquete.estado == EstadoDescarga.descargada) {
      return _eliminar(context, ref);
    }

    if (!hayRed) {
      showErrorSnack(
        context,
        'Necesitas internet para descargar ${paquete.nombre}.',
      );
      return;
    }

    final error = await ref
        .read(descargasProvider.notifier)
        .descargar(paquete.areaId);

    if (!context.mounted) return;
    if (error != null) {
      // RN-03: quien decide si hay plan es el servidor. Si dice que no, se va
      // al mismo sitio que cuando vence la prueba en mitad de una práctica, y
      // no a un aviso que deja al usuario sin saber qué hacer.
      if (error is ForbiddenFailure && error.requiereSuscripcion) {
        irAlPago(ref, context);
      } else {
        showErrorSnack(context, error.message);
      }
      return;
    }

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('${paquete.nombre} lista para usar sin conexión'),
        ),
      );
  }

  Future<void> _eliminar(BuildContext context, WidgetRef ref) async {
    final borrar = await confirmar(
      context,
      titulo: '¿Eliminar ${paquete.nombre}?',
      mensaje:
          'Liberas ${formatearTamano(paquete.bytes)}. Puedes volver a '
          'descargarla cuando quieras, y tu progreso no se pierde.',
      confirmar: 'Eliminar',
      cancelar: 'Conservar',
      destructivo: true,
    );
    if (!borrar || !context.mounted) return;

    await ref.read(descargasProvider.notifier).eliminar(paquete.areaId);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text('${paquete.nombre} eliminada')));
  }
}
