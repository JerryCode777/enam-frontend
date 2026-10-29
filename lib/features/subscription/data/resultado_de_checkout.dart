import 'package:dio/dio.dart' show DioException;
import 'package:flutter/services.dart' show PlatformException;
import 'package:in_app_purchase/in_app_purchase.dart' show IAPError;

import '../../../core/analitica/analitica.dart';
import '../../../core/error/failure.dart';
import 'fallo_de_tienda.dart';

/// Cómo terminó una compra en la tienda (`checkout_resultado`).
///
/// Existe porque después de `checkout_started` no se veía nada: en 30 días,
/// 10 compras empezadas en la app y ni un desenlace. No se sabía si la gente
/// cancelaba, si fallaba la tienda o si pagaba y no se activaba.
enum ResultadoDeCheckout {
  /// Nuestro servidor la registró y la app la cerró con la tienda.
  completado,
  cancelado,

  /// Pago diferido: Play PENDING, «Pedir permiso» en iPhone o un 202.
  pendiente,
  error,
}

/// En qué parte falló: en la tienda (no pudo pagar) o en nuestro servidor
/// (pagó y no se activó todavía). La diferencia lo es todo.
enum EtapaDelFallo { tienda, servidor }

/// De dónde salió el desenlace.
enum OrigenDelCheckout {
  /// La persona tocó «Suscribirme».
  compra,

  /// Una compra que quedó a medias y se vuelve a mandar al abrir la app (o al
  /// restaurar). Así se ve si llega al servidor aunque la app se cerrara.
  reintento,
}

/// Registra `checkout_resultado`. **Nunca** un mensaje: los de las tiendas
/// son prosa traducida sin garantía de no llevar datos de nadie, y el código
/// con la etapa dicen lo mismo.
void registrarResultadoDeCheckout(
  Analitica analitica, {
  required String medio,
  required String? planId,
  required ResultadoDeCheckout resultado,
  required OrigenDelCheckout origen,
  EtapaDelFallo? etapa,
  String? codigo,
}) {
  final esError = resultado == ResultadoDeCheckout.error;
  analitica.registrar(
    Evento.checkoutResultado,
    propiedades: {
      'medio': medio,
      'plan_id': ?planId,
      'resultado': resultado.name,
      // `intento` y no `origen`: en el contrato `origen` es cliente/servidor.
      'intento': origen.name,
      if (esError) 'etapa': (etapa ?? EtapaDelFallo.tienda).name,
      if (esError) 'codigo': ?codigo,
    },
  );
}

/// El código de una compra que la tienda rechazó, en minúsculas.
///
/// Play no lo pone en `code` (siempre `purchase_error`) sino en el mensaje,
/// como `BillingResponse.itemAlreadyOwned`: de ahí sale `item_already_owned`.
/// StoreKit 2 lanza un `PlatformException` con el suyo
/// (`storekit2_purchase_failed`…).
String codigoDeCompraFallida(Object? error) {
  if (error is IAPError &&
      error.code == 'purchase_error' &&
      error.message.startsWith('BillingResponse.')) {
    return codigoDeTienda(
      IAPError(source: error.source, code: error.message, message: ''),
    );
  }
  if (error is PlatformException) {
    return codigoDeTienda(IAPError(source: '', code: error.code, message: ''));
  }
  return codigoDeTienda(error ?? '');
}

/// El código de un fallo de nuestro servidor al registrar la compra: el del
/// backend si viene (`compra_de_otra_cuenta`), si no, la clase (`red`,
/// `http_503`…).
String codigoDeServidor(Object error) {
  final c = error is Failure ? error.code : null;
  if (c != null && c.isNotEmpty) {
    final limpio = c
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9_]'), '_')
        .replaceAll(RegExp('_+'), '_');
    if (RegExp(r'^[a-z0-9_]{1,64}$').hasMatch(limpio)) return limpio;
  }
  // Lo que el cliente no clasifica (un 409: la compra es de otra cuenta) llega
  // como `UnknownFailure` con la respuesta dentro.
  if (error case UnknownFailure(details: DioException(:final response?))) {
    return 'http_${response.statusCode}';
  }
  return switch (error) {
    NetworkFailure() => 'red',
    TimeoutFailure() => 'timeout',
    UnauthorizedFailure() => 'http_401',
    ForbiddenFailure() => 'http_403',
    NotFoundFailure() => 'http_404',
    ValidationFailure() => 'http_422',
    RateLimitFailure() => 'http_429',
    MaintenanceFailure() => 'http_503',
    ServerFailure() => 'http_5xx',
    _ => 'desconocido',
  };
}
