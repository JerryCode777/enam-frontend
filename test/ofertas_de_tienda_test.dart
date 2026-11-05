import 'package:enam_app/features/subscription/data/apple_iap_service.dart';
import 'package:enam_app/features/subscription/data/google_play_iap_service.dart';
import 'package:enam_app/features/subscription/data/oferta_de_tienda.dart';
import 'package:enam_app/features/subscription/presentation/widgets/precio_de_plan.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_2_wrappers.dart';

/// La promoción de las tiendas: se enseña solo lo que la tienda le ofrece a esa
/// persona, siempre con lo que se cobra después, y lo que dice la pantalla es
/// lo que se compra.
void main() {
  group('Google Play', () {
    test('elige la oferta cuando Play la devuelve', () {
      final elegidos = elegirUnoPorProducto(_suscripcion(conOferta: true));
      expect(elegidos.single.price, 'S/ 49.00');

      final oferta = ofertaDe(elegidos.single)!;
      expect(oferta.precio, 'S/ 49.00');
      expect(oferta.precioNormal, 'S/ 59.00');
      expect(oferta.leyenda, 'Primer mes a S/ 49.00. Luego S/ 59.00 al mes.');
    });

    test('sin oferta (no es elegible), el plan base', () {
      final elegidos = elegirUnoPorProducto(_suscripcion(conOferta: false));
      expect(elegidos.single.price, 'S/ 59.00');
      expect(ofertaDe(elegidos.single), isNull);
    });

    test('da igual el orden en que Play las devuelva', () {
      final elegidos = elegirUnoPorProducto(
        _suscripcion(conOferta: true).reversed.toList(),
      );
      expect(elegidos.single.price, 'S/ 49.00');
    });

    test('una oferta que no se puede explicar en una línea no se elige', () {
      for (final fases in [
        // Prueba gratis.
        [_fase(0, 'Gratis', 'P7D', ciclos: 1), _fase(59, 'S/ 59.00', 'P1M')],
        // Tres meses a precio reducido.
        [_fase(49, 'S/ 49.00', 'P1M', ciclos: 3), _fase(59, 'S/ 59.00', 'P1M')],
        // Sin descuento.
        [_fase(59, 'S/ 59.00', 'P1M', ciclos: 1), _fase(59, 'S/ 59.00', 'P1M')],
      ]) {
        final elegidos = elegirUnoPorProducto(
          _suscripcion(conOferta: true, faseDeOferta: fases),
        );
        expect(elegidos.single.price, 'S/ 59.00');
        expect(ofertaDe(elegidos.single), isNull);
      }
    });

    test('comprar manda el offerToken de la oferta elegida', () async {
      final tienda = _TiendaFalsa();
      final servicio = GooglePlayIapServiceImpl(tienda: tienda);

      await servicio.comprar(
        elegirUnoPorProducto(_suscripcion(conOferta: true)).single,
        cuentaId: 'u1',
      );
      var param = tienda.param! as GooglePlayPurchaseParam;
      expect(param.offerToken, 'token-oferta');
      expect(param.applicationUserName, 'u1');

      await servicio.comprar(
        elegirUnoPorProducto(_suscripcion(conOferta: false)).single,
        cuentaId: 'u1',
      );
      param = tienda.param! as GooglePlayPurchaseParam;
      expect(param.offerToken, 'token-base');
    });
  });

  group('App Store', () {
    SK2Product producto({SK2SubscriptionOffer? oferta, String id = _idAnual}) =>
        SK2Product(
          id: id,
          displayName: 'ENAM Prep · 1 año',
          displayPrice: 'S/ 399.00',
          description: 'Acceso completo.',
          price: 399,
          type: SK2ProductType.autoRenewable,
          priceLocale: SK2PriceLocale(currencyCode: 'PEN', currencySymbol: 'S/'),
          subscription: SK2SubscriptionInfo(
            subscriptionGroupID: 'g',
            promotionalOffers: [?oferta],
            subscriptionPeriod: const SK2SubscriptionPeriod(
              value: 1,
              unit: SK2SubscriptionPeriodUnit.year,
            ),
          ),
        );

    SK2SubscriptionOffer introductoria({
      double precio = 179,
      SK2SubscriptionOfferType tipo = SK2SubscriptionOfferType.introductory,
      SK2SubscriptionOfferPaymentMode modo =
          SK2SubscriptionOfferPaymentMode.payUpFront,
    }) => SK2SubscriptionOffer(
      price: precio,
      type: tipo,
      period: const SK2SubscriptionPeriod(
        value: 1,
        unit: SK2SubscriptionPeriodUnit.year,
      ),
      periodCount: 1,
      paymentMode: modo,
    );

    Future<List<ProductDetails>> productos(
      SK2Product p, {
      required Future<bool> Function(String) esElegible,
    }) => AppleIapServiceImpl(
      tienda: _TiendaFalsa([AppStoreProduct2Details.fromSK2Product(p)]),
      esElegible: esElegible,
    ).productos();

    test('elegible: la oferta, con el precio con el formato de Apple', () async {
      final [p] = await productos(
        producto(oferta: introductoria()),
        esElegible: (_) async => true,
      );
      final oferta = ofertaDe(p)!;
      expect(oferta.precio, 'S/ 179.00');
      expect(oferta.precioNormal, 'S/ 399.00');
      expect(
        oferta.leyenda,
        'Primer año a S/ 179.00 (S/ 14.92 al mes). Luego S/ 399.00 al año.',
      );
    });

    test('no elegible: solo el normal', () async {
      final [p] = await productos(
        producto(oferta: introductoria()),
        esElegible: (_) async => false,
      );
      expect(ofertaDe(p), isNull);
      expect(p.price, 'S/ 399.00');
    });

    test('si StoreKit no responde a la elegibilidad: solo el normal', () async {
      final [p] = await productos(
        producto(oferta: introductoria()),
        esElegible: (_) async =>
            throw PlatformException(code: 'storekit2_eligibility_check_failed'),
      );
      expect(ofertaDe(p), isNull);
    });

    test('sin oferta creada no se pregunta la elegibilidad', () async {
      var preguntas = 0;
      final [p] = await productos(
        producto(),
        esElegible: (_) async {
          preguntas++;
          return true;
        },
      );
      expect(ofertaDe(p), isNull);
      expect(preguntas, 0);
    });

    test('solo la introductoria de pago por adelantado con descuento', () {
      for (final o in [
        introductoria(tipo: SK2SubscriptionOfferType.promotional),
        introductoria(modo: SK2SubscriptionOfferPaymentMode.freeTrial),
        introductoria(modo: SK2SubscriptionOfferPaymentMode.payAsYouGo),
        introductoria(precio: 399),
      ]) {
        expect(ofertaIntroductoria(producto(oferta: o)), isNull);
      }
    });

    test('se le compra a la tienda el producto original', () async {
      final tienda = _TiendaFalsa();
      final original = AppStoreProduct2Details.fromSK2Product(
        producto(oferta: introductoria()),
      );
      await AppleIapServiceImpl(tienda: tienda).comprar(
        ProductoConOferta(original, ofertaIntroductoria(original.sk2Product)!),
      );
      expect(tienda.param!.productDetails, same(original));
    });

    test('un anual que la tienda no devuelve no rompe nada', () async {
      final mensual = AppStoreProduct2Details.fromSK2Product(
        producto(id: 'pe.jakstech.enamApp.mensual'),
      );
      final lista = await AppleIapServiceImpl(
        tienda: _TiendaFalsa([mensual]),
        esElegible: (_) async => false,
      ).productos();
      expect(lista.map((p) => p.id), ['pe.jakstech.enamApp.mensual']);
    });

    test('el anual y su plan', () {
      expect(productosApple.last, _idAnual);
      expect(planIdDeApple(_idAnual), 'anual');
    });
  });

  group('los textos', () {
    test('cada periodo dice lo suyo', () {
      String leyenda(int? meses) => OfertaDeTienda(
        precio: 'A',
        precioNormal: 'B',
        mesesDeOferta: meses,
        mesesDeRenovacion: meses,
      ).leyenda;

      expect(leyenda(1), 'Primer mes a A. Luego B al mes.');
      expect(leyenda(3), 'Primeros 3 meses a A. Luego B cada 3 meses.');
      expect(leyenda(6), 'Primeros 6 meses a A. Luego B cada 6 meses.');
      expect(leyenda(12), 'Primer año a A. Luego B al año.');
      expect(leyenda(null), 'Primer periodo a A. Luego B en cada renovación.');
    });

    test('los periodos de Play', () {
      expect(mesesDePeriodo('P1M'), 1);
      expect(mesesDePeriodo('P6M'), 6);
      expect(mesesDePeriodo('P1Y'), 12);
      expect(mesesDePeriodo('P12M'), 12);
      expect(mesesDePeriodo('P4W'), isNull);
    });

    test('el precio de la oferta, como la tienda escribe el normal', () {
      expect(precioConElFormatoDe('S/ 59.00', 49), 'S/ 49.00');
      expect(precioConElFormatoDe('S/59.00', 49.5), 'S/49.50');
      expect(precioConElFormatoDe('59,00 S/', 49), '49,00 S/');
      expect(precioConElFormatoDe('PEN 59', 49), 'PEN 49');
    });

    testWidgets('el precio normal va tachado', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrecioDePlan(
              precio: 'S/ 59.00',
              oferta: ofertaDeEjemplo('premium_mensual'),
              tamano: 15,
            ),
          ),
        ),
      );
      expect(find.text('S/ 49.00'), findsOneWidget);
      final normal = tester.widget<Text>(find.text('S/ 59.00'));
      expect(normal.style?.decoration, TextDecoration.lineThrough);
    });
  });
}

const _idAnual = 'pe.jakstech.enamApp.anual';

PricingPhaseWrapper _fase(
  int soles,
  String texto,
  String periodo, {
  int ciclos = 0,
}) => PricingPhaseWrapper(
  billingCycleCount: ciclos,
  billingPeriod: periodo,
  formattedPrice: texto,
  priceAmountMicros: soles * 1000000,
  priceCurrencyCode: 'PEN',
  recurrenceMode: ciclos == 0
      ? RecurrenceMode.infiniteRecurring
      : RecurrenceMode.nonRecurring,
);

List<ProductDetails> _suscripcion({
  required bool conOferta,
  List<PricingPhaseWrapper>? faseDeOferta,
}) {
  final base = SubscriptionOfferDetailsWrapper(
    basePlanId: 'cada-1m',
    offerTags: const [],
    offerIdToken: 'token-base',
    pricingPhases: [_fase(59, 'S/ 59.00', 'P1M')],
  );
  final oferta = SubscriptionOfferDetailsWrapper(
    basePlanId: 'cada-1m',
    offerId: 'promo-nov-2026',
    offerTags: const [],
    offerIdToken: 'token-oferta',
    pricingPhases:
        faseDeOferta ??
        [_fase(49, 'S/ 49.00', 'P1M', ciclos: 1), _fase(59, 'S/ 59.00', 'P1M')],
  );
  return GooglePlayProductDetails.fromProductDetails(
    ProductDetailsWrapper(
      description: 'Acceso completo.',
      name: 'Premium mensual',
      productId: 'premium_mensual',
      productType: ProductType.subs,
      title: 'Premium mensual (ENAM Prep)',
      subscriptionOfferDetails: [base, if (conOferta) oferta],
    ),
  );
}

class _TiendaFalsa implements InAppPurchase {
  _TiendaFalsa([this._productos = const []]);

  final List<ProductDetails> _productos;
  PurchaseParam? param;

  @override
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> identifiers,
  ) async => ProductDetailsResponse(
    productDetails: _productos,
    notFoundIDs: [
      for (final id in identifiers)
        if (!_productos.any((p) => p.id == id)) id,
    ],
  );

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    param = purchaseParam;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
