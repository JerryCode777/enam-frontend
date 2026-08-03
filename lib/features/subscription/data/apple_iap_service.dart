import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/error/failure.dart';

/// Los identificadores de los productos, tal como están en App Store Connect.
///
/// El orden es el de la pantalla: de más corto a más largo, que es como se lee
/// una escalera de precios.
const productosApple = <String>[
  'pe.jakstech.enamApp.mensual',
  'pe.jakstech.enamApp.trimestral',
  'pe.jakstech.enamApp.semestral',
];

/// Compras dentro de la app, en iOS.
///
/// Habla con StoreKit y **nada más**: no decide si alguien tiene acceso, no
/// guarda nada y no llama a nuestro servidor. Quien canjea la compra por una
/// suscripción es el repositorio, igual que con Google y Apple en el login.
///
/// ---
///
/// La regla que sostiene todo esto: **una compra no se da por terminada hasta
/// que el servidor la registra**. StoreKit guarda las transacciones sin
/// completar y las vuelve a entregar en cada arranque, así que si el servidor no
/// responde —sin red, app cerrada, batería agotada justo después de pagar— la
/// compra reaparece sola en el siguiente intento. Completarla antes de tiempo es
/// lo único que puede hacer que alguien pague y se quede sin acceso.
abstract interface class AppleIapService {
  /// Si esta plataforma puede cobrar por la App Store.
  Future<bool> disponible();

  /// Los productos con el precio ya formateado por Apple en la moneda del país.
  ///
  /// El precio viene de StoreKit y no de nuestro backend porque Apple lo exige
  /// —y porque así un usuario en México ve pesos sin que nadie convierta nada—.
  Future<List<ProductDetails>> productos();

  /// Lanza la compra. El resultado llega por [compras], no aquí.
  Future<void> comprar(ProductDetails producto);

  /// Vuelve a entregar lo que el usuario ya compró.
  ///
  /// App Store lo exige: quien reinstala la app o cambia de iPhone tiene que
  /// poder recuperar su suscripción sin volver a pagar.
  Future<void> restaurar();

  /// Las compras, según van ocurriendo.
  ///
  /// Incluye las que quedaron sin completar de sesiones anteriores: StoreKit las
  /// reentrega al suscribirse a este flujo.
  Stream<List<PurchaseDetails>> get compras;

  /// Le dice a Apple que la compra ya se entregó.
  ///
  /// **Solo después de que el servidor la haya registrado.** Antes de eso, dejar
  /// la transacción sin completar es lo que garantiza que no se pierda.
  Future<void> completar(PurchaseDetails compra);
}

class AppleIapServiceImpl implements AppleIapService {
  AppleIapServiceImpl({InAppPurchase? tienda})
    : _tienda = tienda ?? InAppPurchase.instance;

  final InAppPurchase _tienda;

  @override
  Future<bool> disponible() async {
    if (kIsWeb || !Platform.isIOS) return false;
    return _tienda.isAvailable();
  }

  @override
  Future<List<ProductDetails>> productos() async {
    final respuesta = await _tienda.queryProductDetails(productosApple.toSet());

    if (respuesta.error != null) {
      throw UnknownFailure(
        'No pudimos cargar los planes. ${respuesta.error!.message}',
      );
    }

    // Los que Apple no reconoce se descartan sin ruido: pasa mientras un
    // producto nuevo todavía no está aprobado, y esconder uno es mucho mejor
    // que dejar la pantalla vacía por él.
    final porId = {for (final p in respuesta.productDetails) p.id: p};
    return [for (final id in productosApple) ?porId[id]];
  }

  @override
  Future<void> comprar(ProductDetails producto) async {
    // `buyNonConsumable` y no `buyConsumable`: una suscripción no se gasta al
    // usarla, y con el consumible Apple no la restauraría nunca.
    await _tienda.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: producto),
    );
  }

  @override
  Future<void> restaurar() => _tienda.restorePurchases();

  @override
  Stream<List<PurchaseDetails>> get compras => _tienda.purchaseStream;

  @override
  Future<void> completar(PurchaseDetails compra) async {
    if (compra.pendingCompletePurchase) {
      await _tienda.completePurchase(compra);
    }
  }
}
