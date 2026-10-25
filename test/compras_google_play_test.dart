import 'dart:async';

import 'package:enam_app/core/error/failure.dart';
import 'package:enam_app/features/subscription/data/compras_apple_controller.dart'
    show EstadoCompra;
import 'package:enam_app/features/subscription/data/compras_google_play_controller.dart';
import 'package:enam_app/features/subscription/data/fallo_de_tienda.dart';
import 'package:enam_app/features/subscription/data/google_play_iap_service.dart';
import 'package:enam_app/features/subscription/data/subscription_repository.dart';
import 'package:enam_app/features/subscription/domain/subscription_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// La compra con Google Play, de punta a punta, contra una tienda y un
/// servidor falsos. La regla es la de iOS: **solo con 200 se completa**. Las
/// respuestas son las de `enam-backend`, `GOOGLE-PLAY.md` §7 y §9.
void main() {
  late _TiendaFalsa tienda;
  late _RepoFalso repo;
  late ComprasGooglePlayController controlador;

  setUp(() {
    tienda = _TiendaFalsa();
    repo = _RepoFalso();
    controlador = ComprasGooglePlayController(
      tienda: tienda,
      suscripciones: repo,
    );
    controlador.escuchar();
  });

  tearDown(() => controlador.soltar());

  test('una compra que el servidor acepta (200) se completa', () async {
    final estados = <EstadoCompra>[];
    controlador.resultados.listen((r) => estados.add(r.estado));

    tienda.entregar(_compra(PurchaseStatus.purchased));
    await _dejarCorrer();

    expect(repo.canjeadas, [('premium_mensual', 'token-de-play')]);
    expect(tienda.completadas, hasLength(1));
    expect(estados, contains(EstadoCompra.listo));
  });

  test('con la red o el servidor caídos NO se completa', () async {
    for (final falla in const <Failure>[
      NetworkFailure('sin red'),
      ServerFailure('500'),
      // 503: GOOGLE_PLAY_ACTIVO apagado. Se registra sola cuando se encienda.
      MaintenanceFailure(
        'El pago por Google Play no está disponible por ahora.',
      ),
    ]) {
      repo.falla = falla;
      String? mensaje;
      final escucha = controlador.resultados.listen(
        (r) => mensaje = r.mensaje ?? mensaje,
      );

      tienda.entregar(_compra(PurchaseStatus.purchased));
      await _dejarCorrer();
      await escucha.cancel();

      expect(tienda.completadas, isEmpty, reason: '$falla');
      expect(mensaje!.toLowerCase(), contains('no pagues de nuevo'));
    }
  });

  test('pago pendiente (202): se avisa y no se completa', () async {
    repo.pendiente = true;
    final resultados = <(EstadoCompra, String?)>[];
    controlador.resultados.listen((r) => resultados.add((r.estado, r.mensaje)));

    tienda.entregar(_compra(PurchaseStatus.pending));
    await _dejarCorrer();

    expect(repo.canjeadas, hasLength(1), reason: 'pendiente también va');
    expect(tienda.completadas, isEmpty);
    expect(resultados.last.$1, EstadoCompra.pendiente);
    expect(resultados.last.$2, contains('pendiente'));
  });

  test('409 o 422: el mensaje del servidor, y se completa', () async {
    // Reintentar no lo arregla: si no se completara, reaparecería en cada
    // arranque con el mismo error.
    for (final falla in const <Failure>[
      UnknownFailure('Esa compra ya está asociada a otra cuenta de ENAM Prep.'),
      ValidationFailure('No pudimos validar tu compra. Inténtalo de nuevo.'),
    ]) {
      tienda.completadas.clear();
      repo.falla = falla;
      String? mensaje;
      final escucha = controlador.resultados.listen(
        (r) => mensaje = r.mensaje ?? mensaje,
      );

      tienda.entregar(_compra(PurchaseStatus.purchased));
      await _dejarCorrer();
      await escucha.cancel();

      expect(mensaje, falla.message);
      expect(tienda.completadas, hasLength(1));
    }
  });

  test('cancelar no es un error ni va al servidor', () async {
    final estados = <EstadoCompra>[];
    controlador.resultados.listen((r) => estados.add(r.estado));

    tienda.entregar(_compra(PurchaseStatus.canceled));
    await _dejarCorrer();

    expect(estados, isNot(contains(EstadoCompra.error)));
    expect(repo.canjeadas, isEmpty);
  });

  test('una restauración también pasa por el servidor', () async {
    tienda.entregar(_compra(PurchaseStatus.restored));
    await _dejarCorrer();

    expect(repo.canjeadas, hasLength(1));
    expect(tienda.completadas, hasLength(1));
  });

  test(
    'la misma compra dos veces seguidas va una sola vez al servidor',
    () async {
      // La compra y la restauración del arranque pueden llegar juntas.
      repo.demora = const Duration(milliseconds: 20);
      tienda.entregar(_compra(PurchaseStatus.purchased));
      tienda.entregar(_compra(PurchaseStatus.restored));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(repo.canjeadas, hasLength(1));
    },
  );

  test('comprar va a nombre de la cuenta (obfuscatedAccountId)', () async {
    await controlador.comprar(_producto('premium_mensual'), cuentaId: 'u-123');

    expect(tienda.compradas, [('premium_mensual', 'u-123')]);
  });

  test('al abrir la app, restaurar en silencio no emite nada', () async {
    final resultados = [];
    controlador.resultados.listen(resultados.add);

    await controlador.restaurarEnSilencio();

    expect(tienda.restauraciones, 1);
    expect(resultados, isEmpty);
  });

  group('los productos de Play', () {
    test('ids y planes del servidor', () {
      expect(productosGooglePlay, [
        'premium_mensual',
        'premium_trimestral',
        'premium_semestral',
      ]);
      expect(productosGooglePlay.map(planIdDeGooglePlay), [
        'mensual',
        'intensivo',
        'semestral',
      ]);
    });

    test('uno por producto, en el orden de la pantalla', () {
      final elegidos = elegirUnoPorProducto([
        _producto('premium_semestral'),
        _producto('premium_mensual'),
        _producto('premium_mensual'),
        _producto('otro'),
      ]);
      expect(elegidos.map((p) => p.id), [
        'premium_mensual',
        'premium_semestral',
      ]);
    });

    test('el código de la tienda, en minúsculas y sin mensaje', () {
      expect(
        codigoDeTienda(
          IAPError(
            source: 'google_play',
            code: 'BillingResponse.serviceUnavailable',
            message: 'Texto que no debe salir',
          ),
        ),
        'service_unavailable',
      );
      expect(
        codigoDeTienda(
          IAPError(source: 'google_play', code: 'network_error', message: ''),
        ),
        'network_error',
      );
      expect(codigoDeTienda(StateError('x')), 'desconocido');
    });
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

PurchaseDetails _compra(PurchaseStatus estado) {
  return PurchaseDetails(
      productID: 'premium_mensual',
      verificationData: PurchaseVerificationData(
        localVerificationData: '{}',
        serverVerificationData: 'token-de-play',
        source: 'google_play',
      ),
      transactionDate: '0',
      status: estado,
    )
    ..error = estado == PurchaseStatus.error
        ? IAPError(source: 'google_play', code: 'x', message: 'falló')
        : null;
}

class _TiendaFalsa implements GooglePlayIapService {
  final _flujo = StreamController<List<PurchaseDetails>>.broadcast();
  final completadas = <PurchaseDetails>[];
  final compradas = <(String, String)>[];
  var restauraciones = 0;

  void entregar(PurchaseDetails compra) => _flujo.add([compra]);

  @override
  Stream<List<PurchaseDetails>> get compras => _flujo.stream;

  @override
  Future<void> completar(PurchaseDetails compra) async =>
      completadas.add(compra);

  @override
  Future<bool> disponible() async => true;

  @override
  Future<List<ProductDetails>> productos() async => [];

  @override
  Future<void> comprar(
    ProductDetails producto, {
    required String cuentaId,
  }) async => compradas.add((producto.id, cuentaId));

  @override
  Future<void> restaurar() async => restauraciones++;
}

class _RepoFalso implements SubscriptionRepository {
  final canjeadas = <(String, String)>[];
  Failure? falla;
  bool pendiente = false;
  Duration demora = Duration.zero;

  @override
  Future<CanjeGooglePlay> canjearCompraGooglePlay({
    required String productId,
    required String purchaseToken,
  }) async {
    if (demora > Duration.zero) await Future<void>.delayed(demora);
    if (falla case final f?) throw f;
    canjeadas.add((productId, purchaseToken));
    if (pendiente) {
      return const CanjePendiente('Tu pago está pendiente en Google Play.');
    }
    return CanjeActivado(_suscripcion);
  }

  @override
  Future<Subscription> canjearCompraApple(String jws) async => _suscripcion;

  @override
  Future<Subscription> current() async => _suscripcion;

  @override
  Future<void> cancelar() async {}

  @override
  Future<String> enlaceDeSuscripcion() async => '';

  @override
  Future<void> enviarEnlaceDeSuscripcion(String email) async {}

  static final _suscripcion = Subscription(
    id: 's1',
    plan: const Plan(
      id: 'mensual',
      nombre: 'Mensual',
      precioCentimos: 5900,
      duracionDias: 30,
      beneficios: [],
    ),
    estado: SubscriptionStatus.activa,
    origen: SubscriptionOrigin.googlePlay,
    inicia: DateTime.utc(2026, 10, 25),
  );
}
