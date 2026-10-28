import 'dart:async';

import 'package:enam_app/core/analitica/analitica.dart';
import 'package:enam_app/core/providers.dart';
import 'package:enam_app/core/theme/app_theme.dart';
import 'package:enam_app/features/auth/domain/auth_models.dart';
import 'package:enam_app/features/subscription/data/apple_iap_service.dart';
import 'package:enam_app/features/subscription/data/fallo_de_tienda.dart';
import 'package:enam_app/features/subscription/domain/subscription_models.dart';
import 'package:enam_app/features/subscription/presentation/widgets/planes_de_apple.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// iOS sin planes (27–28/10/2026): 6 personas reales recibieron
/// `storekit_no_response`, que **no** es un fallo de conexión: StoreKit 2 lo
/// lanza cuando App Store responde sin ninguno de los productos.
void main() {
  group('el servicio', () {
    test('storekit_no_response es «vacío», con su diagnóstico', () async {
      final servicio = AppleIapServiceImpl(
        tienda: _StoreKit(
          error: IAPError(
            source: 'app_store',
            code: 'storekit_no_response',
            message: 'StoreKit: Failed to get response from platform.',
          ),
          pais: 'PER',
        ),
      );

      expect(await servicio.productos(), isEmpty);
      final d = await servicio.diagnostico();
      expect(d.propiedades, {
        'pais_tienda': 'pe',
        'productos_tienda': '0',
        'no_encontrados': '3',
      });
    });

    test('un fallo de verdad sigue siendo error', () async {
      final servicio = AppleIapServiceImpl(
        tienda: _StoreKit(
          error: IAPError(
            source: 'app_store',
            code: 'storekit2_products_error',
            message: 'The Internet connection appears to be offline.',
          ),
        ),
      );

      await expectLater(
        servicio.productos(),
        throwsA(
          isA<FalloDeTienda>().having(
            (f) => f.codigo,
            'codigo',
            'storekit2_products_error',
          ),
        ),
      );
    });
  });

  test('el país de App Store llega en tres letras y se manda en dos', () {
    expect(paisDeAppStore('PER'), 'pe');
    expect(paisDeAppStore('usa'), 'us');
    expect(paisDeAppStore('PE'), 'pe');
    // Los 13 de la app, todos con su país.
    for (final (a3, a2) in const [
      ('PER', 'pe'), ('ARG', 'ar'), ('BOL', 'bo'), ('BRA', 'br'),
      ('CHL', 'cl'), ('COL', 'co'), ('ECU', 'ec'), ('PRY', 'py'),
      ('URY', 'uy'), ('VEN', 've'), ('SUR', 'sr'), ('GUY', 'gy'),
      ('MEX', 'mx'),
    ]) {
      expect(paisDeAppStore(a3), a2, reason: a3);
    }
    // Uno que no se conoce no se inventa.
    expect(paisDeAppStore('ZZZ'), isNull);
    expect(paisDeAppStore(''), isNull);
  });

  testWidgets('la pantalla: sin callejón, con ayuda y sin la web', (
    tester,
  ) async {
    final analitica = _Capturadora();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_ConSesion.new),
          subscriptionProvider.overrideWith((ref) async => _expirada),
          appleIapServiceProvider.overrideWithValue(_Vacia()),
          analiticaProvider.overrideWithValue(analitica),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: PlanesDeApple()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Los planes no están disponibles en tu cuenta de App Store en este '
        'momento. Escríbenos y te ayudamos.',
      ),
      findsOneWidget,
    );
    expect(find.text('Escríbenos por WhatsApp'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.textContaining('web'), findsNothing);

    // «vacío», no «error», y con el país y lo que dio App Store.
    expect(analitica.registrados, [
      'planes_no_disponibles medio=apple motivo=vacio pais_tienda=pe '
          'productos_tienda=0 no_encontrados=3',
    ]);
    expect(
      propiedadesValidas(Evento.planesNoDisponibles, {
        'medio': 'apple',
        'motivo': 'vacio',
        'pais_tienda': 'pe',
        'productos_tienda': '0',
        'no_encontrados': '3',
      }, plataforma: 'ios'),
      isNotNull,
    );
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
}

/// StoreKit con una respuesta fija.
class _StoreKit implements InAppPurchase {
  _StoreKit({required this.error, this.pais = ''});

  final IAPError error;
  final String pais;

  @override
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> identifiers,
  ) async => ProductDetailsResponse(
    productDetails: const [],
    notFoundIDs: identifiers.toList(),
    error: error,
  );

  @override
  Future<String> countryCode() async => pais;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// App Store sin ninguno de los tres productos, en Perú.
class _Vacia implements AppleIapService {
  @override
  Future<bool> disponible() async => true;

  @override
  Future<List<ProductDetails>> productos() async => const [];

  @override
  Future<DiagnosticoDeTienda> diagnostico() async => const DiagnosticoDeTienda(
    pais: 'pe',
    productosTienda: 0,
    noEncontrados: 3,
  );

  @override
  Future<void> comprar(ProductDetails producto) async {}

  @override
  Future<void> restaurar() async {}

  // ignore: close_sinks
  final _flujo = StreamController<List<PurchaseDetails>>.broadcast();

  @override
  Stream<List<PurchaseDetails>> get compras => _flujo.stream;

  @override
  Future<void> completar(PurchaseDetails compra) async {}
}

class _Capturadora implements Analitica {
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

class _ConSesion extends AuthController {
  @override
  Future<AuthState> build() async => const AuthSignedIn(
    User(id: 'u1', email: 'a@b.pe', nombre: 'Ana', emailVerificado: true),
  );
}
