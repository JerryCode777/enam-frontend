import 'package:enam_app/core/config/app_config.dart';
import 'package:enam_app/core/router/app_router.dart';
import 'package:enam_app/core/router/routes.dart';
import 'package:enam_app/features/subscription/presentation/widgets/opciones_de_pago.dart';
import 'package:enam_app/core/config/contacto.dart';
import 'package:enam_app/core/providers.dart';
import 'package:enam_app/core/theme/app_theme.dart';
import 'package:enam_app/features/auth/domain/auth_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
///  2. En iPhone solo se ofrece App Store: nada de enlaces a la web desde donde
///     se paga. En Android, la web con Mercado Pago. WhatsApp es solo ayuda;
///     el pago manual por Yape ya no existe.
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

  group('Solo App Store en iPhone, solo la web en Android', () {
    Future<void> montar(WidgetTester tester) async {
      tester.view
        ..physicalSize = const Size(393, 1400) * 3
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [authControllerProvider.overrideWith(_ConSesion.new)],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(
              body: SingleChildScrollView(child: OpcionesDePago()),
            ),
          ),
        ),
      );
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
    }

    testWidgets('iPhone: sin enlace a la web ni activación por WhatsApp', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      await montar(tester);
      expect(enTiendaApple, isTrue);
      // La nota que abría `/activar`, desde donde se paga en la web.
      expect(find.textContaining('enamprep.com'), findsNothing);
      expect(find.textContaining('Gestiona tu cuenta'), findsNothing);
      expect(find.textContaining('Activar'), findsNothing);
      expect(find.text('Escríbenos si necesitas ayuda'), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('Android: la web identificada y WhatsApp solo de ayuda', (
      tester,
    ) async {
      await montar(tester);
      expect(enTiendaApple, isFalse);
      expect(find.text('Continuar en el navegador'), findsOneWidget);
      expect(find.text('Activar por WhatsApp'), findsNothing);
      expect(find.text('Escríbenos si necesitas ayuda'), findsOneWidget);
    });

    test('el WhatsApp pide ayuda, no activar un pago', () {
      final mensaje = Contacto.ayudaConElAcceso().queryParameters['text']!;
      expect(mensaje, isNot(contains('activar')));
      expect(mensaje.toLowerCase(), isNot(contains('yape')));
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

class _ConSesion extends AuthController {
  @override
  Future<AuthState> build() async => const AuthSignedIn(
    User(id: 'u1', email: 'a@b.pe', nombre: 'Ana', emailVerificado: true),
  );
}
