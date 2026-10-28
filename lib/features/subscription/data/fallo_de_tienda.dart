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
///
/// [diagnostico] son las propiedades del diagnóstico de la tienda
/// (`DiagnosticoDePlay.propiedades`), para saber por qué no hubo planes.
void registrarPlanesNoDisponibles(
  Analitica analitica, {
  required String medio,
  Object? error,
  Map<String, String> diagnostico = const {},
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
      ...diagnostico,
    },
  );
}

/// Lo que se mide cuando Planes queda vacío (catálogo 37). Nació en Android
/// (26/10/2026: 5 de ~7 personas reales no vieron ningún plan, y la prueba de
/// Jerry sí los veía) y sirve igual en iPhone, sin [instalador].
///
/// Las hipótesis que separa:
/// - **País:** los planes base solo están configurados para PE. Una cuenta de
///   Play de otro país no recibe ninguno → [pais].
/// - **Instalación:** una app que Play no instaló (APK suelto, adb) no tiene
///   productos → [instalador].
/// - **Nuestro filtro:** Play los dio y los descartamos → [productosTienda]
///   mayor que cero con la lista vacía.
class DiagnosticoDeTienda {
  const DiagnosticoDeTienda({
    this.pais,
    this.productosTienda,
    this.noEncontrados,
    this.instalador,
  });

  /// País de la cuenta de la tienda (BillingConfig de Play, Storefront de
  /// App Store), ISO 3166 de dos letras en minúsculas.
  final String? pais;

  /// Entradas que devolvió la tienda **antes** de nuestro filtro.
  final int? productosTienda;

  /// Cuántos de los ids pedidos la tienda no encontró (`notFoundIDs`).
  final int? noEncontrados;

  /// Solo Android: `play`, `otro` o `ninguno` (ver `instaladorDe`).
  final String? instalador;

  /// Las propiedades de `planes_no_disponibles`, solo las que se saben.
  Map<String, String> get propiedades => {
    'pais_tienda': ?pais,
    'productos_tienda': ?productosTienda?.toString(),
    'no_encontrados': ?noEncontrados?.toString(),
    'instalador': ?instalador,
  };
}
