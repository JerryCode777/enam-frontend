import 'dart:async';

import 'package:enam_app/core/analitica/analitica.dart';
import 'package:enam_app/core/providers.dart';
import 'package:enam_app/core/theme/app_theme.dart';
import 'package:enam_app/features/auth/domain/auth_models.dart';
import 'package:enam_app/features/consentimiento/data/consentimiento_repository.dart';
import 'package:enam_app/features/duelo/domain/duelo_models.dart';
import 'package:enam_app/features/profile/presentation/help_screen.dart';
import 'package:enam_app/features/subscription/data/google_play_iap_service.dart';
import 'package:enam_app/features/subscription/data/subscription_repository.dart';
import 'package:enam_app/features/subscription/domain/acceso.dart';
import 'package:enam_app/features/subscription/domain/subscription_models.dart';
import 'package:enam_app/features/subscription/presentation/access_ended_screen.dart';
import 'package:enam_app/features/subscription/presentation/my_subscription_screen.dart';
import 'package:enam_app/features/subscription/presentation/widgets/opciones_de_pago.dart';
import 'package:enam_app/features/subscription/presentation/widgets/planes_de_google_play.dart'
    show detalleNovedadesEnPlanes, tituloNovedadesEnPlanes;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/date_symbol_data_local.dart';

/// En Android se compra con Google Play Billing, y **solo** con él.
///
/// Hasta la 1.1.2 Android no tenía ningún camino de compra: se había quitado
/// el pago por la web (Play lo prohíbe para contenido digital) y la pantalla
/// solo decía que Premium iba con la cuenta. Del 10/10 al 25/10, 145 personas
/// de Android vieron Planes y ninguna pudo comprar.
///
/// Estas pruebas fijan las dos mitades: que se ofrecen los planes de Play, y
/// que no vuelve nada que lleve a pagar fuera de Play, tampoco cuando Play no
/// devuelve productos.
///
/// Los tests corren en el host, que no es iOS: `enTiendaApple` es falso y sale
/// la variante de Android.
void main() {
  setUpAll(() => initializeDateFormatting('es'));

  /// Lo que no puede aparecer en Android: llevaría a pagar fuera de Play.
  const prohibidos = [
    'navegador',
    'enlace por correo',
    'buzón',
    'Activar por WhatsApp',
    'activa tu plan',
    'Renuévalo',
    'enamprep.com',
    'Yape',
    'Mercado Pago',
    'en la web',
    'Tu acceso Premium se activa con tu cuenta',
  ];

  void sinPagoFueraDePlay(WidgetTester tester) {
    final textos = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
        .toList();
    for (final p in prohibidos) {
      expect(
        textos.where((t) => t.toLowerCase().contains(p.toLowerCase())),
        isEmpty,
        reason: '«$p» lleva a pagar fuera de Google Play',
      );
    }
  }

  test('los tests corren con la variante de Android', () {
    expect(enTiendaApple, isFalse);
  });

  group('con los productos en Play', () {
    for (final (nombre, pantalla) in [
      ('Acceso terminado', const AccessEndedScreen() as Widget),
      ('Mi suscripción', const MySubscriptionScreen()),
    ]) {
      testWidgets('$nombre ofrece los planes de Play', (tester) async {
        final t = _Montaje(sub: _expirada);
        await tester.pumpWidget(t.montar(pantalla));
        // En «Acceso terminado» la oferta aparece tras la explicación.
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();

        expect(find.text('Premium mensual'), findsOneWidget);
        expect(find.text('S/ 59.00'), findsOneWidget);
        expect(find.text('Suscribirme'), findsNWidgets(3));
        expect(find.text('Restaurar compras'), findsOneWidget);
        sinPagoFueraDePlay(tester);
      });
    }

    testWidgets('comprar abre Play a nombre de la cuenta y lo mide', (
      tester,
    ) async {
      final t = _Montaje(sub: _expirada);
      await tester.pumpWidget(t.montar(const Scaffold(body: _Opciones())));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Suscribirme').first);
      await tester.pump();

      expect(t.tienda.compradas, [('premium_mensual', 'u1')]);
      expect(t.analitica.registrados, [
        'consentimiento_visto lugar=planes',
        'checkout_started plan_id=mensual medio=google_play',
      ]);
    });

    testWidgets('solo las tres suscripciones, sin «(ENAM Prep)»', (
      tester,
    ) async {
      final t = _Montaje(sub: _expirada);
      await tester.pumpWidget(t.montar(const Scaffold(body: _Opciones())));
      await tester.pumpAndSettle();

      expect(find.text('Premium mensual'), findsOneWidget);
      expect(find.text('Premium trimestral'), findsOneWidget);
      expect(find.text('Premium semestral'), findsOneWidget);
      expect(find.textContaining('(ENAM Prep)'), findsNothing);
      expect(find.textContaining('Hasta tu ENAM'), findsNothing);
    });

    testWidgets('quien ya pagó ve «Ya tienes Premium», no precios', (
      tester,
    ) async {
      final t = _Montaje(sub: _premiumPorPlay);
      await tester.pumpWidget(t.montar(const Scaffold(body: _Opciones())));
      await tester.pumpAndSettle();

      expect(find.text('Ya tienes Premium.'), findsOneWidget);
      expect(find.text('Suscribirme'), findsNothing);
    });
  });

  group('sin productos en Play', () {
    testWidgets('vacío: lo dice, sin mandar a la web, y lo mide una vez', (
      tester,
    ) async {
      final t = _Montaje(sub: _expirada, productos: const []);
      await tester.pumpWidget(t.montar(const Scaffold(body: _Opciones())));
      await tester.pumpAndSettle();

      expect(
        find.text('No pudimos cargar los planes. Inténtalo más tarde.'),
        findsOneWidget,
      );
      sinPagoFueraDePlay(tester);

      // Reintentar dentro de la misma apertura no repite el evento.
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(t.analitica.registrados, [
        'planes_no_disponibles medio=google_play motivo=vacio',
      ]);
    });

    testWidgets('error: con el código de Play, nunca el mensaje', (
      tester,
    ) async {
      final t = _Montaje(
        sub: _expirada,
        falla: const FalloDeTienda(
          'Google Play Billing no está disponible.',
          codigo: 'billing_unavailable',
        ),
      );
      await tester.pumpWidget(t.montar(const Scaffold(body: _Opciones())));
      await tester.pumpAndSettle();

      expect(
        find.text('No pudimos cargar los planes. Inténtalo más tarde.'),
        findsOneWidget,
      );
      expect(t.analitica.registrados, [
        'planes_no_disponibles medio=google_play motivo=error '
            'codigo=billing_unavailable',
      ]);
    });
  });

  group('la casilla de novedades debajo de los planes', () {
    Finder casilla() => find.text(tituloNovedadesEnPlanes);

    Future<void> verCasilla(WidgetTester tester) async {
      await tester.scrollUntilVisible(casilla(), 300);
      await tester.pumpAndSettle();
    }

    testWidgets('desmarcada, con un texto que no habla de la web', (
      tester,
    ) async {
      final t = _Montaje(sub: _expirada);
      await tester.pumpWidget(t.montar(const Scaffold(body: _Opciones())));
      await tester.pumpAndSettle();
      await verCasilla(tester);

      // La única casilla de Planes.
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
      final texto = '$tituloNovedadesEnPlanes $detalleNovedadesEnPlanes'
          .toLowerCase();
      for (final p in ['web', 'pag', 'descuento', 'precio', 'enamprep.com']) {
        expect(texto, isNot(contains(p)), reason: p);
      }
      sinPagoFueraDePlay(tester);
      // Uno por apertura; nada se guarda hasta que la toque.
      expect(t.analitica.registrados, ['consentimiento_visto lugar=planes']);
      expect(t.consentimiento.decisiones, isEmpty);
    });

    testWidgets('marcar guarda el sí con origen planes; desmarcar, el no', (
      tester,
    ) async {
      final t = _Montaje(sub: _expirada);
      await tester.pumpWidget(t.montar(const Scaffold(body: _Opciones())));
      await tester.pumpAndSettle();
      await verCasilla(tester);

      await tester.tap(casilla());
      await tester.pumpAndSettle();
      await tester.tap(casilla());
      await tester.pumpAndSettle();

      expect(t.consentimiento.decisiones, [
        (true, OrigenConsentimiento.planes),
        (false, OrigenConsentimiento.planes),
      ]);
      expect(t.analitica.registrados, [
        'consentimiento_visto lugar=planes',
        'consentimiento_respuesta lugar=planes respuesta=si',
        'consentimiento_respuesta lugar=planes respuesta=no',
      ]);
      // Sigue a la vista aunque la cuenta ya haya decidido.
      expect(casilla(), findsOneWidget);
    });

    testWidgets('si no se pudo guardar, vuelve a desmarcarse y lo dice', (
      tester,
    ) async {
      final t = _Montaje(sub: _expirada)..consentimiento.falla = true;
      await tester.pumpWidget(t.montar(const Scaffold(body: _Opciones())));
      await tester.pumpAndSettle();
      await verCasilla(tester);

      await tester.tap(casilla());
      await tester.pumpAndSettle();

      expect(
        tester.widgetList<Checkbox>(find.byType(Checkbox)).map((c) => c.value),
        everyElement(isFalse),
      );
      expect(find.textContaining('No pudimos guardar'), findsOneWidget);
    });

    testWidgets('quien ya aceptó no la ve, y no se mide', (tester) async {
      final t = _Montaje(sub: _expirada, aceptaComerciales: true);
      await tester.pumpWidget(t.montar(const Scaffold(body: _Opciones())));
      await tester.pumpAndSettle();

      expect(casilla(), findsNothing);
      expect(t.analitica.registrados, isEmpty);
    });

    testWidgets('quien dijo que no sí la ve', (tester) async {
      final t = _Montaje(sub: _expirada, aceptaComerciales: false);
      await tester.pumpWidget(t.montar(const Scaffold(body: _Opciones())));
      await tester.pumpAndSettle();
      await verCasilla(tester);

      expect(casilla(), findsOneWidget);
    });

    testWidgets('sin planes no hay casilla', (tester) async {
      final t = _Montaje(sub: _expirada, productos: const []);
      await tester.pumpWidget(t.montar(const Scaffold(body: _Opciones())));
      await tester.pumpAndSettle();

      expect(casilla(), findsNothing);
    });
  });

  group('lo que se pagó por Google Play', () {
    testWidgets('la renovación la gestiona Play, no nuestro botón', (
      tester,
    ) async {
      // Nuestro servidor no detiene un cobro de Play: un «Cancelar renovación»
      // aquí haría creer que se canceló.
      final t = _Montaje(sub: _premiumPorPlay);
      await tester.pumpWidget(t.montar(const MySubscriptionScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Automática, por Google Play'), findsOneWidget);
      expect(
        find.text('Abrir mis suscripciones de Google Play'),
        findsOneWidget,
      );
      expect(find.text('Cancelar renovación'), findsNothing);
    });
  });

  testWidgets('quien es Premium por la web puede cancelar la renovación', (
    tester,
  ) async {
    // Gestionar lo que ya se pagó no es comprar: eso se queda.
    final t = _Montaje(sub: _premiumPorLaWeb);
    await tester.pumpWidget(t.montar(const MySubscriptionScreen()));
    await tester.pumpAndSettle();

    expect(find.text('ACTIVO'), findsOneWidget);
    expect(find.text('Cancelar renovación'), findsOneWidget);
  });

  testWidgets('la ayuda no habla de pagar fuera de la tienda', (tester) async {
    final t = _Montaje(sub: _expirada);
    await tester.pumpWidget(t.montar(const HelpScreen()));
    await tester.pumpAndSettle();

    sinPagoFueraDePlay(tester);
    expect(find.text('¿Qué incluye la cuenta gratis?'), findsOneWidget);
  });

  testWidgets('el botón de WhatsApp es de ayuda, no de activar', (
    tester,
  ) async {
    final t = _Montaje(sub: _expirada);
    await tester.pumpWidget(t.montar(const Scaffold(body: _Opciones())));
    await tester.pumpAndSettle();

    expect(find.text('Escríbenos si necesitas ayuda'), findsOneWidget);
    sinPagoFueraDePlay(tester);
  });
}

/// [OpcionesDePago] con sitio para desplazarse: son tres planes.
class _Opciones extends StatelessWidget {
  const _Opciones();

  @override
  Widget build(BuildContext context) =>
      ListView(children: const [OpcionesDePago()]);
}

ProductDetails _producto(String id, String titulo, String precio) =>
    ProductDetails(
      id: id,
      title: '$titulo (ENAM Prep)',
      description: 'Acceso completo.',
      price: precio,
      rawPrice: 1,
      currencyCode: 'PEN',
    );

final _productosDePlay = [
  _producto('premium_mensual', 'Premium mensual', 'S/ 59.00'),
  _producto('premium_trimestral', 'Premium trimestral', 'S/ 129.00'),
  _producto('premium_semestral', 'Premium semestral', 'S/ 229.00'),
];

class _Montaje {
  _Montaje({
    required this.sub,
    List<ProductDetails>? productos,
    FalloDeTienda? falla,
    this.aceptaComerciales,
  }) : tienda = _TiendaFalsa(productos ?? _productosDePlay, falla);

  final Subscription sub;
  final bool? aceptaComerciales;
  final _TiendaFalsa tienda;
  final analitica = _Capturadora();
  final consentimiento = _Consentimiento();

  Widget montar(Widget pantalla) => ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(() => _ConSesion(aceptaComerciales)),
      consentimientoRepositoryProvider.overrideWithValue(consentimiento),
      subscriptionProvider.overrideWith((ref) async => sub),
      subscriptionRepositoryProvider.overrideWithValue(_Repo(sub)),
      googlePlayIapServiceProvider.overrideWithValue(tienda),
      analiticaProvider.overrideWithValue(analitica),
      // Sin pase de duelo: el botón del duelo gratis no se pinta.
      paseDeDueloProvider.overrideWith((ref) async => const PaseDeDuelo()),
    ],
    child: MaterialApp(theme: AppTheme.light, home: pantalla),
  );
}

class _TiendaFalsa implements GooglePlayIapService {
  _TiendaFalsa(this._productos, this._falla);

  final List<ProductDetails> _productos;
  final FalloDeTienda? _falla;
  final compradas = <(String, String)>[];

  // ignore: close_sinks
  final _flujo = StreamController<List<PurchaseDetails>>.broadcast();

  @override
  Future<bool> disponible() async => true;

  @override
  Future<List<ProductDetails>> productos() async {
    if (_falla case final f?) throw f;
    return elegirUnoPorProducto(_productos);
  }

  @override
  Future<void> comprar(
    ProductDetails producto, {
    required String cuentaId,
  }) async => compradas.add((producto.id, cuentaId));

  @override
  Future<void> restaurar() async {}

  @override
  Stream<List<PurchaseDetails>> get compras => _flujo.stream;

  @override
  Future<void> completar(PurchaseDetails compra) async {}
}

class _Capturadora implements Analitica {
  /// «nombre clave=valor …», para comparar por contenido.
  final registrados = <String>[];

  @override
  void registrar(Evento evento, {Map<String, String> propiedades = const {}}) =>
      registrados.add(
        [
          evento.nombre,
          for (final MapEntry(:key, :value) in propiedades.entries)
            '$key=$value',
        ].join(' '),
      );

  @override
  Future<void> enviarPendientes() async {}
}

final _expirada = Subscription(
  id: 's1',
  plan: const Plan(
    id: 'prueba',
    nombre: 'Prueba de 1 día',
    precioCentimos: 0,
    duracionDias: 1,
    esGratuito: true,
  ),
  estado: SubscriptionStatus.expirada,
  origen: SubscriptionOrigin.sistema,
  inicia: DateTime(2026, 10, 1),
  expira: DateTime(2026, 10, 2),
);

final _premiumPorLaWeb = Subscription(
  id: 's2',
  plan: const Plan(
    id: 'mensual',
    nombre: 'Premium mensual',
    precioCentimos: 5900,
    duracionDias: 30,
  ),
  estado: SubscriptionStatus.activa,
  origen: SubscriptionOrigin.culqi,
  inicia: DateTime(2026, 10, 1),
  expira: DateTime(2026, 10, 31),
);

final _premiumPorPlay = _premiumPorLaWeb.copyWith(
  id: 's3',
  origen: SubscriptionOrigin.googlePlay,
  acceso: const AccesoPremium(),
);

class _ConSesion extends AuthController {
  _ConSesion(this.aceptaComerciales);

  final bool? aceptaComerciales;

  @override
  Future<AuthState> build() async => AuthSignedIn(_usuario(aceptaComerciales));
}

User _usuario(bool? aceptaComerciales) => User(
  id: 'u1',
  email: 'valeria.rojas@unmsm.edu.pe',
  nombre: 'Valeria Rojas',
  emailVerificado: true,
  aceptaComerciales: aceptaComerciales,
);

/// Anota cada decisión; con [falla], el PATCH revienta.
class _Consentimiento implements ConsentimientoRepository {
  final decisiones = <(bool, OrigenConsentimiento)>[];
  bool falla = false;

  @override
  Future<User> decidir({
    required bool acepta,
    required OrigenConsentimiento origen,
  }) async {
    if (falla) throw Exception('sin red');
    decisiones.add((acepta, origen));
    return _usuario(acepta);
  }
}

class _Repo implements SubscriptionRepository {
  _Repo(this.sub);

  final Subscription sub;

  @override
  Future<Subscription> current() async => sub;

  @override
  Future<void> enviarEnlaceDeSuscripcion(String email) =>
      throw StateError('En Android no se manda el enlace de pago');

  @override
  Future<String> enlaceDeSuscripcion() =>
      throw StateError('En Android no se abre la web para pagar');

  @override
  Future<void> cancelar() async {}

  @override
  Future<Subscription> canjearCompraApple(String jws) async => sub;

  @override
  Future<CanjeGooglePlay> canjearCompraGooglePlay({
    required String productId,
    required String purchaseToken,
  }) async => CanjeActivado(sub);
}
