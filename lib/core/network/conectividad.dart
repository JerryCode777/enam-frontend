import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Si el teléfono tiene una red a la que agarrarse.
///
/// **Lo que esto sabe y lo que no.** El sistema informa de la *interfaz* —wifi,
/// datos, nada—, no de si hay internet de verdad: un wifi de hotel que pide
/// contraseña en el navegador aparece como conectado. Por eso la app **no**
/// decide con esto si una petición va a funcionar; para eso está el fallo real
/// de la petición, que es el único juez fiable.
///
/// Aquí se usa para dos cosas honestas:
/// - avisar en pantalla de que se está sin conexión;
/// - saber **cuándo volver a intentar** sincronizar, que es justo cuando
///   aparece una interfaz nueva.
abstract interface class Conectividad {
  /// Si ahora mismo hay alguna interfaz de red.
  Future<bool> hayRed();

  /// Emite en cada cambio. `true` cuando aparece una red.
  Stream<bool> get cambios;
}

class ConectividadDelSistema implements Conectividad {
  ConectividadDelSistema({Connectivity? plugin})
    : _plugin = plugin ?? Connectivity();

  final Connectivity _plugin;

  @override
  Future<bool> hayRed() async => _hayRed(await _plugin.checkConnectivity());

  @override
  Stream<bool> get cambios => _plugin.onConnectivityChanged.map(_hayRed);

  static bool _hayRed(List<ConnectivityResult> resultados) =>
      resultados.any((r) => r != ConnectivityResult.none);
}

/// Para pruebas y para el modo con mocks: se controla a mano.
class ConectividadFalsa implements Conectividad {
  ConectividadFalsa({bool conectado = true}) : _conectado = conectado;

  bool _conectado;
  final _control = StreamController<bool>.broadcast();

  @override
  Future<bool> hayRed() async => _conectado;

  @override
  Stream<bool> get cambios => _control.stream;

  /// Simula que se cae o vuelve la señal.
  void cambiar({required bool conectado}) {
    _conectado = conectado;
    _control.add(conectado);
  }

  Future<void> cerrar() => _control.close();
}
