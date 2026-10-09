import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'sonidos.dart';

/// Los sonidos de la app, uno para toda ella.
///
/// Se crea una vez y vive lo que la aplicación: abrir un reproductor por cada
/// toque tarda más que el propio sonido. La preferencia se le empuja cuando
/// cambia, sin recrear los reproductores (sería un chasquido).
final sonidosProvider = Provider<Sonidos>((ref) {
  final sonidos = Sonidos(reproductores: ref.read(reproductoresDeSonido));
  ref.onDispose(sonidos.cerrar);

  void aplicar(PreferenciasSonido p) => sonidos
    ..activo = p.activo
    ..volumen = p.volumen;

  aplicar(ref.read(preferenciasSonidoProvider));
  ref.listen(preferenciasSonidoProvider, (_, p) => aplicar(p));
  return sonidos;
});

/// Los reproductores que usan los sonidos. Nulo = los de verdad. Las pruebas
/// ponen aquí uno que anota lo que suena.
final reproductoresDeSonido = Provider<List<Reproductor>?>((ref) => null);

/// Lo que se recuerda del sonido entre sesiones.
class PreferenciasSonido {
  const PreferenciasSonido({this.activo = true, this.volumen = 0.6});

  final bool activo;

  /// De 0 a 1.
  final double volumen;

  PreferenciasSonido copiaCon({bool? activo, double? volumen}) =>
      PreferenciasSonido(
        activo: activo ?? this.activo,
        volumen: volumen ?? this.volumen,
      );
}

/// Guarda el interruptor y el volumen en el teléfono (`shared_preferences`,
/// con las mismas claves que Rumbo). Por defecto, activos a 0,6.
///
/// Arranca con los valores por defecto y aplica lo guardado en cuanto lo lee:
/// esperar una preferencia de comodidad no puede retrasar la app.
class ControladorSonido extends Notifier<PreferenciasSonido> {
  static const _claveActivo = 'sonido_activo';
  static const _claveVolumen = 'sonido_volumen';

  bool _cambiadoEnEstaSesion = false;

  @override
  PreferenciasSonido build() {
    unawaited(_cargar());
    return const PreferenciasSonido();
  }

  Future<void> _cargar() async {
    try {
      final p = await SharedPreferences.getInstance();
      if (_cambiadoEnEstaSesion || !ref.mounted) return;
      state = PreferenciasSonido(
        activo: p.getBool(_claveActivo) ?? true,
        volumen: p.getDouble(_claveVolumen) ?? 0.6,
      );
    } catch (_) {
      // Sin preferencias legibles, los valores por defecto.
    }
  }

  Future<void> cambiarActivo(bool activo) async {
    _cambiadoEnEstaSesion = true;
    state = state.copiaCon(activo: activo);
    try {
      await (await SharedPreferences.getInstance()).setBool(
        _claveActivo,
        activo,
      );
    } catch (_) {}
  }

  Future<void> cambiarVolumen(double volumen) async {
    _cambiadoEnEstaSesion = true;
    state = state.copiaCon(volumen: volumen.clamp(0.0, 1.0));
    try {
      await (await SharedPreferences.getInstance()).setDouble(
        _claveVolumen,
        state.volumen,
      );
    } catch (_) {}
  }
}

final preferenciasSonidoProvider =
    NotifierProvider<ControladorSonido, PreferenciasSonido>(
      ControladorSonido.new,
    );

/// Atajo para las pantallas: `ref.sonar(Sonido.toque)`. No espera: un sonido
/// no retrasa nada.
extension SonarDesdeWidget on WidgetRef {
  void sonar(Sonido sonido) => unawaited(read(sonidosProvider).sonar(sonido));
}
