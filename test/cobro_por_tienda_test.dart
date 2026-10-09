import 'package:enam_app/core/config/app_config.dart';
import 'package:enam_app/core/router/app_router.dart';
import 'package:enam_app/core/router/routes.dart';
import 'package:enam_app/features/subscription/presentation/widgets/opciones_de_pago.dart';
import 'package:flutter_test/flutter_test.dart';

/// Cómo se cobra, según la tienda (modelo Netflix).
///
/// En iPhone se cobra solo con App Store; en Android la app no vende (ver
/// `opciones_de_pago.dart`). Estos tests fijan las dos cosas que ya se
/// rompieron una vez:
///
///  1. La app **no tiene** pantallas de planes, pago ni resultado de pago. Las
///     tuvo, enseñaban precios en iPhone —guideline 3.1.1, motivo de rechazo— y
///     el checkout ni siquiera llamaba a un endpoint: anunciaba "pago exitoso"
///     tras esperar 900 ms, con cualquier tarjeta.
///  2. La diferencia entre tiendas está en un solo sitio y se puede forzar, que
///     es lo que permite revisar las dos variantes sin cambiar de dispositivo.
void main() {
  group('La app no cobra por dentro', () {
    test('sin acceso, lo alcanzable es lo justo para volver o irse', () {
      // Negarle a alguien el camino de vuelta a su propio dinero, o los
      // términos que aceptó, no es bloquear el producto: es atraparlo.
      expect(rutasSinAcceso, {
        Routes.accessEnded,
        Routes.mySubscription,
        Routes.help,
        Routes.terms,
      });
    });
  });

  group('La variante de tienda', () {
    // `enTiendaApple` es la única condición que decide qué se ofrece. Vivía
    // suelta en la pantalla de bloqueo, y por eso «Mi suscripción» se saltaba
    // el reparto entero y llegaba a los precios en iPhone.
    test('la web a la que enlaza está publicada, no en localhost', () {
      // Es una dirección que abre el navegador del usuario: un localhost por
      // defecto es un enlace roto en cuanto la app sale del equipo de quien
      // programa, y el fallo solo se ve en el móvil de otra persona.
      expect(AppConfig.webUrl, startsWith('https://'));
      expect(AppConfig.webUrl, isNot(contains('localhost')));
    });

    test('se puede forzar para revisar las dos sin cambiar de equipo', () {
      // Sin `--dart-define=TIENDA`, sale la del dispositivo; en los tests eso
      // es el host, que no es iOS.
      expect(AppConfig.tiendaForzada, isEmpty);
      expect(enTiendaApple, isFalse);
    });
  });
}
