import 'dart:async';

import 'package:enam_app/core/error/failure.dart';
import 'package:enam_app/features/subscription/data/apple_iap_service.dart';
import 'package:enam_app/features/subscription/data/compras_apple_controller.dart';
import 'package:enam_app/features/subscription/data/subscription_repository.dart';
import 'package:enam_app/features/subscription/domain/subscription_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// El cobro por App Store, por el lado del móvil.
///
/// Lo único que hay que proteger aquí es esto: **una compra no se le confirma a
/// Apple hasta que el servidor la registra**. StoreKit guarda sin completar las
/// transacciones y las reentrega en cada arranque, así que mientras no se
/// complete, una compra que no llegó al servidor vuelve sola. Completarla antes
/// de tiempo la borra de esa cola: dinero cobrado y acceso sin dar, sin rastro.
void main() {
  late _TiendaFalsa tienda;
  late _RepoFalso repo;
  late ComprasAppleController controlador;

  setUp(() {
    tienda = _TiendaFalsa();
    repo = _RepoFalso();
    controlador = ComprasAppleController(tienda: tienda, suscripciones: repo);
    controlador.escuchar();
  });

  tearDown(() => controlador.soltar());

  test('una compra que el servidor acepta se confirma a Apple', () async {
    final estados = <EstadoCompra>[];
    controlador.resultados.listen((r) => estados.add(r.estado));

    tienda.entregar(_compra(PurchaseStatus.purchased));
    await _dejarCorrer();

    expect(repo.canjeadas, ['jws-de-apple']);
    expect(tienda.completadas, hasLength(1), reason: 'no se confirmó a Apple');
    expect(estados, contains(EstadoCompra.listo));
  });

  test('si el servidor falla, la compra NO se confirma a Apple', () async {
    // Es la prueba que sostiene todo. Con la transacción sin completar,
    // StoreKit la reentrega en el siguiente arranque y el usuario entra solo.
    repo.falla = const NetworkFailure('sin red');

    tienda.entregar(_compra(PurchaseStatus.purchased));
    await _dejarCorrer();

    expect(
      tienda.completadas,
      isEmpty,
      reason: 'se confirmó una compra que el servidor no registró: se pierde',
    );
  });

  test('cuando el servidor falla, el mensaje no invita a pagar de nuevo', () async {
    repo.falla = const NetworkFailure('sin red');
    String? mensaje;
    controlador.resultados.listen((r) => mensaje = r.mensaje ?? mensaje);

    tienda.entregar(_compra(PurchaseStatus.purchased));
    await _dejarCorrer();

    expect(mensaje, isNotNull);
    expect(mensaje!.toLowerCase(), contains('no pagues de nuevo'));
  });

  test('un rechazo definitivo se cuenta con las palabras del servidor', () async {
    // «Esa compra ya está en otra cuenta» no se arregla reintentando, así que
    // decirle que se activará solo sería mentirle.
    repo.falla = const UnknownFailure(
      'Esa compra ya está asociada a otra cuenta de ENAM Prep.',
    );
    String? mensaje;
    controlador.resultados.listen((r) => mensaje = r.mensaje ?? mensaje);

    tienda.entregar(_compra(PurchaseStatus.purchased));
    await _dejarCorrer();

    expect(mensaje, contains('otra cuenta'));
  });

  test('cancelar no es un error', () async {
    // Quien cierra la hoja de Apple no ha hecho nada mal.
    final estados = <EstadoCompra>[];
    controlador.resultados.listen((r) => estados.add(r.estado));

    tienda.entregar(_compra(PurchaseStatus.canceled));
    await _dejarCorrer();

    expect(estados, isNot(contains(EstadoCompra.error)));
    expect(repo.canjeadas, isEmpty);
  });

  test('una compra con error sí se confirma, para que no se repita siempre', () async {
    // Si quedara en la cola, reaparecería en cada arranque enseñando el mismo
    // fallo para siempre.
    tienda.entregar(_compra(PurchaseStatus.error));
    await _dejarCorrer();

    expect(tienda.completadas, hasLength(1));
    expect(repo.canjeadas, isEmpty);
  });

  test('una restauración también pasa por el servidor', () async {
    // Reinstalar la app o cambiar de iPhone tiene que devolver el acceso sin
    // volver a pagar, y el servidor es quien lo concede.
    tienda.entregar(_compra(PurchaseStatus.restored));
    await _dejarCorrer();

    expect(repo.canjeadas, ['jws-de-apple']);
    expect(tienda.completadas, hasLength(1));
  });

  test('sin transacción firmada no se confirma nada', () async {
    // Un JWS vacío es un tropiezo de StoreKit, no una compra inválida: dejarla
    // en la cola es lo que permite que vuelva entera.
    tienda.entregar(_compra(PurchaseStatus.purchased, jws: ''));
    await _dejarCorrer();

    expect(repo.canjeadas, isEmpty);
    expect(tienda.completadas, isEmpty);
  });
}

/// Deja correr los `Future` encadenados del controlador.
Future<void> _dejarCorrer() => Future<void>.delayed(Duration.zero);

PurchaseDetails _compra(PurchaseStatus estado, {String jws = 'jws-de-apple'}) {
  return PurchaseDetails(
    productID: 'pe.jakstech.enamApp.mensual',
    verificationData: PurchaseVerificationData(
      localVerificationData: '{}',
      serverVerificationData: jws,
      source: 'app_store',
    ),
    transactionDate: '0',
    status: estado,
  )..error = estado == PurchaseStatus.error
      ? IAPError(source: 'app_store', code: 'x', message: 'falló')
      : null;
}

class _TiendaFalsa implements AppleIapService {
  final _flujo = StreamController<List<PurchaseDetails>>.broadcast();
  final completadas = <PurchaseDetails>[];

  void entregar(PurchaseDetails compra) => _flujo.add([compra]);

  @override
  Stream<List<PurchaseDetails>> get compras => _flujo.stream;

  @override
  Future<void> completar(PurchaseDetails compra) async => completadas.add(compra);

  @override
  Future<bool> disponible() async => true;

  @override
  Future<List<ProductDetails>> productos() async => [];

  @override
  Future<void> comprar(ProductDetails producto) async {}

  @override
  Future<void> restaurar() async {}
}

class _RepoFalso implements SubscriptionRepository {
  final canjeadas = <String>[];
  Failure? falla;

  @override
  Future<Subscription> canjearCompraApple(String jws) async {
    if (falla case final f?) throw f;
    canjeadas.add(jws);
    return _suscripcion;
  }

  @override
  Future<Subscription> current() async => _suscripcion;

  @override
  Future<void> cancelar() async {}

  @override
  Future<String> enlaceDeSuscripcion() async => 'https://enamprep.com/activar';

  @override
  Future<void> enviarEnlaceDeSuscripcion(String email) async {}

  static const _plan = Plan(
    id: 'mensual',
    nombre: 'Mensual',
    precioCentimos: 5900,
    duracionDias: 30,
    beneficios: [],
  );

  static final _suscripcion = Subscription(
    id: 's1',
    plan: _plan,
    estado: SubscriptionStatus.activa,
    origen: SubscriptionOrigin.apple,
    inicia: DateTime.utc(2026, 8, 2),
  );
}
