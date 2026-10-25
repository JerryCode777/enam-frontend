import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../core/analitica/analitica.dart';

/// La tienda no pudo dar los productos: falló la consulta o la conexión con la
/// facturación. [codigo] es el de máquina, en minúsculas (`billing_unavailable`,
/// `network_error`…), para la analítica; nunca el mensaje.
class FalloDeTienda implements Exception {
  const FalloDeTienda(this.mensaje, {required this.codigo});

  final String mensaje;
  final String codigo;

  @override
  String toString() => 'FalloDeTienda($codigo): $mensaje';
}

/// El código de máquina de la tienda, en minúsculas y con guiones bajos.
///
/// Android: el `BillingResponse` (`BillingResponse.serviceUnavailable` queda
/// `service_unavailable`). iOS: el código de StoreKit. Lo que no se reconoce
/// es `desconocido`, nunca el mensaje.
String codigoDeTienda(Object error) {
  final crudo = switch (error) {
    IAPError(:final code) => code,
    _ => '',
  };
  final enSerpiente = crudo
      .split('.')
      .last
      .replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]!.toLowerCase()}')
      .replaceAll(RegExp('[^a-z0-9_]'), '_')
      .replaceAll(RegExp('_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  if (enSerpiente.isEmpty) return 'desconocido';
  return enSerpiente.length > 64 ? enSerpiente.substring(0, 64) : enSerpiente;
}

/// `planes_no_disponibles` (catálogo 33): la pantalla de Planes no puede
/// enseñar ningún plan. Con [error] nulo, la tienda respondió sin productos
/// (`vacio`); si no, falló (`error`, con su código).
///
/// Quien lo llama se encarga de mandarlo **una vez por apertura** de Planes:
/// un reintento que vuelve a fallar no lo repite. Si faltan solo algunos
/// planes, no se llama.
void registrarPlanesNoDisponibles(
  Analitica analitica, {
  required String medio,
  Object? error,
}) {
  analitica.registrar(
    Evento.planesNoDisponibles,
    propiedades: {
      'medio': medio,
      if (error == null)
        'motivo': 'vacio'
      else ...{
        'motivo': 'error',
        'codigo': error is FalloDeTienda ? error.codigo : 'desconocido',
      },
    },
  );
}
