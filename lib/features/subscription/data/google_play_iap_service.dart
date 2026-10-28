import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'fallo_de_tienda.dart';

export 'fallo_de_tienda.dart' show DiagnosticoDeTienda, FalloDeTienda;

/// El nombre de la app en Google Play. El servidor lo exige en cada compra.
const paqueteGooglePlay = 'pe.jakstech.enam_app';

/// Los `productId` de Play Console, los del servidor (`enam-backend`,
/// `GOOGLE-PLAY.md` §2).
///
/// Las tres son suscripciones, en el orden de la pantalla.
const productosGooglePlay = <String>[
  'premium_mensual',
  'premium_trimestral',
  'premium_semestral',
];

/// El `plan_id` del servidor para cada producto de Google Play. Explícito, como
/// en `GOOGLE_PLAY_PRODUCTOS`: el trimestral se llama `intensivo` por historia.
/// `null` si el producto no se conoce.
String? planIdDeGooglePlay(String productId) => switch (productId) {
  'premium_mensual' => 'mensual',
  'premium_trimestral' => 'intensivo',
  'premium_semestral' => 'semestral',
  _ => null,
};

/// Compras dentro de la app, en Android, con Google Play Billing.
///
/// Como [AppleIapService]: habla con Play y **nada más**. Quien canjea la
/// compra por una suscripción es el repositorio, y quien decide cuándo darla
/// por terminada es el controlador: **solo después de que el servidor la
/// registre**.
abstract interface class GooglePlayIapService {
  /// Si este dispositivo puede cobrar por Google Play.
  Future<bool> disponible();

  /// Los productos con el precio ya formateado por Play en la moneda del país,
  /// uno por `productId` y en el orden de [productosGooglePlay].
  ///
  /// Lanza [FalloDeTienda] si Play no responde.
  Future<List<ProductDetails>> productos();

  /// Lanza la compra a nombre de [cuentaId], el id de la cuenta de ENAM Prep.
  /// El resultado llega por [compras], no aquí.
  Future<void> comprar(ProductDetails producto, {required String cuentaId});

  /// Vuelve a entregar por [compras] lo que la cuenta de Google ya compró.
  Future<void> restaurar();

  /// Las compras, según van ocurriendo, y las restauradas.
  Stream<List<PurchaseDetails>> get compras;

  /// Le dice a Play que la compra ya se entregó. **Solo después de que el
  /// servidor la haya registrado** (el servidor ya hace el acknowledge; esto
  /// es la otra mitad del contrato de `in_app_purchase`).
  Future<void> completar(PurchaseDetails compra);

  /// Por qué Play pudo no dar planes: lo que devolvió la última consulta, el
  /// país de la cuenta de Play y quién instaló la app. Nunca lanza: lo que no
  /// se pueda saber queda en `null`.
  Future<DiagnosticoDePlay> diagnostico();
}

/// El diagnóstico de Play es el de cualquier tienda (ver [DiagnosticoDeTienda]).
typedef DiagnosticoDePlay = DiagnosticoDeTienda;

/// Quién instaló la app, en las tres clases del contrato: `play`, `otro`
/// (otra tienda) y `ninguno` (un APK suelto o adb).
///
/// `com.android.vending` es Play Store (y `com.google.android.feedback`, el
/// nombre que daban versiones viejas).
///
/// Desde Android 11, `installerStore` es quien **inició** la instalación, y
/// un APK suelto o adb ya no dan `null`: dan el instalador del sistema o la
/// shell. Eso es `ninguno`, no otra tienda. Pasó en la 1.1.7: el robot de
/// prelanzamiento de Play, que instala por adb, llegaba como `otro`.
String instaladorDe(String? paquete) => switch (paquete) {
  null || '' => 'ninguno',
  'com.android.vending' || 'com.google.android.feedback' => 'play',
  _ when _sinTienda.contains(paquete) => 'ninguno',
  _ => 'otro',
};

/// Los que instalan sin tienda: adb y los instaladores de paquetes del
/// sistema (el de AOSP, el de Google y los de los fabricantes más comunes
/// en Perú).
const _sinTienda = {
  'com.android.shell',
  'com.android.packageinstaller',
  'com.google.android.packageinstaller',
  'com.samsung.android.packageinstaller',
  'com.miui.packageinstaller',
  'com.huawei.appmarket.packageinstaller',
  'com.oplus.packageinstaller',
  'com.coloros.packageinstaller',
};

class GooglePlayIapServiceImpl implements GooglePlayIapService {
  GooglePlayIapServiceImpl({InAppPurchase? tienda}) : _inyectada = tienda;

  final InAppPurchase? _inyectada;

  /// Lo que devolvió Play en la última consulta, para [diagnostico].
  ({int productos, int noEncontrados})? _ultima;

  /// Perezosa: este servicio se crea al arrancar la app (para restaurar
  /// compras), también donde no hay Play, y `InAppPurchase.instance` falla
  /// si la plataforma no tiene implementación.
  InAppPurchase get _tienda => _inyectada ?? InAppPurchase.instance;

  @override
  Future<bool> disponible() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    return _tienda.isAvailable();
  }

  @override
  Future<List<ProductDetails>> productos() async {
    // Sin esto, una facturación caída se confunde con «no hay productos»: el
    // plugin traduce un BILLING_UNAVAILABLE a una lista vacía sin error.
    if (!await _tienda.isAvailable()) {
      throw const FalloDeTienda(
        'Google Play Billing no está disponible.',
        codigo: 'billing_unavailable',
      );
    }
    final ProductDetailsResponse respuesta;
    try {
      respuesta = await _tienda.queryProductDetails(
        productosGooglePlay.toSet(),
      );
    } catch (e) {
      throw FalloDeTienda('$e', codigo: codigoDeTienda(e));
    }
    _ultima = (
      productos: respuesta.productDetails.length,
      noEncontrados: respuesta.notFoundIDs.length,
    );
    if (respuesta.error case final error?) {
      throw FalloDeTienda(error.message, codigo: codigoDeTienda(error));
    }
    return elegirUnoPorProducto(respuesta.productDetails);
  }

  @override
  Future<void> comprar(
    ProductDetails producto, {
    required String cuentaId,
  }) async {
    // `buyNonConsumable` es el de las suscripciones: `buyConsumable` es para
    // lo que se gasta.
    //
    // `applicationUserName` llega a Play como `obfuscatedAccountId`. El
    // servidor lo compara con quien verifica: si no coincide, 409. Es el UUID
    // de la cuenta, nunca el correo.
    await _tienda.buyNonConsumable(
      purchaseParam: GooglePlayPurchaseParam(
        productDetails: producto,
        applicationUserName: cuentaId,
      ),
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
  Future<DiagnosticoDePlay> diagnostico() async {
    return DiagnosticoDePlay(
      pais: await _pais(),
      productosTienda: _ultima?.productos,
      noEncontrados: _ultima?.noEncontrados,
      instalador: await _instalador(),
    );
  }

  /// El país de la cuenta de Play, o `null` si Play no lo dice a tiempo (con
  /// la facturación caída, por ejemplo).
  Future<String?> _pais() async {
    try {
      final codigo = await _tienda.countryCode().timeout(
        const Duration(seconds: 3),
      );
      final pais = codigo.trim().toLowerCase();
      return RegExp(r'^[a-z]{2}$').hasMatch(pais) ? pais : null;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _instalador() async {
    try {
      return instaladorDe((await PackageInfo.fromPlatform()).installerStore);
    } catch (_) {
      return null;
    }
  }
}

/// Uno por `productId`, en el orden de [productosGooglePlay].
///
/// Play devuelve una entrada por cada oferta de una suscripción: el plan base
/// y, si algún día se crean, las promociones. Se queda el plan base (la oferta
/// sin `offerId`): es el precio de siempre, el que dice la pantalla. Los que
/// Play no devuelve se descartan sin ruido, como en iOS.
@visibleForTesting
List<ProductDetails> elegirUnoPorProducto(List<ProductDetails> todos) {
  final porId = <String, ProductDetails>{};
  for (final p in todos) {
    final anterior = porId[p.id];
    if (anterior == null || (!_esPlanBase(anterior) && _esPlanBase(p))) {
      porId[p.id] = p;
    }
  }
  return [for (final id in productosGooglePlay) ?porId[id]];
}

bool _esPlanBase(ProductDetails p) {
  if (p is! GooglePlayProductDetails) return true;
  final indice = p.subscriptionIndex;
  final ofertas = p.productDetails.subscriptionOfferDetails;
  if (indice == null || ofertas == null) return true;
  return ofertas[indice].offerId == null;
}

/// Tienda de mentira, para recorrer la pantalla de planes sin Play.
///
/// Devuelve los tres productos con los precios de Play escritos a mano:
/// son datos de ejemplo para pintar la pantalla, y en cuanto se apagan los
/// mocks vienen de Play. La compra no hace nada.
class MockGooglePlayIapService implements GooglePlayIapService {
  // Nunca emite nada: con mocks no hay compras que entregar.
  // ignore: close_sinks
  final _compras = StreamController<List<PurchaseDetails>>.broadcast();

  @override
  Future<bool> disponible() async => true;

  @override
  Future<List<ProductDetails>> productos() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return [
      ProductDetails(
        id: 'premium_mensual',
        title: 'Premium mensual',
        description: 'Acceso completo a ENAM Prep durante un mes.',
        price: 'S/ 69.00',
        rawPrice: 69,
        currencyCode: 'PEN',
      ),
      ProductDetails(
        id: 'premium_trimestral',
        title: 'Premium trimestral',
        description: 'Acceso completo a ENAM Prep durante tres meses.',
        price: 'S/ 149.00',
        rawPrice: 149,
        currencyCode: 'PEN',
      ),
      ProductDetails(
        id: 'premium_semestral',
        title: 'Premium semestral',
        description: 'Acceso completo a ENAM Prep durante seis meses.',
        price: 'S/ 259.00',
        rawPrice: 259,
        currencyCode: 'PEN',
      ),
    ];
  }

  @override
  Future<void> comprar(
    ProductDetails producto, {
    required String cuentaId,
  }) async {}

  @override
  Future<void> restaurar() async {}

  @override
  Stream<List<PurchaseDetails>> get compras => _compras.stream;

  @override
  Future<void> completar(PurchaseDetails compra) async {}

  @override
  Future<DiagnosticoDePlay> diagnostico() async => const DiagnosticoDePlay();
}
