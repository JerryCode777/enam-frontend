import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/error/failure.dart';
import 'compras_apple_controller.dart' show EstadoCompra, ResultadoCompra;
import 'google_play_iap_service.dart';
import 'subscription_repository.dart';

/// Orquesta una compra de Google Play de punta a punta.
///
/// La misma regla que en iOS (`ComprasAppleController`): **una compra no se da
/// por terminada hasta que el servidor la registra.**
///
///  1. Play cobra y entrega la compra con su `purchaseToken`.
///  2. Se manda al servidor, que la lee en Google, da el acceso y hace el
///     acknowledge.
///  3. **Solo con 200** se completa aquí.
///
/// Si el paso 2 falla por la red o el servidor, no se completa: la compra se
/// vuelve a mandar en la próxima apertura con [restaurarEnSilencio], que el
/// servidor recibe sin duplicar nada (es idempotente por `purchaseToken`).
///
/// Lo que responde el servidor (`enam-backend`, `GOOGLE-PLAY.md` §7 y §9):
///
/// | Respuesta | Aquí |
/// |---|---|
/// | 200 | Completar y avisar «listo» |
/// | 202 | «Pago pendiente», sin completar |
/// | 409 / 422 | El mensaje del servidor, y completar: no hay nada más que hacer |
/// | 5xx, 503, sin red | Mensaje tranquilizador, sin completar |
class ComprasGooglePlayController {
  ComprasGooglePlayController({
    required GooglePlayIapService tienda,
    required SubscriptionRepository suscripciones,
  }) : _tienda = tienda,
       _suscripciones = suscripciones;

  final GooglePlayIapService _tienda;
  final SubscriptionRepository _suscripciones;

  StreamSubscription<List<PurchaseDetails>>? _escucha;

  final _resultados = StreamController<ResultadoCompra>.broadcast();

  /// Los tokens que ya se están mandando al servidor. Play puede entregar la
  /// misma compra dos veces seguidas (la compra y la restauración del
  /// arranque): sin esto saldrían dos `verify` a la vez.
  final _enCurso = <String>{};

  /// Lo que le va pasando a la compra en curso.
  Stream<ResultadoCompra> get resultados => _resultados.stream;

  /// Empieza a atender las compras. Se puede llamar varias veces.
  void escuchar() {
    _escucha ??= _tienda.compras.listen(_atender);
  }

  Future<void> soltar() async {
    await _escucha?.cancel();
    _escucha = null;
    await _resultados.close();
  }

  Future<List<ProductDetails>> productos() => _tienda.productos();

  Future<DiagnosticoDePlay> diagnostico() => _tienda.diagnostico();

  Future<void> comprar(
    ProductDetails producto, {
    required String cuentaId,
  }) async {
    _emitir(EstadoCompra.comprando);
    try {
      await _tienda.comprar(producto, cuentaId: cuentaId);
    } catch (e) {
      _emitir(EstadoCompra.error, 'No pudimos abrir la compra. $e');
    }
  }

  /// Lo que pide la persona con «Restaurar compras»: se le cuenta qué pasa.
  Future<void> restaurar() async {
    escuchar();
    _emitir(EstadoCompra.comprando);
    try {
      await _tienda.restaurar();
      // Si no tenía nada que restaurar, Play no entrega nada y el botón se
      // quedaría girando.
      _emitir(EstadoCompra.quieto);
    } catch (e) {
      _emitir(EstadoCompra.error, 'No pudimos restaurar tus compras. $e');
    }
  }

  /// Al abrir la app con sesión: vuelve a mandar al servidor lo que quedó sin
  /// registrar (pagó y se cerró la app, sin red, otro teléfono). Sin avisos:
  /// si falla, se intenta en la próxima apertura.
  Future<void> restaurarEnSilencio() async {
    escuchar();
    try {
      if (!await _tienda.disponible()) return;
      await _tienda.restaurar();
    } catch (_) {}
  }

  Future<void> _atender(List<PurchaseDetails> compras) async {
    for (final compra in compras) {
      switch (compra.status) {
        case PurchaseStatus.pending:
          // También al servidor: responde 202 y guarda la compra a nombre de
          // la cuenta, para aplicarla cuando Play avise.
          await _registrar(compra);

        case PurchaseStatus.canceled:
          // Cerrar la hoja de Play no es un error.
          _emitir(EstadoCompra.quieto);

        case PurchaseStatus.error:
          _emitir(
            EstadoCompra.error,
            compra.error?.message ?? 'La compra no se pudo completar.',
          );

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _registrar(compra);
      }
    }
  }

  Future<void> _registrar(PurchaseDetails compra) async {
    final token = compra.verificationData.serverVerificationData;
    if (token.isEmpty || !_enCurso.add(token)) return;
    _emitir(EstadoCompra.registrando);

    try {
      final canje = await _suscripciones.canjearCompraGooglePlay(
        productId: compra.productID,
        purchaseToken: token,
      );
      switch (canje) {
        case CanjeActivado():
          // Solo aquí: el servidor ya dio el acceso.
          await _tienda.completar(compra);
          _emitir(EstadoCompra.listo);
        case CanjePendiente(:final mensaje):
          _emitir(EstadoCompra.pendiente, mensaje);
      }
    } on Failure catch (e) {
      if (_esPasajero(e)) {
        // El dinero ya salió (o está por salir). No se completa: se vuelve a
        // mandar en la próxima apertura.
        _emitir(EstadoCompra.error, _mensajeGenerico);
      } else {
        // 409 (la compra es de otra cuenta) o 422 (Google no la conoce, otro
        // producto, vencida): reintentar no cambia nada. Se completa para que
        // no reaparezca en cada arranque con el mismo error.
        _emitir(EstadoCompra.error, e.message);
        await _tienda.completar(compra);
      }
    } catch (_) {
      _emitir(EstadoCompra.error, _mensajeGenerico);
    } finally {
      _enCurso.remove(token);
    }
  }

  static const _mensajeGenerico =
      'Tu pago se hizo, pero no pudimos activarlo todavía. No pagues de nuevo: '
      'vuelve a abrir la app con conexión y se activará solo.';

  /// Como en iOS, se enumera lo PASAJERO: lo que no se reconoce se cuenta con
  /// las palabras del servidor, que al menos son ciertas.
  ///
  /// El 503 (`GOOGLE_PLAY_ACTIVO` apagado) es pasajero: la compra se registra
  /// sola cuando el servidor se encienda.
  bool _esPasajero(Failure e) => switch (e) {
    NetworkFailure() ||
    TimeoutFailure() ||
    ServerFailure() ||
    MaintenanceFailure() ||
    RateLimitFailure() ||
    UnauthorizedFailure() => true,
    _ => false,
  };

  void _emitir(EstadoCompra estado, [String? mensaje]) {
    if (!_resultados.isClosed) {
      _resultados.add((estado: estado, mensaje: mensaje));
    }
  }
}
