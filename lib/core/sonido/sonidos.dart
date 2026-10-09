import 'dart:async';
import 'dart:io' show Platform;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../domain/blueprint.dart';

/// Los sonidos de la app: los mismos siete de Rumbo, la app hermana del mismo
/// dueño, con sus mismos archivos.
///
/// Los WAV originales se pasaron a MP3 mono de 96 kbps (el formato de la
/// web): de 2,1 MB a 142 KB, con el mismo efecto. El de pestaña sigue en
/// `.m4a` porque el original es `.ogg`, que iOS no reproduce.
enum Sonido {
  /// Tocar algo que decide: una alternativa, una tarjeta.
  toque('sonidos/click_normal.mp3'),

  /// Cambiar de pestaña. Más corto que el toque: moverse no es decidir.
  pestana('sonidos/select_002.m4a'),

  /// Empieza una práctica, un simulacro, un examen pasado o un duelo.
  empiezaQuiz('sonidos/start_quiz.mp3'),

  /// Solo cuando la pantalla revela si se acertó. **Nunca** en un simulacro
  /// ni en un examen cronometrado: la clave está oculta hasta el final y el
  /// sonido la delataría (RF-16).
  acierto('sonidos/good_answer.mp3'),
  fallo('sonidos/bad_answer.mp3'),

  /// Al ver el resultado. Ver [sonidoDeResultado].
  buenResultado('sonidos/good_score.mp3'),
  malResultado('sonidos/bad_score.mp3');

  const Sonido(this.archivo);

  final String archivo;
}

/// El sonido del resultado: bueno con nota aprobatoria (11 o más), malo si no.
Sonido sonidoDeResultado({required double nota}) =>
    Blueprint.isPassing(nota) ? Sonido.buenResultado : Sonido.malResultado;

/// Lo que de verdad hace sonar un archivo. Se sustituye en las pruebas.
abstract interface class Reproductor {
  Future<void> reproducir(String archivo, double volumen);
  Future<void> cerrar();
}

/// Reproduce los sonidos de la interfaz.
///
/// Varios reproductores en rotación en vez de uno: con uno solo, tocar dos
/// alternativas seguidas corta el sonido de la primera, y se nota. Es el mismo
/// arreglo que hace Rumbo.
class Sonidos {
  Sonidos({List<Reproductor>? reproductores})
    : _reproductores =
          reproductores ?? List.generate(3, (_) => _crearReproductor());

  final List<Reproductor> _reproductores;
  int _siguiente = 0;

  /// Si suena o no. Silenciarlo es una preferencia —hay quien estudia en
  /// clase—; quien la guarda es `ControladorSonido`.
  bool activo = true;

  /// De 0 a 1. Por defecto 0,6, como Rumbo: los sonidos acompañan, no
  /// anuncian.
  double volumen = 0.6;

  /// Suena, y si falla no pasa nada.
  ///
  /// Un sonido que no se puede reproducir no puede tumbar una respuesta ni
  /// interrumpir un duelo. Se traga a propósito.
  Future<void> sonar(Sonido sonido) async {
    if (!activo || volumen <= 0) return;
    final reproductor = _reproductores[_siguiente];
    _siguiente = (_siguiente + 1) % _reproductores.length;
    try {
      await reproductor.reproducir(sonido.archivo, volumen);
    } on Object catch (error) {
      debugPrint('sonido «${sonido.name}» no se pudo reproducir: $error');
    }
  }

  Future<void> cerrar() async {
    for (final r in _reproductores) {
      await r.cerrar();
    }
  }
}

/// En `flutter test` no hay altavoz ni plugin de audio: crear un reproductor
/// de verdad lanzaría errores del canal nativo en cualquier prueba que toque
/// una alternativa. Ahí se usa uno mudo; las pruebas del sonido inyectan el
/// suyo.
Reproductor _crearReproductor() {
  final enPruebas = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
  return enPruebas ? _Mudo() : _ReproductorAudioplayers();
}

class _Mudo implements Reproductor {
  @override
  Future<void> reproducir(String archivo, double volumen) async {}

  @override
  Future<void> cerrar() async {}
}

class _ReproductorAudioplayers implements Reproductor {
  _ReproductorAudioplayers() {
    unawaited(_configurarUnaVez());
  }

  final _jugador = AudioPlayer()..setReleaseMode(ReleaseMode.stop);

  static bool _configurado = false;

  /// Sonidos de interfaz, no música:
  ///
  /// - **iOS**: categoría `ambient`. Respeta el interruptor de silencio y se
  ///   mezcla con lo que suene, sin cortar la música de quien estudia con ella.
  /// - **Android**: uso de «sonido de interfaz» (`assistanceSonification`),
  ///   que sigue el modo silencio, y **sin pedir el foco de audio**: la música
  ///   no se pausa por un clic.
  static Future<void> _configurarUnaVez() async {
    if (_configurado) return;
    _configurado = true;
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.ambient,
            options: const {AVAudioSessionOptions.mixWithOthers},
          ),
          android: const AudioContextAndroid(
            usageType: AndroidUsageType.assistanceSonification,
            contentType: AndroidContentType.sonification,
            audioFocus: AndroidAudioFocus.none,
          ),
        ),
      );
    } on Object catch (error) {
      debugPrint('no se pudo configurar el audio: $error');
    }
  }

  @override
  Future<void> reproducir(String archivo, double volumen) async {
    await _jugador.stop();
    await _jugador.play(AssetSource(archivo), volume: volumen);
  }

  @override
  Future<void> cerrar() => _jugador.dispose();
}
