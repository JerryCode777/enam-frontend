import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../../../core/theme/state_colors.dart';
import '../../data/aula_repository.dart';
import '../../domain/aula_models.dart';
import '../../domain/segundos_vistos.dart';
import '../aula_providers.dart';
import '../widgets/presentacion.dart';
import 'controles.dart';

/// El video de la clase, con sus controles.
///
/// ## Por qué `video_player` y controles propios
///
/// Las clases son MP4 H.264 servidos por CloudFront con rango. `video_player`
/// los reproduce con ExoPlayer en Android y AVPlayer en iOS, que piden por
/// rango solos, y trae el lector de WebVTT. Los controles son nuestros para
/// que los textos y las velocidades (1×, 1,25×, 1,5×, 2×) sean los del
/// diseño.
///
/// ## La URL caduca
///
/// La firma dura 4 h. Si el video falla, se pide la clase de nuevo
/// ([claseProvider]) y se sigue en la misma posición. Una sola vez por
/// minuto: si vuelve a fallar enseguida, no es la firma y se dice.
///
/// ## El progreso
///
/// Igual que la web (`useProgresoDeVideo.ts`): los segundos **distintos**
/// vistos ([SegundosVistos]), cada 15 s de reproducción, al pausar, al
/// terminar, al salir de la app y al cerrar la clase. El servidor la marca
/// completada al 90 %.
class ReproductorDeClase extends ConsumerStatefulWidget {
  const ReproductorDeClase({
    required this.clase,
    required this.alCompletar,
    super.key,
  });

  final Clase clase;

  /// Se cruzó el 90 %: la pantalla ya puede decir «Vista».
  final VoidCallback alCompletar;

  @override
  ConsumerState<ReproductorDeClase> createState() => EstadoDelReproductor();
}

/// El estado del reproductor, que los controles usan para mandar.
class EstadoDelReproductor extends ConsumerState<ReproductorDeClase>
    with WidgetsBindingObserver {
  static const velocidades = [1.0, 1.25, 1.5, 2.0];

  VideoPlayerController? _video;
  late final AulaRepository _repo;
  late final ProviderContainer _contenedor;
  late SegundosVistos _contador;

  /// Subtítulos a la vista. Un notificador y no `setState`: los controles
  /// también viven en la ruta de pantalla completa, fuera de este árbol.
  final subtitulos = ValueNotifier<bool>(true);
  final velocidad = ValueNotifier<double>(1);

  /// Si los controles están a la vista: los subtítulos se apartan de ellos.
  final controlesALaVista = ValueNotifier<bool>(true);

  /// Si hay pista de subtítulos que ofrecer.
  bool get conSubtitulos => widget.clase.subtitulosUrl != null;

  Object? _error;
  bool _renovando = false;
  DateTime? _ultimaRenovacion;

  Duration? _ultimaPosicion;

  /// La última posición buena. No es [_ultimaPosicion]: esa se borra al
  /// saltar, y la del controlador vuelve a cero cuando el video falla.
  Duration _posicionConocida = Duration.zero;
  Duration _sinEnviar = Duration.zero;
  bool _estabaReproduciendo = false;
  bool _finEnviado = false;
  (int, int)? _ultimoEnvio;
  late bool _completada;
  bool _avisoDelServidor = false;

  /// Dónde se retomó, para el aviso «Sigues donde lo dejaste».
  Duration? reanudadoEn;

  VideoPlayerController? get video => _video;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _repo = ref.read(aulaRepositoryProvider);
    _completada = widget.clase.progreso.completada;
    _contador = SegundosVistos(previos: widget.clase.progreso.segundosVistos);
    unawaited(_iniciar());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _contenedor = ProviderScope.containerOf(context, listen: false);
  }

  @override
  void didUpdateWidget(ReproductorDeClase oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Llegó la clase otra vez, con la firma nueva: se rehace el video donde
    // iba. Solo si la pedimos nosotros; si no, cambiar el video a la mitad
    // sería un salto que nadie pidió.
    if (_renovando && !identical(oldWidget.clase, widget.clase)) {
      final en = _posicionConocida;
      _renovando = false;
      unawaited(_iniciar(en: en, reproducir: true));
    }
  }

  Future<void> _iniciar({Duration? en, bool reproducir = false}) async {
    final url = widget.clase.videoUrl;
    if (url == null) return;

    final anterior = _video;
    anterior?.removeListener(_alCambiar);
    final vtt = widget.clase.subtitulosUrl;
    final c = VideoPlayerController.networkUrl(
      Uri.parse(url),
      closedCaptionFile: vtt == null ? null : _leerSubtitulos(vtt),
    );
    setState(() {
      _video = c;
      _error = null;
    });
    unawaited(anterior?.dispose());

    try {
      await c.initialize();
    } catch (e) {
      if (mounted && _video == c) _alFallar(e);
      return;
    }
    if (!mounted || _video != c) return;

    final destino = en ?? _dondeSeQuedo(c.value.duration);
    if (en == null && destino != null) reanudadoEn = destino;
    if (destino != null) await c.seekTo(destino);
    await c.setPlaybackSpeed(velocidad.value);
    c.addListener(_alCambiar);
    if (reproducir) await c.play();
    if (mounted) setState(() {});
  }

  /// La posición guardada, si vale la pena volver a ella: ni los primeros
  /// segundos ni los últimos, y no si ya se vio entera.
  Duration? _dondeSeQuedo(Duration duracion) {
    final p = widget.clase.progreso;
    if (p.completada) return null;
    final s = p.posicionS;
    if (s <= 5 || s >= duracion.inSeconds - 15) return null;
    return Duration(seconds: s);
  }

  /// El VTT, con un cliente aparte: la URL es de CloudFront y no lleva la
  /// cabecera de sesión de la API. Si no llega, la clase sigue sin
  /// subtítulos.
  static Future<ClosedCaptionFile> _leerSubtitulos(String url) async {
    try {
      final r = await Dio().get<String>(
        url,
        options: Options(responseType: ResponseType.plain),
      );
      return WebVTTCaptionFile(r.data ?? '');
    } catch (_) {
      return _SinSubtitulos();
    }
  }

  void _alCambiar() {
    final c = _video;
    if (c == null) return;
    final v = c.value;
    if (v.hasError) {
      _alFallar(v.errorDescription);
      return;
    }

    final reproduciendo = v.isPlaying && !v.isBuffering;
    _contador.registrar(v.position, reproduciendo: reproduciendo);
    if (_ultimaPosicion case final antes? when reproduciendo) {
      final paso = v.position - antes;
      if (paso > Duration.zero && paso <= const Duration(seconds: 2)) {
        _sinEnviar += paso;
      }
    }
    _ultimaPosicion = v.position;
    _posicionConocida = v.position;

    if (_sinEnviar >= const Duration(seconds: progresoCadaS)) {
      _sinEnviar = Duration.zero;
      unawaited(enviarProgreso());
    }
    if (_estabaReproduciendo && !v.isPlaying) {
      _contador.cortar();
      unawaited(enviarProgreso());
    }
    if (v.isCompleted && !_finEnviado) {
      _finEnviado = true;
      unawaited(enviarProgreso());
    }
    if (v.isPlaying != _estabaReproduciendo) {
      unawaited(v.isPlaying ? WakelockPlus.enable() : WakelockPlus.disable());
    }
    _estabaReproduciendo = v.isPlaying;
  }

  void _alFallar(Object? error) {
    if (_renovando) return;
    final ahora = DateTime.now();
    final reciente =
        _ultimaRenovacion != null &&
        ahora.difference(_ultimaRenovacion!) < const Duration(minutes: 1);
    if (reciente) {
      setState(() => _error = error ?? 'error');
      return;
    }
    // Lo más probable es que la firma caducara: se pide la clase de nuevo.
    _ultimaRenovacion = ahora;
    _renovando = true;
    ref.invalidate(claseProvider(widget.clase.id));
  }

  /// Lo visto, al servidor. Los fallos se tragan: el siguiente envío lleva
  /// el total y los corrige.
  Future<void> enviarProgreso() async {
    final c = _video;
    if (c == null || !c.value.isInitialized) return;
    final duracion = widget.clase.duracionS > 0
        ? widget.clase.duracionS
        : c.value.duration.inSeconds;
    final vistos = math.min(_contador.total, duracion);
    final posicion = c.value.position.inSeconds;
    if (_ultimoEnvio == (vistos, posicion)) return;
    _ultimoEnvio = (vistos, posicion);

    if (!_completada && completa(vistos, duracion)) {
      _completada = true;
      widget.alCompletar();
    }
    try {
      final p = await _repo.progreso(
        widget.clase.id,
        segundosVistos: vistos,
        posicionS: posicion,
      );
      if (p.completada && !_avisoDelServidor) {
        _avisoDelServidor = true;
        _refrescarAvance();
      }
    } catch (_) {}
  }

  void _refrescarAvance() {
    _contenedor
      ..invalidate(cursosProvider)
      ..invalidate(cursoProvider)
      ..invalidate(seguirViendoProvider);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // `paused` y no `inactive`: este último llega también al bajar la
    // cortina de notificaciones, y eso no es salir de la app.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      final c = _video;
      if (c != null && c.value.isPlaying) unawaited(c.pause());
      unawaited(enviarProgreso());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final c = _video;
    if (c != null) {
      c.removeListener(_alCambiar);
      // Lo último que se vio y, cuando el servidor lo tenga, el catálogo y el
      // temario al día: al volver se ve la clase como vista o a medias.
      unawaited(enviarProgreso().whenComplete(_refrescarAvance));
      unawaited(c.dispose());
    }
    unawaited(WakelockPlus.disable());
    subtitulos.dispose();
    velocidad.dispose();
    controlesALaVista.dispose();
    super.dispose();
  }

  // ---------- Lo que mandan los controles ----------

  Future<void> alternarReproduccion() async {
    final c = _video;
    if (c == null || !c.value.isInitialized) return;
    if (c.value.isPlaying) {
      await c.pause();
    } else {
      if (c.value.isCompleted) await irA(Duration.zero);
      await c.play();
    }
  }

  /// Un salto: lo que se salta no cuenta como visto.
  Future<void> irA(Duration posicion) async {
    final c = _video;
    if (c == null) return;
    _contador.cortar();
    _ultimaPosicion = null;
    _finEnviado = false;
    final tope = c.value.duration;
    await c.seekTo(
      posicion < Duration.zero
          ? Duration.zero
          : (posicion > tope ? tope : posicion),
    );
  }

  Future<void> cambiarVelocidad(double v) async {
    velocidad.value = v;
    await _video?.setPlaybackSpeed(v);
  }

  void quitarAvisoDeReanudar() {
    if (reanudadoEn == null) return;
    setState(() => reanudadoEn = null);
  }

  /// En horizontal y sin barras del sistema, con el mismo video.
  Future<void> abrirPantallaCompleta() async {
    final c = _video;
    if (c == null) return;
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    if (!mounted) return;
    await Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => _PantallaCompleta(estado: this),
        transitionsBuilder: (_, animacion, _, hijo) =>
            FadeTransition(opacity: animacion, child: hijo),
      ),
    );
    // Como en main.dart: la app se estudia en vertical.
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  Future<void> reintentar() async {
    _ultimaRenovacion = null;
    setState(() => _error = null);
    _alFallar(null);
  }

  @override
  Widget build(BuildContext context) {
    final c = _video;
    final clase = widget.clase;

    final Widget contenido;
    if (_error != null) {
      contenido = _Fallo(alReintentar: reintentar);
    } else if (c == null || !c.value.isInitialized) {
      contenido = Stack(
        fit: StackFit.expand,
        children: [
          if (clase.miniaturaUrl case final url?) ImagenFirmada(url: url),
          const Center(child: CircularProgressIndicator(color: Colors.white)),
        ],
      );
    } else {
      contenido = LienzoDeVideo(estado: this, pantallaCompleta: false);
    }

    final video = Semantics(
      label: 'Video de la clase: ${clase.titulo}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        child: ColoredBox(
          color: Colors.black,
          child: AspectRatio(aspectRatio: 16 / 9, child: contenido),
        ),
      ),
    );

    final reanudado = reanudadoEn;
    if (reanudado == null) return video;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        video,
        const SizedBox(height: DesignTokens.space2),
        _AvisoDeReanudar(
          en: reanudado,
          alEmpezarDeCero: () {
            quitarAvisoDeReanudar();
            unawaited(irA(Duration.zero));
          },
          alCerrar: quitarAvisoDeReanudar,
        ),
      ],
    );
  }
}

/// El video, sus subtítulos y los controles encima. El mismo en la página y
/// en pantalla completa.
class LienzoDeVideo extends StatelessWidget {
  const LienzoDeVideo({
    required this.estado,
    required this.pantallaCompleta,
    super.key,
  });

  final EstadoDelReproductor estado;
  final bool pantallaCompleta;

  @override
  Widget build(BuildContext context) {
    final c = estado.video!;
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: c.value.aspectRatio,
            child: VideoPlayer(c),
          ),
        ),
        _Subtitulos(estado: estado, grande: pantallaCompleta),
        ControlesDelVideo(estado: estado, pantallaCompleta: pantallaCompleta),
      ],
    );
  }
}

class _Subtitulos extends StatelessWidget {
  const _Subtitulos({required this.estado, required this.grande});

  final EstadoDelReproductor estado;
  final bool grande;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        estado.subtitulos,
        estado.controlesALaVista,
      ]),
      builder: (context, _) {
        if (!estado.subtitulos.value) return const SizedBox.shrink();
        final controles = estado.controlesALaVista.value;
        // En la página el video es bajo: con los controles a la vista no hay
        // sitio para el texto sin tapar los botones, así que se aparta, como
        // en YouTube. En pantalla completa sube por encima de la barra.
        if (controles && !grande) return const SizedBox.shrink();
        final abajo = controles ? 96.0 : (grande ? 40.0 : 12.0);
        return ValueListenableBuilder<VideoPlayerValue>(
          valueListenable: estado.video!,
          builder: (context, v, _) {
            final texto = v.caption.text.trim();
            if (texto.isEmpty) return const SizedBox.shrink();
            return Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  DesignTokens.space4,
                  0,
                  DesignTokens.space4,
                  abajo,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.space2,
                      vertical: 2,
                    ),
                    child: Text(
                      texto,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: grande ? 18 : 14,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _PantallaCompleta extends StatelessWidget {
  const _PantallaCompleta({required this.estado});

  final EstadoDelReproductor estado;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: estado.video == null
          ? const SizedBox.shrink()
          : LienzoDeVideo(estado: estado, pantallaCompleta: true),
    );
  }
}

/// «Sigues donde lo dejaste», con la salida para empezar de cero.
class _AvisoDeReanudar extends StatelessWidget {
  const _AvisoDeReanudar({
    required this.en,
    required this.alEmpezarDeCero,
    required this.alCerrar,
  });

  final Duration en;
  final VoidCallback alEmpezarDeCero;
  final VoidCallback alCerrar;

  @override
  Widget build(BuildContext context) {
    final info = context.states.info;
    return Container(
      padding: const EdgeInsets.only(left: DesignTokens.space3),
      decoration: BoxDecoration(
        color: info.tint,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Sigues donde lo dejaste, en el ${posicionEnTexto(en)}.',
              style: context.texts.bodySmall?.copyWith(
                color: info.onTint,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: alEmpezarDeCero,
            child: const Text('Desde el inicio'),
          ),
          IconButton(
            tooltip: 'Cerrar',
            onPressed: alCerrar,
            icon: Icon(Symbols.close, size: 18, color: info.onTint),
          ),
        ],
      ),
    );
  }
}

class _Fallo extends StatelessWidget {
  const _Fallo({required this.alReintentar});

  final VoidCallback alReintentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'No pudimos reproducir la clase.',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: DesignTokens.space2),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white54),
            ),
            onPressed: alReintentar,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

class _SinSubtitulos extends ClosedCaptionFile {
  _SinSubtitulos();

  @override
  List<Caption> get captions => const [];
}
