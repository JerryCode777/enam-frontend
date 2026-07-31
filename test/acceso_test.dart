import 'package:enam_app/core/providers.dart';
import 'package:enam_app/core/router/app_router.dart';
import 'package:enam_app/core/router/routes.dart';
import 'package:enam_app/core/storage/app_prefs.dart';
import 'package:enam_app/features/auth/data/mock_auth_repository.dart';
import 'package:enam_app/features/auth/domain/auth_models.dart';
import 'package:enam_app/features/subscription/domain/subscription_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// RN-03 v2 · SSD-ENAM-002 §1 — el modelo de cobro de 1 día.
///
/// Lo que se fija aquí es lo que más fácil se rompe al tocar el router: que un
/// usuario expirado quede bloqueado (D-01) y que uno con la prueba **sin
/// empezar** no lo esté, aunque no tenga fecha de expiración (D-02).
///
/// El caso de `expira == null` es el que un `DateTime.now().isBefore(expira)`
/// escrito sin pensar convierte en un bloqueo a todo usuario recién registrado.
void main() {
  const planPrueba = Plan(
    id: 'prueba',
    nombre: 'Prueba de 1 día',
    precioCentimos: 0,
    duracionDias: 1,
    esGratuito: true,
  );

  const planMensual = Plan(
    id: 'mensual',
    nombre: 'Premium mensual',
    precioCentimos: 4900,
    duracionDias: 30,
  );

  Subscription sub(
    SubscriptionStatus estado, {
    Plan plan = planPrueba,
    Duration? faltaParaExpirar,
  }) => Subscription(
    id: 's1',
    plan: plan,
    estado: estado,
    origen: SubscriptionOrigin.sistema,
    inicia: DateTime.now().subtract(const Duration(hours: 2)),
    expira: faltaParaExpirar == null
        ? null
        : DateTime.now().add(faltaParaExpirar),
  );

  group('Modelo de acceso', () {
    test('la prueba sin empezar da acceso aunque no tenga fecha de fin', () {
      // D-02: el reloj arranca en la primera práctica, así que `expira` nace
      // nulo. Leerlo como "expiró hace rato" bloquearía a todo recién
      // registrado.
      final s = sub(SubscriptionStatus.pruebaSinIniciar);

      expect(s.expira, isNull);
      expect(s.daAcceso, isTrue);
      expect(s.pruebaSinEmpezar, isTrue);
      expect(s.enPrueba, isTrue);
    });

    test('la prueba corriendo da acceso hasta su fecha', () {
      expect(
        sub(
          SubscriptionStatus.prueba,
          faltaParaExpirar: const Duration(hours: 5),
        ).daAcceso,
        isTrue,
      );
      expect(
        sub(
          SubscriptionStatus.prueba,
          faltaParaExpirar: const Duration(hours: -1),
        ).daAcceso,
        isFalse,
      );
    });

    test('expirada y cancelada no dan acceso', () {
      expect(sub(SubscriptionStatus.expirada).daAcceso, isFalse);
      expect(sub(SubscriptionStatus.cancelada).daAcceso, isFalse);
      expect(sub(SubscriptionStatus.expirada).sinAcceso, isTrue);
    });

    test('en gracia conserva acceso: falló el cobro, no la vigencia (RF-27)', () {
      final s = sub(
        SubscriptionStatus.enGracia,
        plan: planMensual,
        faltaParaExpirar: const Duration(days: 2),
      );
      expect(s.daAcceso, isTrue);
    });

    test('estar en prueba NO cuenta como plan pagado vigente (RF-42)', () {
      // Es la decisión más fina del backend de la app hermana: así el bot le
      // puede vender a alguien que todavía está probando, en vez de
      // responderle "ya tienes acceso" y perder la venta.
      final probando = sub(
        SubscriptionStatus.prueba,
        faltaParaExpirar: const Duration(hours: 5),
      );
      final pagando = sub(
        SubscriptionStatus.activa,
        plan: planMensual,
        faltaParaExpirar: const Duration(days: 20),
      );

      expect(probando.daAcceso, isTrue);
      expect(probando.planPagadoVigente, isFalse);
      expect(pagando.planPagadoVigente, isTrue);
    });

    test('"por expirar" no se aplica a la prueba', () {
      // Son 24 h: sería cierto desde el primer minuto y no diría nada.
      expect(
        sub(
          SubscriptionStatus.prueba,
          faltaParaExpirar: const Duration(hours: 20),
        ).porExpirar,
        isFalse,
      );
      expect(
        sub(
          SubscriptionStatus.activa,
          plan: planMensual,
          faltaParaExpirar: const Duration(days: 3),
        ).porExpirar,
        isTrue,
      );
    });
  });

  group('Guarda del router (D-01)', () {
    late _Prefs prefs;

    setUp(() => prefs = _Prefs());

    Future<ProviderContainer> conSesion() async {
      final c = ProviderContainer(
        overrides: [
          appPrefsProvider.overrideWithValue(prefs),
          authRepositoryProvider.overrideWithValue(_RepoConSesion()),
        ],
      );
      addTearDown(c.dispose);
      await c.read(startupProvider.future);
      await c.read(authControllerProvider.future);
      return c;
    }

    String? destino(
      ProviderContainer c,
      String desde,
      AsyncValue<Subscription> suscripcion,
    ) => decidirDestino(
      auth: c.read(authControllerProvider),
      startup: c.read(startupProvider),
      suscripcion: suscripcion,
      here: desde,
    );

    test('sin acceso, la app queda tras la pantalla de pago', () async {
      final c = await conSesion();
      final expirada = AsyncData(sub(SubscriptionStatus.expirada));

      // Nada del producto sigue alcanzable: es la decisión del cliente.
      expect(destino(c, Routes.home, expirada), Routes.accessEnded);
      expect(destino(c, Routes.temario, expirada), Routes.accessEnded);
      expect(destino(c, Routes.stats, expirada), Routes.accessEnded);
      expect(destino(c, Routes.simulacroSelection, expirada), Routes.accessEnded);
    });

    test('sin acceso, el camino para pagar sigue abierto', () async {
      final c = await conSesion();
      final expirada = AsyncData(sub(SubscriptionStatus.expirada));

      // Cerrarle a alguien el camino de vuelta a su propio dinero, o los
      // términos que aceptó, no es bloquear el producto: es atraparlo.
      expect(destino(c, Routes.accessEnded, expirada), isNull);
      // No se comprueban /planes ni /pago: no existen en la app. Las tiendas no
      // dejan cobrar dentro sin su comisión, así que el pago vive en la web.
      expect(destino(c, Routes.mySubscription, expirada), isNull);
      expect(destino(c, Routes.help, expirada), isNull);
      expect(destino(c, Routes.terms, expirada), isNull);
    });

    test('la prueba sin empezar no bloquea nada', () async {
      final c = await conSesion();
      final nueva = AsyncData(sub(SubscriptionStatus.pruebaSinIniciar));

      expect(destino(c, Routes.home, nueva), isNull);
      expect(destino(c, Routes.temario, nueva), isNull);
    });

    test('mientras la suscripción carga no se bloquea', () async {
      final c = await conSesion();

      // Bloquear por defecto haría parpadear la pantalla de pago en cada
      // arranque. El contenido lo protege el servidor (RNF-04), no el router.
      expect(
        destino(c, Routes.home, const AsyncLoading<Subscription>()),
        isNull,
      );
    });

    test('si la petición falla tampoco se bloquea', () async {
      final c = await conSesion();
      final error = AsyncError<Subscription>(Exception('sin red'), StackTrace.empty);

      // Quedarse sin señal no puede leerse como "no pagaste".
      expect(destino(c, Routes.home, error), isNull);
    });

    test('con acceso, la pantalla de bloqueo devuelve al inicio', () async {
      final c = await conSesion();
      // Es a donde vuelve alguien que acaba de pagar.
      final activa = AsyncData(
        sub(
          SubscriptionStatus.activa,
          plan: planMensual,
          faltaParaExpirar: const Duration(days: 20),
        ),
      );

      expect(destino(c, Routes.accessEnded, activa), Routes.home);
    });
  });
}

class _Prefs implements AppPrefs {
  final nacionales = <String>{};

  @override
  Future<bool> onboardingVisto() async => true;

  @override
  Future<void> marcarOnboardingVisto() async {}

  @override
  Future<Set<String>> nacionalesInscritos() async => nacionales;

  @override
  Future<void> marcarInscritoEnNacional(String id) async => nacionales.add(id);

  @override
  Future<DateTime?> inicioPrueba() async => null;

  @override
  Future<DateTime> marcarInicioPrueba() async => DateTime.now();

  @override
  Future<void> reiniciarPrueba() async {}
}

class _RepoConSesion extends MockAuthRepository {
  @override
  Future<User?> currentUser() async => User(
    id: 'u1',
    email: 'a@b.pe',
    nombre: 'Ana',
    emailVerificado: true,
    universidad: 'UNSA',
    condicion: StudentCondition.interno,
    fechaObjetivo: DateTime(2026, 12, 1),
  );
}
