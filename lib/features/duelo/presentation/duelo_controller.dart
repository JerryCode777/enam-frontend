import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/duelo_socket.dart';

/// Conecta el motor del duelo con las pantallas.
///
/// # Por qué es un `Notifier` y no un `AsyncNotifier`
///
/// Porque aquí no hay «cargando, listo, error» que valga: la conexión se cae y
/// vuelve dentro de la misma partida, y eso no es un estado de carga, es parte
/// del juego. Con `AsyncValue`, cada reconexión repintaría la pantalla como si
/// estuviera cargando de cero y el usuario perdería de vista su pregunta.
///
/// # Uno por duelo, y por qué importa
///
/// Es `family` por el id del duelo, así que pedir otro duelo crea otro motor
/// desde cero. Ese detalle es la revancha: se navega de `/duelo/partida/A` a
/// `/duelo/partida/B` sin salir de la pantalla, y sin esto el estado del duelo
/// anterior sobreviviría — con su resultado final todavía puesto. En la web
/// pasó exactamente eso: se pulsaba «Revancha», el servidor la creaba bien, y
/// en pantalla no ocurría nada.
class DueloController extends Notifier<EstadoDelDuelo> {
  DueloController(this.dueloId);

  final String dueloId;

  DueloSocket? _motor;

  @override
  EstadoDelDuelo build() {
    final motor = DueloSocket(
      repositorio: ref.read(dueloRepositoryProvider),
      dueloId: dueloId,
    );
    _motor = motor;

    final escucha = motor.estados.listen((nuevo) => state = nuevo);

    // El orden importa: primero se corta la escucha y después se cierra el
    // motor. Al revés, el cierre emite y la escucha intenta tocar un provider
    // que ya no existe.
    ref.onDispose(() async {
      await escucha.cancel();
      await motor.cerrar();
    });

    unawaited(motor.conectar());
    return motor.estado;
  }

  /// Manda la respuesta y devuelve **si salió de verdad**.
  ///
  /// La pantalla necesita saberlo: un socket cerrado se traga lo que le echen,
  /// y dar por contestada una pregunta que nunca llegó es peor que decir que
  /// no salió.
  bool responder(String? opcionId) => _motor?.responder(opcionId) ?? false;

  void abandonar() => _motor?.abandonar();

  Future<void> reintentar() async => _motor?.reintentar();
}

final dueloControllerProvider =
    NotifierProvider.family<DueloController, EstadoDelDuelo, String>(
      DueloController.new,
    );
