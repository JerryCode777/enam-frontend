import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

/// Un precio de primer periodo que la tienda le ofrece a **esta** persona.
///
/// Nunca sale de un valor nuestro, ni lleva fecha de fin: Play solo devuelve
/// las ofertas para las que la cuenta es elegible y StoreKit responde si lo es.
/// Cuando la tienda deja de ofrecerla, la pantalla vuelve sola al precio normal.
class OfertaDeTienda {
  const OfertaDeTienda({
    required this.precio,
    required this.precioNormal,
    required this.mesesDeOferta,
    required this.mesesDeRenovacion,
    this.equivalenteMensual,
  });

  /// El primer periodo, en el formato de la tienda: `S/ 49.00`.
  final String precio;

  /// Lo que se cobra en cada renovación: `S/ 59.00`.
  final String precioNormal;

  /// Cuánto dura el primer periodo. `null` si la tienda da otra unidad.
  final int? mesesDeOferta;

  /// Cada cuánto se renueva. `null` si la tienda da otra unidad.
  final int? mesesDeRenovacion;

  /// En los planes de un año, lo que sale al mes: `S/ 14.92`. Es solo una
  /// ayuda: el total, que es lo que se cobra, sigue siendo lo principal.
  final String? equivalenteMensual;

  /// Son suscripciones que se renuevan: junto a la oferta tiene que quedar
  /// claro qué se cobra después (guía 3.1.2 de App Store).
  String get leyenda =>
      '${_primerPeriodo(mesesDeOferta)} a $precio'
      '${equivalenteMensual == null ? '' : ' ($equivalenteMensual al mes)'}. '
      'Luego $precioNormal ${_cadaPeriodo(mesesDeRenovacion)}.';
}

String _primerPeriodo(int? meses) => switch (meses) {
  1 => 'Primer mes',
  12 => 'Primer año',
  null => 'Primer periodo',
  _ when meses % 12 == 0 => 'Primeros ${meses ~/ 12} años',
  _ => 'Primeros $meses meses',
};

String _cadaPeriodo(int? meses) => switch (meses) {
  1 => 'al mes',
  12 => 'al año',
  null => 'en cada renovación',
  _ when meses % 12 == 0 => 'cada ${meses ~/ 12} años',
  _ => 'cada $meses meses',
};

/// Un producto de App Store con la oferta para la que la persona es elegible.
///
/// StoreKit no la trae en el producto como Play: la elegibilidad se pregunta
/// aparte. `price` sigue siendo el normal, y a la tienda se le compra
/// [original].
class ProductoConOferta extends ProductDetails {
  ProductoConOferta(this.original, this.oferta)
    : super(
        id: original.id,
        title: original.title,
        description: original.description,
        price: original.price,
        rawPrice: original.rawPrice,
        currencyCode: original.currencyCode,
        currencySymbol: original.currencySymbol,
      );

  final ProductDetails original;
  final OfertaDeTienda oferta;
}

/// La oferta de [producto] para esta persona, o `null` si solo le toca el
/// precio normal.
OfertaDeTienda? ofertaDe(ProductDetails producto) => switch (producto) {
  ProductoConOferta(:final oferta) => oferta,
  GooglePlayProductDetails() => _ofertaDeGooglePlay(producto),
  _ => null,
};

/// Solo una oferta que se entienda igual en la pantalla y en la hoja de Play:
/// **un** pago de primer periodo, con descuento, y luego el precio normal. Lo
/// demás (prueba gratis, varios ciclos con descuento) no está creado, y antes
/// de decir un precio que no es se queda el normal.
OfertaDeTienda? _ofertaDeGooglePlay(GooglePlayProductDetails producto) {
  final indice = producto.subscriptionIndex;
  final ofertas = producto.productDetails.subscriptionOfferDetails;
  if (indice == null || ofertas == null) return null;

  final oferta = ofertas[indice];
  final fases = oferta.pricingPhases;
  if (oferta.offerId == null || fases.length < 2) return null;

  final (primera, ultima) = (fases.first, fases.last);
  if (primera.billingCycleCount != 1 ||
      primera.priceAmountMicros <= 0 ||
      primera.priceAmountMicros >= ultima.priceAmountMicros) {
    return null;
  }
  final meses = mesesDePeriodo(primera.billingPeriod);
  return OfertaDeTienda(
    precio: primera.formattedPrice,
    precioNormal: ultima.formattedPrice,
    equivalenteMensual: equivalenteMensualDe(
      primera.formattedPrice,
      primera.priceAmountMicros / 1000000,
      meses,
    ),
    mesesDeOferta: meses,
    mesesDeRenovacion: mesesDePeriodo(ultima.billingPeriod),
  );
}

/// `P3M` → 3 y `P1Y` → 12. `null` en lo que no son meses o años (`P4W`).
int? mesesDePeriodo(String periodoIso) {
  final m = RegExp(r'^P(?:(\d+)Y)?(?:(\d+)M)?$').firstMatch(periodoIso);
  if (m == null || (m[1] == null && m[2] == null)) return null;
  return int.parse(m[1] ?? '0') * 12 + int.parse(m[2] ?? '0');
}

/// [monto] escrito como [modelo], que es como la tienda escribe los precios de
/// ese país: `S/ 59.00` y 49 dan `S/ 49.00`; `59,00 S/` y 49 dan `49,00 S/`.
///
/// StoreKit da el precio de la oferta solo como número.
String precioConElFormatoDe(String modelo, double monto) {
  final numero = RegExp(r'\d(?:[\d.,\s]*\d)?').firstMatch(modelo);
  if (numero == null) return monto.toStringAsFixed(2);
  final decimales = RegExp(r'[.,](\d{1,2})$').firstMatch(numero[0]!);
  final escrito = decimales == null
      ? monto.toStringAsFixed(monto == monto.roundToDouble() ? 0 : 2)
      : monto
            .toStringAsFixed(decimales[1]!.length)
            .replaceFirst('.', numero[0]![decimales.start]);
  return modelo.replaceRange(numero.start, numero.end, escrito);
}

/// Lo que sale al mes un primer periodo de un año, escrito como [modelo]. `null`
/// si el periodo es otro.
String? equivalenteMensualDe(String modelo, double monto, int? meses) =>
    meses == 12 ? precioConElFormatoDe(modelo, monto / 12) : null;

/// El plan que se destaca como la mejor opción, en las dos tiendas.
bool esMejorOpcion(String productId) =>
    productId == 'pe.jakstech.enamApp.anual' || productId == 'premium_anual';

/// La promoción de noviembre de 2026, para las tiendas de mentira: en cuanto se
/// apagan los mocks, las ofertas vienen de la tienda.
OfertaDeTienda ofertaDeEjemplo(String productId) {
  final (oferta, normal, meses) = switch (productId) {
    final id when id.endsWith('mensual') => ('49', '59', 1),
    final id when id.endsWith('trimestral') => ('79', '129', 3),
    final id when id.endsWith('semestral') => ('129', '229', 6),
    _ => ('179', '399', 12),
  };
  return OfertaDeTienda(
    precio: 'S/ $oferta.00',
    precioNormal: 'S/ $normal.00',
    equivalenteMensual: equivalenteMensualDe(
      'S/ $oferta.00',
      double.parse(oferta),
      meses,
    ),
    mesesDeOferta: meses,
    mesesDeRenovacion: meses,
  );
}
