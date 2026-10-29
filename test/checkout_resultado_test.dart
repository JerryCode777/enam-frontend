import 'dart:async';

import 'package:dio/dio.dart';
import 'package:enam_app/core/analitica/analitica.dart';
import 'package:enam_app/core/error/failure.dart';
import 'package:enam_app/features/subscription/data/apple_iap_service.dart';
import 'package:enam_app/features/subscription/data/compras_apple_controller.dart';
import 'package:enam_app/features/subscription/data/compras_google_play_controller.dart';
import 'package:enam_app/features/subscription/data/google_play_iap_service.dart';
import 'package:enam_app/features/subscription/data/resultado_de_checkout.dart';
import 'package:enam_app/features/subscription/data/subscription_repository.dart';
import 'package:enam_app/features/subscription/domain/subscription_models.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// `checkout_resultado` (catálogo 40): qué pasa después de
/// `checkout_started`. Antes no se veía nada: 10 compras empezadas en 30 días
/// y ningún desenlace.
void main() {
  group('Google Play', () {
    late _Play tienda;
    late _Repo repo;
    late _Analitica analitica;
    late ComprasGooglePlayController c;

    setUp(() {
      tienda = _Play();
      repo = _Repo();
      analitica = _Analitica();
      c = ComprasGooglePlayController(
        tienda: tienda,
        suscripciones: repo,
        analitica: analitica,
      )..escuchar();
    });
    tearDown(() => c.soltar());

    Future<void> comprarY(PurchaseDetails desenlace) async {
      await c.comprar(_producto('premium_mensual'), cuentaId: 'u1');
      tienda.entregar(desenlace);
      await _dejarCorrer();
    }

    test('completada: solo cuando el servidor la registró', () async {
      await comprarY(_compra(PurchaseStatus.purchased));
      expect(analitica.registrados, [
        'checkout_resultado medio=google_play plan_id=mensual '
            'resultado=completado intento=compra',
      ]);
    });

    test('cancelada al cerrar la hoja de Play', () async {
      await comprarY(_compra(PurchaseStatus.canceled));
      expect(analitica.registrados, [
        'checkout_resultado medio=google_play plan_id=mensual '
            'resultado=cancelado intento=compra',
      ]);
    });

    test('error de Play: el BillingResponse, nunca el mensaje', () async {
      await comprarY(
        _compra(PurchaseStatus.error)
          ..error = IAPError(
            source: 'google_play',
            code: 'purchase_error',
            message: 'BillingResponse.itemAlreadyOwned',
            details: 'Item is already owned by user@gmail.com',
          ),
      );
      expect(analitica.registrados, [
        'checkout_resultado medio=google_play plan_id=mensual '
            'resultado=error intento=compra etapa=tienda '
            'codigo=item_already_owned',
      ]);
    });

    test('pagó y nuestro servidor falló: etapa servidor', () async {
      repo.falla = const NetworkFailure();
      await comprarY(_compra(PurchaseStatus.purchased));
      expect(analitica.registrados.single, contains('etapa=servidor'));
      expect(analitica.registrados.single, contains('codigo=red'));
    });

    test('pendiente: el servidor responde 202', () async {
      repo.pendiente = true;
      await comprarY(_compra(PurchaseStatus.pending));
      expect(analitica.registrados.single, contains('resultado=pendiente'));
    });

    test('lo ya reconocido que vuelve al abrir la app no se mide', () async {
      // Quien ya es Premium: Play lo entrega en cada arranque.
      tienda.entregar(_compra(PurchaseStatus.restored));
      await _dejarCorrer();
      expect(repo.canjeadas, hasLength(1));
      expect(analitica.registrados, isEmpty);
    });

    test(
      'una compra a medias que llega al abrir la app es un reintento',
      () async {
        tienda.entregar(
          _compra(PurchaseStatus.purchased)..pendingCompletePurchase = true,
        );
        await _dejarCorrer();
        expect(analitica.registrados, [
          'checkout_resultado medio=google_play plan_id=mensual '
              'resultado=completado intento=reintento',
        ]);
      },
    );

    test('todo lo que se mide lo acepta el contrato', () async {
      await comprarY(_compra(PurchaseStatus.canceled));
      await comprarY(_compra(PurchaseStatus.error));
      repo.falla = const ServerFailure('500');
      await comprarY(_compra(PurchaseStatus.purchased));
      for (final (evento, props) in analitica.eventos) {
        expect(
          propiedadesValidas(evento, props, plataforma: 'android'),
          isNotNull,
          reason: '$props',
        );
      }
    });
  });

  group('App Store', () {
    test('completada y cancelada, con su plan', () async {
      final tienda = _Apple();
      final analitica = _Analitica();
      final c = ComprasAppleController(
        tienda: tienda,
        suscripciones: _Repo(),
        analitica: analitica,
      )..escuchar();
      addTearDown(c.soltar);

      await c.comprar(_producto('pe.jakstech.enamApp.semestral'));
      tienda.entregar(_compra(PurchaseStatus.purchased, apple: true));
      await _dejarCorrer();
      await c.comprar(_producto('pe.jakstech.enamApp.semestral'));
      tienda.entregar(_compra(PurchaseStatus.canceled, apple: true));
      await _dejarCorrer();

      expect(analitica.registrados, [
        'checkout_resultado medio=apple plan_id=semestral '
            'resultado=completado intento=compra',
        'checkout_resultado medio=apple plan_id=semestral '
            'resultado=cancelado intento=compra',
      ]);
    });

    test('StoreKit 2 no pudo abrir la compra: su código', () async {
      final tienda = _Apple()
        ..falla = PlatformException(code: 'storekit2_purchase_failed');
      final analitica = _Analitica();
      final c = ComprasAppleController(
        tienda: tienda,
        suscripciones: _Repo(),
        analitica: analitica,
      );
      addTearDown(c.soltar);

      await c.comprar(_producto('pe.jakstech.enamApp.mensual'));
      expect(analitica.registrados.single, contains('etapa=tienda'));
      expect(
        analitica.registrados.single,
        contains('codigo=storekit2_purchase_failed'),
      );
    });
  });

  test('el código del servidor: el del backend, o la clase', () {
    expect(
      codigoDeServidor(const ForbiddenFailure('x', 'COMPRA_DE_OTRA_CUENTA')),
      'compra_de_otra_cuenta',
    );
    expect(codigoDeServidor(const TimeoutFailure()), 'timeout');
    final opts = RequestOptions(path: '/x');
    expect(
      codigoDeServidor(
        UnknownFailure(
          'x',
          DioException(
            requestOptions: opts,
            response: Response<void>(requestOptions: opts, statusCode: 409),
          ),
        ),
      ),
      'http_409',
    );
  });
}

Future<void> _dejarCorrer() => Future<void>.delayed(Duration.zero);

ProductDetails _producto(String id) => ProductDetails(
  id: id,
  title: id,
  description: '',
  price: 'S/ 1.00',
  rawPrice: 1,
  currencyCode: 'PEN',
);

PurchaseDetails _compra(PurchaseStatus estado, {bool apple = false}) =>
    PurchaseDetails(
        productID: apple ? 'pe.jakstech.enamApp.semestral' : 'premium_mensual',
        verificationData: PurchaseVerificationData(
          localVerificationData: '{}',
          serverVerificationData: 'token',
          source: apple ? 'app_store' : 'google_play',
        ),
        transactionDate: '0',
        status: estado,
      )
      ..error = estado == PurchaseStatus.error
          ? IAPError(
              source: 'google_play',
              code: 'purchase_error',
              message: 'BillingResponse.serviceUnavailable',
            )
          : null;

class _Play implements GooglePlayIapService {
  final _flujo = StreamController<List<PurchaseDetails>>.broadcast();

  void entregar(PurchaseDetails compra) => _flujo.add([compra]);

  @override
  Stream<List<PurchaseDetails>> get compras => _flujo.stream;

  @override
  Future<void> completar(PurchaseDetails compra) async {}

  @override
  Future<bool> disponible() async => true;

  @override
  Future<List<ProductDetails>> productos() async => [];

  @override
  Future<void> comprar(
    ProductDetails producto, {
    required String cuentaId,
  }) async {}

  @override
  Future<void> restaurar() async {}

  @override
  Future<DiagnosticoDePlay> diagnostico() async => const DiagnosticoDePlay();
}

class _Apple implements AppleIapService {
  final _flujo = StreamController<List<PurchaseDetails>>.broadcast();
  Object? falla;

  void entregar(PurchaseDetails compra) => _flujo.add([compra]);

  @override
  Stream<List<PurchaseDetails>> get compras => _flujo.stream;

  @override
  Future<void> completar(PurchaseDetails compra) async {}

  @override
  Future<bool> disponible() async => true;

  @override
  Future<List<ProductDetails>> productos() async => [];

  @override
  Future<void> comprar(ProductDetails producto) async {
    if (falla case final f?) throw f;
  }

  @override
  Future<void> restaurar() async {}

  // `diagnostico()` llega con #38: así compila antes y después.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Repo implements SubscriptionRepository {
  final canjeadas = <String>[];
  Failure? falla;
  bool pendiente = false;

  @override
  Future<CanjeGooglePlay> canjearCompraGooglePlay({
    required String productId,
    required String purchaseToken,
  }) async {
    if (falla case final f?) throw f;
    canjeadas.add(productId);
    if (pendiente) return const CanjePendiente('Pago pendiente.');
    return CanjeActivado(_sub);
  }

  @override
  Future<Subscription> canjearCompraApple(String jws) async {
    if (falla case final f?) throw f;
    return _sub;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  static final _sub = Subscription(
    id: 's1',
    plan: const Plan(
      id: 'mensual',
      nombre: 'Mensual',
      precioCentimos: 0,
      duracionDias: 30,
      esGratuito: false,
    ),
    estado: SubscriptionStatus.activa,
    origen: SubscriptionOrigin.googlePlay,
    inicia: DateTime(2026, 10, 1),
    expira: DateTime(2026, 11, 1),
  );
}

class _Analitica implements Analitica {
  final registrados = <String>[];
  final eventos = <(Evento, Map<String, String>)>[];

  @override
  void registrar(Evento evento, {Map<String, String> propiedades = const {}}) {
    eventos.add((evento, propiedades));
    registrados.add(
      [
        evento.nombre,
        for (final p in propiedades.entries) '${p.key}=${p.value}',
      ].join(' '),
    );
  }

  @override
  Future<void> enviarPendientes() async {}
}
