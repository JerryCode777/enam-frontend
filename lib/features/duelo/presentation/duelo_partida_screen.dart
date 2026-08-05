import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../shared/widgets/confirm_dialog.dart';
import '../../../shared/widgets/enam_button.dart';
import '../domain/duelo_models.dart';
import '../data/duelo_socket.dart';
import 'duelo_controller.dart';
import 'widgets/partida_en_curso.dart';
import 'widgets/resultado_del_duelo.dart';
import 'widgets/revision_del_duelo.dart';
import 'widgets/sala_de_espera.dart';

/// La pantalla del duelo, de principio a fin.
///
/// # Por qué es UNA pantalla y no cuatro
///
/// Porque la conexión es una sola. Sala de espera, partida y resultado son
/// momentos del mismo socket, y separarlas en rutas obligaría a cerrarlo y
/// volver a abrirlo dos veces por duelo — con su ticket, su reconexión y su
/// ventana para que algo salga mal. Lo que cambia es lo que se pinta, no la
/// línea.
///
/// # Y por qué está fuera de la barra de navegación
///
/// Porque **salir de un duelo es perderlo** (RN-11). Con la barra puesta,
/// tocar cualquier icono sacaba al usuario de su partida: volviendo dentro de
/// 60 s se recuperaba, y pasado ese margen ya no. Eran cuatro formas de perder
/// sin que nadie avisara. La salida sigue existiendo, por la flecha de arriba,
/// que pregunta antes.
class DueloPartidaScreen extends ConsumerStatefulWidget {
  const DueloPartidaScreen({required this.dueloId, super.key});

  final String dueloId;

  @override
  ConsumerState<DueloPartidaScreen> createState() => _DueloPartidaScreenState();
}

class _DueloPartidaScreenState extends ConsumerState<DueloPartidaScreen> {
  bool _revisando = false;
  bool _aceptandoBot = false;
  bool _pidiendoRevancha = false;
  DueloDTO? _ficha;
  Object? _errorDeLaFicha;

  /// Si el rival ya pidió la revancha (RF-61).
  ///
  /// Se pregunta cada tres segundos porque en la pantalla de resultado **no
  /// hay socket**: la sala se cierra al terminar la partida, así que nadie
  /// puede avisar. Preguntar desde una pantalla en la que el usuario está
  /// parado no cuesta nada, y evita tocar el ciclo de vida de las conexiones.
  Timer? _vigilanteDeRevancha;
  DueloDTO? _revanchaPedida;

  @override
  void initState() {
    super.initState();
    unawaited(_cargarFicha());
  }

  @override
  void dispose() {
    _vigilanteDeRevancha?.cancel();
    super.dispose();
  }

  Future<void> _cargarFicha() async {
    try {
      final ficha = await ref
          .read(dueloRepositoryProvider)
          .duelo(widget.dueloId);
      if (!mounted) return;
      setState(() => _ficha = ficha);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorDeLaFicha = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(dueloControllerProvider(widget.dueloId));

    // El emparejador fusionó esta espera con otra: hay que ir a ese duelo. Sin
    // esto, el usuario se queda mirando un contador mientras su rival ya lo
    // espera en la otra sala.
    final mudadoA = estado.mudadoA;
    if (mudadoA != null && mudadoA.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.pushReplacement(Routes.dueloPartidaOf(mudadoA));
      });
    }

    _vigilarLaRevancha(estado);

    final rival = _nombreDelRival(estado);

    return PopScope(
      // Salir es perder: se pregunta antes, y solo mientras la partida está
      // viva. En la sala de espera y en el resultado no hay nada que perder.
      canPop: !_partidaViva(estado),
      onPopInvokedWithResult: (salio, _) async {
        if (salio || !mounted) return;
        // Se toma el router ANTES del diálogo: después, el `context` del build
        // cruzó un `await` y usarlo es justo lo que el análisis prohíbe.
        final router = GoRouter.of(context);
        final seguro = await confirmar(
          context,
          titulo: '¿Salir del duelo?',
          mensaje:
              'Si sales ahora pierdes la partida, aunque vayas ganando '
              '(RN-11).',
          confirmar: 'Salir y perder',
          cancelar: 'Seguir jugando',
          destructivo: true,
        );
        if (!seguro || !mounted) return;
        ref.read(dueloControllerProvider(widget.dueloId).notifier).abandonar();
        router.go(Routes.duelo);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_titulo(estado)),
          leading: IconButton(
            icon: const Icon(Symbols.arrow_back),
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
        body: SafeArea(child: _cuerpo(estado, rival)),
      ),
    );
  }

  Widget _cuerpo(EstadoDelDuelo estado, String rival) {
    if (estado.error != null) {
      return _Interrumpido(
        mensaje: estado.error!,
        onReintentar: () => ref
            .read(dueloControllerProvider(widget.dueloId).notifier)
            .reintentar(),
        onSalir: () => context.go(Routes.duelo),
      );
    }

    final resultado = estado.finalDelDuelo;
    if (resultado != null) {
      if (_revisando) {
        return RevisionDelDuelo(preguntas: resultado.revision, rival: rival);
      }
      return ResultadoDelDuelo(
        resultado: resultado,
        rival: rival,
        meRetan: _meRetan,
        pidiendoRevancha: _pidiendoRevancha,
        onRevancha: () => unawaited(_pedirRevancha()),
        onRevisar: () => setState(() => _revisando = true),
        onOtroOponente: () => context.go(Routes.duelo),
        onInicio: () => context.go(Routes.home),
      );
    }

    final jugando = estado.pregunta != null || estado.resultado != null;
    if (jugando) {
      return PartidaEnCurso(
        estado: estado,
        onResponder: (opcionId) => ref
            .read(dueloControllerProvider(widget.dueloId).notifier)
            .responder(opcionId),
      );
    }

    if (_errorDeLaFicha != null && _ficha == null) {
      return _Interrumpido(
        mensaje: 'No pudimos abrir este duelo.',
        onReintentar: _cargarFicha,
        onSalir: () => context.go(Routes.duelo),
      );
    }

    final ficha = _ficha;
    if (ficha == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SalaDeEspera(
      duelo: ficha,
      espera: estado.espera,
      sinRival: estado.sinRival,
      botBloqueado: estado.partida?.botBloqueado ?? false,
      aceptandoBot: _aceptandoBot,
      onAceptarBot: () => unawaited(_aceptarBot()),
    );
  }

  bool _partidaViva(EstadoDelDuelo estado) =>
      estado.finalDelDuelo == null &&
      estado.error == null &&
      (estado.pregunta != null || estado.resultado != null);

  String _titulo(EstadoDelDuelo estado) {
    if (estado.finalDelDuelo != null) return 'Resultado del duelo';
    if (estado.pregunta != null || estado.resultado != null) return 'Duelo';
    return 'Buscando rival';
  }

  String _nombreDelRival(EstadoDelDuelo estado) {
    final partida = estado.partida;
    if (partida != null && partida.rival.nombre.isNotEmpty) {
      return partida.rival.nombre;
    }
    final ficha = _ficha;
    if (ficha?.rival != null && ficha!.rival!.isNotEmpty) return ficha.rival!;
    return 'Tu rival';
  }

  Future<void> _aceptarBot() async {
    setState(() => _aceptandoBot = true);
    try {
      await ref.read(dueloRepositoryProvider).aceptarBot(widget.dueloId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_mensajeDe(e))));
    } finally {
      if (mounted) setState(() => _aceptandoBot = false);
    }
  }

  Future<void> _pedirRevancha() async {
    setState(() => _pidiendoRevancha = true);
    try {
      final nueva = await ref
          .read(dueloRepositoryProvider)
          .revancha(widget.dueloId);
      if (!mounted) return;
      context.pushReplacement(Routes.dueloPartidaOf(nueva.id));
    } catch (e) {
      if (!mounted) return;
      setState(() => _pidiendoRevancha = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_mensajeDe(e))));
    }
  }

  /// Solo interesa si la pidió el OTRO: la mía ya me llevó a su sala.
  bool get _meRetan =>
      _revanchaPedida != null &&
      !_revanchaPedida!.esTuyo &&
      _revanchaPedida!.estado == EstadoDuelo.esperando;

  void _vigilarLaRevancha(EstadoDelDuelo estado) {
    final resultado = estado.finalDelDuelo;

    // Con el pase diario no hay revancha, así que tampoco hay nada que
    // preguntar cada tres segundos.
    final procede = resultado != null && !resultado.conPaseGratis;

    if (!procede) {
      _vigilanteDeRevancha?.cancel();
      _vigilanteDeRevancha = null;
      return;
    }
    if (_vigilanteDeRevancha != null) return;

    _vigilanteDeRevancha = Timer.periodic(
      const Duration(seconds: 3),
      (_) => unawaited(_consultarRevancha()),
    );
    unawaited(_consultarRevancha());
  }

  Future<void> _consultarRevancha() async {
    try {
      final revancha = await ref
          .read(dueloRepositoryProvider)
          .revanchaDe(widget.dueloId);
      if (!mounted) return;
      setState(() => _revanchaPedida = revancha);
    } catch (_) {
      // 404 mientras nadie la haya pedido: es la respuesta normal, no un fallo.
    }
  }

  String _mensajeDe(Object e) {
    final texto = e.toString();
    return texto.isEmpty ? 'Algo salió mal.' : texto.replaceFirst('Exception: ', '');
  }
}

/// Lo que se ve cuando el duelo se cortó y no se puede seguir.
///
/// Sin esta pantalla, la partida se quedaba con la última pregunta puesta, el
/// reloj corriendo y las respuestas cayendo al vacío — con el mismo aspecto que
/// una partida sana. El usuario seguía jugando contra nadie.
class _Interrumpido extends StatelessWidget {
  const _Interrumpido({
    required this.mensaje,
    required this.onReintentar,
    required this.onSalir,
  });

  final String mensaje;
  final Future<void> Function() onReintentar;
  final VoidCallback onSalir;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Symbols.link_off, size: 48, color: scheme.onSurfaceVariant),
            const SizedBox(height: DesignTokens.space4),
            Text(
              'El duelo se interrumpió',
              style: texto.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.space2),
            Text(
              mensaje,
              style: texto.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.space6),
            EnamButton(
              label: 'Volver a intentarlo',
              icon: Symbols.refresh,
              onPressed: () => unawaited(onReintentar()),
            ),
            const SizedBox(height: DesignTokens.space3),
            TextButton(onPressed: onSalir, child: const Text('Salir del duelo')),
          ],
        ),
      ),
    );
  }
}
