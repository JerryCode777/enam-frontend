import 'package:enam_app/core/config/app_config.dart';
import 'package:enam_app/core/router/app_router.dart';
import 'package:enam_app/core/router/routes.dart';
import 'package:enam_app/features/subscription/presentation/widgets/opciones_de_pago.dart';
import 'package:flutter_test/flutter_test.dart';

/// Cómo se cobra, según la tienda (modelo Netflix).
///
/// Ni App Store ni Google Play dejan cobrar dentro de una app sin llevarse su
/// comisión, así que el pago ocurre en la web. Estos tests fijan las tres cosas
/// que ya se rompieron una vez:
///
///  1. La app **no tiene** pantallas de planes, pago ni resultado de pago. Las
///     tuvo, enseñaban precios en iPhone —guideline 3.1.1, motivo de rechazo— y
///     el checkout ni siquiera llamaba a un endpoint: anunciaba "pago exitoso"
///     tras esperar 900 ms, con cualquier tarjeta.
///  2. El enlace que la app abre lleva a `/activar`, que sabe recibir a alguien
///     sin sesión. Antes abría la raíz del sitio y la persona acababa en el
///     splash, y de ahí en el login.
///  3. La diferencia entre tiendas está en un solo sitio y se puede forzar, que
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

  group('El enlace a la web', () {
    test('lleva a la pantalla de activación, no a la raíz ni a los planes', () {
      final url = Uri.parse(AppConfig.urlActivar);

      expect(url.path, '/activar');
      // La raíz manda al splash y `/planes` al login: en los dos casos la
      // persona acaba lejos de lo que iba a hacer, y en un teclado de móvil.
      expect(url.path, isNot('/'));
      expect(url.path, isNot('/planes'));
    });

    test('declara de qué tienda viene, para poder medir los dos caminos', () {
      expect(Uri.parse(AppConfig.urlActivar).queryParameters['origen'], 'ios');
    });
  });

  group('La variante de tienda', () {
    // `enTiendaApple` es la única condición que decide qué se ofrece. Vivía
    // suelta en la pantalla de bloqueo, y por eso «Mi suscripción» se saltaba
    // el reparto entero y llegaba a los precios en iPhone.
    test('se puede forzar para revisar las dos sin cambiar de equipo', () {
      // Sin `--dart-define=TIENDA`, sale la del dispositivo; en los tests eso
      // es el host, que no es iOS.
      expect(AppConfig.tiendaForzada, isEmpty);
      expect(enTiendaApple, isFalse);
    });
  });
}
