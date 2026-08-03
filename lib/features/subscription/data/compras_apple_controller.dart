import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/error/failure.dart';
import 'apple_iap_service.dart';
import 'subscription_repository.dart';

/// En qué punto está la compra, para que la pantalla lo pueda contar.
enum EstadoCompra {
  /// Nada en marcha.
  quieto,

  /// La hoja de Apple está abierta, o el cobro en curso.
  comprando,

  /// Apple ya cobró y estamos registrándolo en el servidor.
  ///
  /// Se distingue de [comprando] porque aquí el dinero YA salió: si algo falla,
  /// el mensaje no puede ser «no se pudo comprar».
  registrando,

  listo,
  error,
}

/// El resultado de una compra, tal como lo necesita la pantalla.
typedef ResultadoCompra = ({EstadoCompra estado, String? mensaje});

/// Orquesta una compra de la App Store de punta a punta.
///
/// El orden importa y es el único que evita que alguien pague sin recibir nada:
///
///  1. Apple cobra y entrega la transacción firmada.
///  2. Se manda al servidor, que la verifica y da el acceso.
///  3. **Solo entonces** se le confirma la compra a Apple.
///
/// Si el paso 2 falla, el 3 no ocurre, y StoreKit vuelve a entregar esa misma
/// transacción en el siguiente arranque de la app. El usuario no tiene que hacer
/// nada: la próxima vez que abra la app con red, entra sola. Confirmarle la
/// compra a Apple antes de tiempo la borraría de esa cola y el dinero se habría
/// cobrado sin dar acceso.
class ComprasAppleController {
  ComprasAppleController({
    required AppleIapService tienda,
    required SubscriptionRepository suscripciones,
  }) : _tienda = tienda,
       _suscripciones = suscripciones;

  final AppleIapService _tienda;
  final SubscriptionRepository _suscripciones;

  StreamSubscription<List<PurchaseDetails>>? _escucha;

  final _resultados = StreamController<ResultadoCompra>.broadcast();

  /// Lo que le va pasando a la compra en curso.
  Stream<ResultadoCompra> get resultados => _resultados.stream;

  /// Se llama al abrir la pantalla de compra.
  ///
  /// Al suscribirse, StoreKit entrega también las transacciones que quedaron sin
  /// completar en sesiones anteriores. Ahí es donde se recupera solo quien pagó
  /// y se quedó sin acceso porque falló la red.
  void escuchar() {
    _escucha ??= _tienda.compras.listen(_atender);
  }

  Future<void> soltar() async {
    await _escucha?.cancel();
    _escucha = null;
    await _resultados.close();
  }

  Future<List<ProductDetails>> productos() => _tienda.productos();

  Future<void> comprar(ProductDetails producto) async {
    _emitir(EstadoCompra.comprando);
    try {
      await _tienda.comprar(producto);
    } catch (e) {
      _emitir(EstadoCompra.error, 'No pudimos abrir la compra. $e');
    }
  }

  Future<void> restaurar() async {
    _emitir(EstadoCompra.comprando);
    try {
      await _tienda.restaurar();
    } catch (e) {
      _emitir(EstadoCompra.error, 'No pudimos restaurar tus compras. $e');
    }
  }

  Future<void> _atender(List<PurchaseDetails> compras) async {
    for (final compra in compras) {
      switch (compra.status) {
        case PurchaseStatus.pending:
          _emitir(EstadoCompra.comprando);

        case PurchaseStatus.canceled:
          // Cancelar no es un error: quien cierra la hoja de Apple no ha hecho
          // nada mal y no tiene que ver un mensaje rojo.
          _emitir(EstadoCompra.quieto);
          await _tienda.completar(compra);

        case PurchaseStatus.error:
          _emitir(
            EstadoCompra.error,
            compra.error?.message ?? 'La compra no se pudo completar.',
          );
          // Se completa igualmente: una compra fallida que quede en la cola
          // reaparecería en cada arranque enseñando el mismo error para siempre.
          await _tienda.completar(compra);

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _registrar(compra);
      }
    }
  }

  Future<void> _registrar(PurchaseDetails compra) async {
    _emitir(EstadoCompra.registrando);

    final jws = compra.verificationData.serverVerificationData;
    if (jws.isEmpty) {
      // Sin transacción firmada no hay nada que verificar. NO se completa: si
      // es un fallo pasajero de StoreKit, reaparecerá con los datos completos.
      _emitir(
        EstadoCompra.error,
        'Tu compra se registró en Apple pero aún no llega. Vuelve a abrir la '
        'app en un momento y se activará sola.',
      );
      return;
    }

    try {
      await _suscripciones.canjearCompraApple(jws);
    } on Failure catch (e) {
      // El dinero ya salió. El mensaje tiene que decir eso y tranquilizar, no
      // sugerir que vuelva a pagar.
      _emitir(EstadoCompra.error, _mensajeDeFallo(e));
      return;
    } catch (_) {
      _emitir(EstadoCompra.error, _mensajeGenerico);
      return;
    }

    // Solo aquí: el servidor ya dio el acceso, así que la transacción puede
    // salir de la cola de Apple sin riesgo.
    await _tienda.completar(compra);
    _emitir(EstadoCompra.listo);
  }

  static const _mensajeGenerico =
      'Tu pago se hizo, pero no pudimos activarlo todavía. No pagues de nuevo: '
      'vuelve a abrir la app con conexión y se activará solo.';

  /// Se enumera lo PASAJERO, no lo definitivo.
  ///
  /// Al revés se rompería sola: cada vez que el servidor aprendiera a rechazar
  /// algo nuevo, ese caso caería por defecto en «vuelve a abrir la app y se
  /// activará solo», que es una promesa falsa. Así, lo que no se reconoce se
  /// cuenta con las palabras del servidor, que al menos son ciertas.
  String _mensajeDeFallo(Failure e) => switch (e) {
    NetworkFailure() ||
    TimeoutFailure() ||
    ServerFailure() ||
    MaintenanceFailure() ||
    RateLimitFailure() ||
    UnauthorizedFailure() => _mensajeGenerico,
    _ => e.message,
  };

  void _emitir(EstadoCompra estado, [String? mensaje]) {
    if (!_resultados.isClosed) {
      _resultados.add((estado: estado, mensaje: mensaje));
    }
  }
}
