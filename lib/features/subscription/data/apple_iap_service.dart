import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:in_app_purchase/in_app_purchase.dart';

import 'fallo_de_tienda.dart';

/// Los identificadores de los productos, tal como están en App Store Connect.
///
/// El orden es el de la pantalla: de más corto a más largo, que es como se lee
/// una escalera de precios.
const productosApple = <String>[
  'pe.jakstech.enamApp.mensual',
  'pe.jakstech.enamApp.trimestral',
  'pe.jakstech.enamApp.semestral',
];

/// El `plan_id` del servidor para cada producto de App Store. Explícito, como
/// en el backend (`apple_service.go`): el trimestral se llama `intensivo` por
/// historia. `null` si el producto no se conoce.
String? planIdDeApple(String productId) => switch (productId) {
  'pe.jakstech.enamApp.mensual' => 'mensual',
  'pe.jakstech.enamApp.trimestral' => 'intensivo',
  'pe.jakstech.enamApp.semestral' => 'semestral',
  _ => null,
};

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

  /// Por qué no hubo planes: lo que devolvió la última consulta y el país de
  /// la cuenta de App Store. Nunca lanza.
  Future<DiagnosticoDeTienda> diagnostico();
}

/// El código con el que StoreKit 2 dice «no hay productos».
///
/// Pese al nombre, **no es un fallo de conexión**: el plugin lo lanza cuando
/// Apple responde bien pero con la lista vacía (`SK2Product.products`). Los
/// fallos de verdad llegan como `storekit2_products_error`. Las 6 personas de
/// iOS sin planes del 27 y 28/10 recibieron este: App Store no les dio
/// ninguno de los tres productos. Esperar más o reintentar no lo cambia; es
/// configuración (App Store Connect) o disponibilidad del país.
const sinProductosDeStoreKit = 'storekit_no_response';

class AppleIapServiceImpl implements AppleIapService {
  AppleIapServiceImpl({InAppPurchase? tienda})
    : _tienda = tienda ?? InAppPurchase.instance;

  final InAppPurchase _tienda;

  /// Lo que devolvió App Store en la última consulta, para [diagnostico].
  ({int productos, int noEncontrados})? _ultima;

  @override
  Future<bool> disponible() async {
    if (kIsWeb || !Platform.isIOS) return false;
    return _tienda.isAvailable();
  }

  @override
  Future<List<ProductDetails>> productos() async {
    final ProductDetailsResponse respuesta;
    try {
      respuesta = await _tienda.queryProductDetails(productosApple.toSet());
    } catch (e) {
      throw FalloDeTienda('$e', codigo: codigoDeTienda(e));
    }

    _ultima = (
      productos: respuesta.productDetails.length,
      noEncontrados: respuesta.notFoundIDs.length,
    );

    // App Store respondió, sin productos: es «vacío», no un error.
    if (respuesta.error?.code == sinProductosDeStoreKit) return const [];

    if (respuesta.error case final error?) {
      throw FalloDeTienda(
        'No pudimos cargar los planes. ${error.message}',
        codigo: codigoDeTienda(error),
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

  @override
  Future<DiagnosticoDeTienda> diagnostico() async {
    String? pais;
    try {
      pais = paisDeAppStore(
        await _tienda.countryCode().timeout(const Duration(seconds: 3)),
      );
    } catch (_) {
      pais = null;
    }
    return DiagnosticoDeTienda(
      pais: pais,
      productosTienda: _ultima?.productos,
      noEncontrados: _ultima?.noEncontrados,
    );
  }
}

/// El país de App Store en dos letras minúsculas, como pide el contrato.
///
/// `Storefront.countryCode` de StoreKit 2 da **tres** letras (ISO 3166-1
/// alfa-3, «PER»); StoreKit 1 daba lo mismo. Se traducen los países que se
/// esperan aquí. Uno que no esté en la lista no se manda: mejor sin país que
/// con uno inventado.
String? paisDeAppStore(String codigo) {
  final c = codigo.trim().toUpperCase();
  if (RegExp(r'^[A-Z]{2}$').hasMatch(c)) return c.toLowerCase();
  return _alfa3[c];
}

/// Los 13 países donde está la app (y sus suscripciones, desde el 28/10),
/// más los que es fácil encontrarse.
const _alfa3 = {
  'PER': 'pe',
  'SUR': 'sr',
  'GUY': 'gy',
  'USA': 'us',
  'MEX': 'mx',
  'COL': 'co',
  'CHL': 'cl',
  'ECU': 'ec',
  'BOL': 'bo',
  'ARG': 'ar',
  'VEN': 've',
  'BRA': 'br',
  'ESP': 'es',
  'ITA': 'it',
  'CAN': 'ca',
  'PRY': 'py',
  'URY': 'uy',
  'PAN': 'pa',
  'CRI': 'cr',
  'DOM': 'do',
  'GTM': 'gt',
  'DEU': 'de',
  'FRA': 'fr',
  'GBR': 'gb',
};

/// Tienda de mentira, para recorrer la pantalla de planes sin App Store.
///
/// Devuelve los tres productos con los precios reales escritos a mano. No es
/// duplicar la fuente de verdad: son datos de ejemplo para pintar una pantalla,
/// y en cuanto se apagan los mocks vienen de StoreKit. Lo único que no se puede
/// simular es la compra, que no hace nada: comprar de verdad exige un iPhone y
/// una cuenta de pruebas de Apple.
class MockAppleIapService implements AppleIapService {
  // Nunca emite nada: con mocks no hay compras que entregar. Existe solo para
  // que el controlador tenga a qué suscribirse.
  // ignore: close_sinks
  final _compras = StreamController<List<PurchaseDetails>>.broadcast();

  @override
  Future<bool> disponible() async => true;

  @override
  Future<List<ProductDetails>> productos() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return [
      ProductDetails(
        id: 'pe.jakstech.enamApp.mensual',
        title: 'ENAM Prep · 1 mes',
        description: 'Acceso completo a ENAM Prep durante un mes.',
        price: 'S/ 59.00',
        rawPrice: 59,
        currencyCode: 'PEN',
      ),
      ProductDetails(
        id: 'pe.jakstech.enamApp.trimestral',
        title: 'ENAM Prep · 3 meses',
        description: 'Acceso completo a ENAM Prep durante tres meses.',
        price: 'S/ 129.00',
        rawPrice: 129,
        currencyCode: 'PEN',
      ),
      ProductDetails(
        id: 'pe.jakstech.enamApp.semestral',
        title: 'ENAM Prep · 6 meses',
        description: 'Acceso completo a ENAM Prep durante seis meses.',
        price: 'S/ 229.00',
        rawPrice: 229,
        currencyCode: 'PEN',
      ),
    ];
  }

  @override
  Future<void> comprar(ProductDetails producto) async {}

  @override
  Future<void> restaurar() async {}

  @override
  Stream<List<PurchaseDetails>> get compras => _compras.stream;

  @override
  Future<void> completar(PurchaseDetails compra) async {}

  @override
  Future<DiagnosticoDeTienda> diagnostico() async =>
      const DiagnosticoDeTienda();
}
