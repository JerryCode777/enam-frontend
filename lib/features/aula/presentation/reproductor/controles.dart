import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../domain/segundos_vistos.dart';
import 'reproductor_de_clase.dart';

/// «1×», «1,25×», «1,5×», «2×»: con coma, como se escribe aquí.
String velocidadEnTexto(double v) {
  final texto = v == v.roundToDouble()
      ? v.toStringAsFixed(0)
      : v.toString().replaceAll('.', ',');
  return '$texto×';
}

/// Los controles sobre el video.
///
/// Un toque los muestra u oculta; reproduciendo, se ocultan solos a los 3 s
/// para no tapar la clase. Son los mismos en la página y en pantalla completa.
class ControlesDelVideo extends StatefulWidget {
  const ControlesDelVideo({
    required this.estado,
    required this.pantallaCompleta,
    super.key,
  });

  final EstadoDelReproductor estado;
  final bool pantallaCompleta;

  @override
  State<ControlesDelVideo> createState() => _ControlesDelVideoState();
}

class _ControlesDelVideoState extends State<ControlesDelVideo> {
  static const _salto = Duration(seconds: 10);

  bool _visibles = true;
  Timer? _temporizador;

  /// Mientras se arrastra la barra, la posición que se está eligiendo.
  double? _arrastrando;

  EstadoDelReproductor get _estado => widget.estado;

  @override
  void initState() {
    super.initState();
    _programarOcultar();
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    super.dispose();
  }

  void _programarOcultar() {
    _temporizador?.cancel();
    _temporizador = Timer(const Duration(seconds: 3), () {
      final v = _estado.video?.value;
      if (mounted && (v?.isPlaying ?? false) && _arrastrando == null) {
        setState(() => _visibles = false);
      }
    });
  }

  /// Toda acción vuelve a mostrar los controles y reinicia la cuenta.
  void _tocado([VoidCallback? accion]) {
    accion?.call();
    if (!_visibles) setState(() => _visibles = true);
    _programarOcultar();
  }

  @override
  Widget build(BuildContext context) {
    final video = _estado.video!;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (_visibles) {
          setState(() => _visibles = false);
        } else {
          _tocado();
        }
      },
      child: ValueListenableBuilder<VideoPlayerValue>(
        valueListenable: video,
        builder: (context, v, _) {
          // En pausa, a la vista: si no, no se sabe cómo seguir.
          final visibles = _visibles || !v.isPlaying;
          // Para los subtítulos, que se apartan. Después del cuadro: avisar
          // durante la construcción reconstruiría otro widget a medias.
          if (_estado.controlesALaVista.value != visibles) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _estado.controlesALaVista.value = visibles;
            });
          }
          return AnimatedOpacity(
            opacity: visibles ? 1 : 0,
            duration: DesignTokens.durationNormal,
            child: IgnorePointer(
              ignoring: !visibles,
              child: _Capa(
                valor: v,
                pantallaCompleta: widget.pantallaCompleta,
                arrastrando: _arrastrando,
                conSubtitulos: _estado.conSubtitulos,
                subtitulos: _estado.subtitulos,
                velocidad: _estado.velocidad,
                alAlternar: () => _tocado(_estado.alternarReproduccion),
                alRetroceder: () =>
                    _tocado(() => _estado.irA(v.position - _salto)),
                alAvanzar: () =>
                    _tocado(() => _estado.irA(v.position + _salto)),
                alArrastrar: (s) {
                  _temporizador?.cancel();
                  setState(() => _arrastrando = s);
                },
                alSoltar: (s) {
                  setState(() => _arrastrando = null);
                  _tocado(() => _estado.irA(Duration(seconds: s.round())));
                },
                alSubtitulos: () => _tocado(
                  () => _estado.subtitulos.value = !_estado.subtitulos.value,
                ),
                alVelocidad: (x) => _tocado(() => _estado.cambiarVelocidad(x)),
                alPantallaCompleta: () => _tocado(() {
                  if (widget.pantallaCompleta) {
                    Navigator.of(context).pop();
                  } else {
                    unawaited(_estado.abrirPantallaCompleta());
                  }
                }),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Capa extends StatelessWidget {
  const _Capa({
    required this.valor,
    required this.pantallaCompleta,
    required this.arrastrando,
    required this.conSubtitulos,
    required this.subtitulos,
    required this.velocidad,
    required this.alAlternar,
    required this.alRetroceder,
    required this.alAvanzar,
    required this.alArrastrar,
    required this.alSoltar,
    required this.alSubtitulos,
    required this.alVelocidad,
    required this.alPantallaCompleta,
  });

  final VideoPlayerValue valor;
  final bool pantallaCompleta;
  final double? arrastrando;
  final bool conSubtitulos;
  final ValueNotifier<bool> subtitulos;
  final ValueNotifier<double> velocidad;
  final VoidCallback alAlternar;
  final VoidCallback alRetroceder;
  final VoidCallback alAvanzar;
  final ValueChanged<double> alArrastrar;
  final ValueChanged<double> alSoltar;
  final VoidCallback alSubtitulos;
  final ValueChanged<double> alVelocidad;
  final VoidCallback alPantallaCompleta;

  @override
  Widget build(BuildContext context) {
    final duracion = valor.duration.inSeconds.toDouble();
    final posicion = (arrastrando ?? valor.position.inSeconds.toDouble()).clamp(
      0.0,
      duracion > 0 ? duracion : 0.0,
    );
    final terminado = valor.isCompleted && !valor.isPlaying;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x66000000), Color(0x22000000), Color(0xAA000000)],
          stops: [0, 0.5, 1],
        ),
      ),
      child: Stack(
        children: [
          if (pantallaCompleta)
            Positioned(
              top: DesignTokens.space2,
              left: DesignTokens.space2,
              child: _Boton(
                icono: Symbols.arrow_back,
                etiqueta: 'Salir de pantalla completa',
                alTocar: alPantallaCompleta,
              ),
            ),
          Center(
            child: valor.isBuffering && !terminado
                ? const SizedBox.square(
                    dimension: 48,
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Boton(
                        icono: Symbols.replay_10,
                        etiqueta: 'Atrás 10 segundos',
                        alTocar: alRetroceder,
                        tamano: 30,
                      ),
                      const SizedBox(width: DesignTokens.space6),
                      _Boton(
                        icono: terminado
                            ? Symbols.replay
                            : valor.isPlaying
                            ? Symbols.pause
                            : Symbols.play_arrow,
                        etiqueta: terminado
                            ? 'Ver de nuevo'
                            : valor.isPlaying
                            ? 'Pausar'
                            : 'Reproducir',
                        alTocar: alAlternar,
                        tamano: 44,
                        relleno: true,
                      ),
                      const SizedBox(width: DesignTokens.space6),
                      _Boton(
                        icono: Symbols.forward_10,
                        etiqueta: 'Adelante 10 segundos',
                        alTocar: alAvanzar,
                        tamano: 30,
                      ),
                    ],
                  ),
          ),
          Positioned(
            left: DesignTokens.space2,
            right: DesignTokens.space2,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 14,
                    ),
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Colors.white30,
                    thumbColor: Colors.white,
                  ),
                  child: SizedBox(
                    height: 24,
                    child: Slider(
                      value: posicion,
                      max: duracion > 0 ? duracion : 1,
                      semanticFormatterCallback: (s) =>
                          posicionEnTexto(Duration(seconds: s.round())),
                      onChanged: duracion > 0 ? alArrastrar : null,
                      onChangeEnd: duracion > 0 ? alSoltar : null,
                    ),
                  ),
                ),
                Row(
                  children: [
                    const SizedBox(width: DesignTokens.space2),
                    Text(
                      '${posicionEnTexto(Duration(seconds: posicion.round()))}'
                      ' / ${posicionEnTexto(valor.duration)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const Spacer(),
                    if (conSubtitulos)
                      ValueListenableBuilder<bool>(
                        valueListenable: subtitulos,
                        builder: (context, activos, _) => _Boton(
                          icono: activos
                              ? Symbols.closed_caption
                              : Symbols.closed_caption_disabled,
                          etiqueta: activos
                              ? 'Ocultar subtítulos'
                              : 'Mostrar subtítulos',
                          alTocar: alSubtitulos,
                          relleno: activos,
                        ),
                      ),
                    ValueListenableBuilder<double>(
                      valueListenable: velocidad,
                      builder: (context, actual, _) =>
                          _Velocidad(actual: actual, alElegir: alVelocidad),
                    ),
                    _Boton(
                      icono: pantallaCompleta
                          ? Symbols.fullscreen_exit
                          : Symbols.fullscreen,
                      etiqueta: pantallaCompleta
                          ? 'Salir de pantalla completa'
                          : 'Pantalla completa',
                      alTocar: alPantallaCompleta,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Velocidad extends StatelessWidget {
  const _Velocidad({required this.actual, required this.alElegir});

  final double actual;
  final ValueChanged<double> alElegir;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<double>(
      tooltip: 'Velocidad',
      initialValue: actual,
      onSelected: alElegir,
      itemBuilder: (context) => [
        for (final v in EstadoDelReproductor.velocidades)
          PopupMenuItem(value: v, child: Text(velocidadEnTexto(v))),
      ],
      child: Semantics(
        label: 'Velocidad ${velocidadEnTexto(actual)}',
        button: true,
        excludeSemantics: true,
        child: Container(
          constraints: const BoxConstraints(
            minWidth: DesignTokens.minTouchTarget,
            minHeight: DesignTokens.minTouchTarget,
          ),
          alignment: Alignment.center,
          child: Text(
            velocidadEnTexto(actual),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _Boton extends StatelessWidget {
  const _Boton({
    required this.icono,
    required this.etiqueta,
    required this.alTocar,
    this.tamano = 24,
    this.relleno = false,
  });

  final IconData icono;
  final String etiqueta;
  final VoidCallback alTocar;
  final double tamano;
  final bool relleno;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: etiqueta,
      onPressed: alTocar,
      icon: Icon(icono, size: tamano, fill: relleno ? 1 : 0),
      color: Colors.white,
    );
  }
}
