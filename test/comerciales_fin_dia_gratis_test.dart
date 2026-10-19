import 'package:enam_app/core/analitica/analitica.dart';
import 'package:enam_app/core/domain/hora_peru.dart';
import 'package:enam_app/core/error/failure.dart';
import 'package:enam_app/core/network/api_client.dart';
import 'package:enam_app/core/providers.dart';
import 'package:enam_app/core/theme/app_theme.dart';
import 'package:enam_app/features/auth/domain/auth_models.dart';
import 'package:enam_app/features/consentimiento/data/consentimiento_repository.dart';
import 'package:enam_app/features/consentimiento/presentation/tarjeta_de_comerciales.dart';
import 'package:enam_app/features/subscription/domain/acceso.dart';
import 'package:enam_app/features/subscription/domain/subscription_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// El permiso de correos comerciales al terminar el día gratis (19/10/2026,
/// aprobado por Jerry; igual que la web).
///
/// Solo a quien no decidió, una sola vez, con dos respuestas del mismo peso y
/// sin nada premarcado. Va al servidor con `origenConsentimiento:
/// "fin_dia_gratis"`.
void main() {
  final ahora = DateTime.utc(2026, 10, 19, 17);
  setUp(() {
    congelarReloj(ahora);
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(soltarReloj);

  const sinDecidir = User(
    id: 'u1',
    email: 'a@b.pe',
    nombre: 'Ana',
    emailVerificado: true,
  );

  /// El día gratis de 24 h que terminó hace [hace].
  Subscription terminado({
    Duration hace = const Duration(hours: 2),
    SubscriptionStatus estado = SubscriptionStatus.expirada,
  }) {
    final fin = ahora.subtract(hace);
    return Subscription(
      id: 's1',
      plan: const Plan(
        id: 'trial',
        nombre: 'Día gratis',
        precioCentimos: 0,
        duracionDias: 1,
        esGratuito: true,
      ),
      estado: estado,
      origen: SubscriptionOrigin.sistema,
      inicia: fin.subtract(const Duration(hours: 24)),
      expira: fin,
      acceso: const AccesoGratis(preguntasPorDia: 20, restantesHoy: 20),
    );
  }

  group('A quién le toca', () {
    test('día gratis terminado y sin decidir: sí', () {
      expect(tocaPreguntarComerciales(sinDecidir, terminado(), ahora), isTrue);
    });

    test('recién vencido, aunque el estado siga en «prueba»', () {
      // La tarea horaria del servidor tarda hasta una hora en pasarlo a
      // «expirada»: manda la fecha.
      expect(
        tocaPreguntarComerciales(
          sinDecidir,
          terminado(
            hace: const Duration(minutes: 5),
            estado: SubscriptionStatus.prueba,
          ),
          ahora,
        ),
        isTrue,
      );
    });

    test('ya decidió, sí o no: nunca más', () {
      for (final decision in [true, false]) {
        expect(
          tocaPreguntarComerciales(
            sinDecidir.copyWith(aceptaComerciales: decision),
            terminado(),
            ahora,
          ),
          isFalse,
        );
      }
    });

    test('todavía en su día gratis: no', () {
      final enCurso = terminado().copyWith(
        estado: SubscriptionStatus.prueba,
        expira: ahora.add(const Duration(hours: 3)),
        acceso: const AccesoPremium(),
      );
      expect(tocaPreguntarComerciales(sinDecidir, enCurso, ahora), isFalse);
    });

    test('una cuenta que nunca tuvo día gratis (expira == inicia): no', () {
      final alta = DateTime.utc(2026, 10, 10, 12);
      final sinDia = terminado().copyWith(inicia: alta, expira: alta);
      expect(tocaPreguntarComerciales(sinDecidir, sinDia, ahora), isFalse);
    });

    test('con un plan pagado: no', () {
      final pagado = terminado().copyWith(
        plan: const Plan(
          id: 'mensual',
          nombre: 'Premium mensual',
          precioCentimos: 5900,
          duracionDias: 30,
        ),
        estado: SubscriptionStatus.activa,
        expira: ahora.add(const Duration(days: 20)),
        acceso: const AccesoPremium(),
      );
      expect(tocaPreguntarComerciales(sinDecidir, pagado, ahora), isFalse);
    });
  });

  test('PATCH /me con el origen «fin_dia_gratis»', () async {
    final cliente = _Cliente();
    final user = await ApiConsentimientoRepository(
      cliente,
    ).decidir(acepta: true, origen: OrigenConsentimiento.finDiaGratis);

    expect(cliente.ruta, '/me');
    expect(cliente.cuerpo, {
      'aceptaComerciales': true,
      'origenConsentimiento': 'fin_dia_gratis',
    });
    expect(user.aceptaComerciales, isTrue);
  });

  group('La tarjeta del inicio', () {
    late _Analitica analitica;

    Future<_Repo> montar(
      WidgetTester tester, {
      User user = sinDecidir,
      Subscription? sub,
      _Repo? repo,
    }) async {
      tester.view
        ..physicalSize = const Size(393, 852) * 3
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final r = repo ?? _Repo();
      analitica = _Analitica();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(() => _ConSesion(user)),
            subscriptionProvider.overrideWith((_) async => sub ?? terminado()),
            consentimientoRepositoryProvider.overrideWithValue(r),
            analiticaProvider.overrideWithValue(analitica),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(body: TarjetaDeComerciales()),
          ),
        ),
      );
      // Las preferencias se leen fuera del reloj falso.
      for (var i = 0; i < 3; i++) {
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await tester.pump();
      }
      return r;
    }

    testWidgets('dos respuestas del mismo tamaño, y «Sí» guarda el sí', (
      tester,
    ) async {
      final repo = await montar(tester);

      expect(find.text(tituloComerciales), findsOneWidget);
      expect(find.text(politicaComerciales), findsOneWidget);
      Size boton(String texto) => tester.getSize(
        find.ancestor(
          of: find.text(texto),
          matching: find.byType(OutlinedButton),
        ),
      );
      expect(boton(siComerciales), boton(noComerciales));
      // Nada premarcado: no hay casillas ni interruptores.
      expect(find.byType(Checkbox), findsNothing);
      expect(find.byType(Switch), findsNothing);

      await tester.tap(find.text(siComerciales));
      await tester.pump();
      await tester.pump();

      expect(repo.decisiones, [(true, OrigenConsentimiento.finDiaGratis)]);
      expect(find.text(tituloComerciales), findsNothing);
      // Sin anunciar descuentos.
      expect(find.text(listoComerciales), findsOneWidget);
      expect(analitica.eventos, [
        'consentimiento_visto lugar=fin_dia_gratis',
        'consentimiento_respuesta lugar=fin_dia_gratis respuesta=si',
      ]);
    });

    testWidgets('«No, gracias» guarda el no', (tester) async {
      final repo = await montar(tester);
      await tester.tap(find.text(noComerciales));
      await tester.pump();
      await tester.pump();

      expect(repo.decisiones, [(false, OrigenConsentimiento.finDiaGratis)]);
      expect(find.text(tituloComerciales), findsNothing);
      expect(find.text(listoComerciales), findsNothing);
      expect(
        analitica.eventos.last,
        'consentimiento_respuesta lugar=fin_dia_gratis respuesta=no',
      );
    });

    testWidgets('si falla, queda abierta con el error y se puede reintentar', (
      tester,
    ) async {
      final repo = await montar(tester, repo: _Repo(fallasAntes: 1));
      await tester.tap(find.text(siComerciales));
      await tester.pump();
      await tester.pump();

      expect(find.text(tituloComerciales), findsOneWidget);
      expect(find.textContaining('No pudimos guardar'), findsOneWidget);
      expect(repo.decisiones, isEmpty);

      await tester.tap(find.text(siComerciales));
      await tester.pump();
      await tester.pump();
      expect(repo.decisiones, [(true, OrigenConsentimiento.finDiaGratis)]);
      expect(find.text(tituloComerciales), findsNothing);
      // Una respuesta por aparición, aunque se haya reintentado.
      expect(
        analitica.eventos.where(
          (e) => e.startsWith('consentimiento_respuesta'),
        ),
        hasLength(1),
      );
    });

    testWidgets('cerrarla no decide nada', (tester) async {
      final repo = await montar(tester);
      await tester.tap(find.byTooltip('Cerrar'));
      await tester.pump();

      expect(find.text(tituloComerciales), findsNothing);
      expect(repo.decisiones, isEmpty);
      expect(
        analitica.eventos.last,
        'consentimiento_respuesta lugar=fin_dia_gratis respuesta=cerro',
      );
    });

    testWidgets('una sola vez: en la visita siguiente ya no sale', (
      tester,
    ) async {
      await montar(tester);
      expect(find.text(tituloComerciales), findsOneWidget);

      // Otra visita: la app se abre de nuevo, con lo guardado en el teléfono.
      await tester.pumpWidget(const SizedBox());
      await montar(tester);
      expect(find.text(tituloComerciales), findsNothing);
      expect(analitica.eventos, isEmpty);
    });

    testWidgets('ya decidió, o sigue en su día gratis: no sale', (
      tester,
    ) async {
      await montar(tester, user: sinDecidir.copyWith(aceptaComerciales: false));
      expect(find.text(tituloComerciales), findsNothing);

      await tester.pumpWidget(const SizedBox());
      SharedPreferences.setMockInitialValues({});
      await montar(
        tester,
        sub: terminado().copyWith(
          estado: SubscriptionStatus.prueba,
          expira: ahora.add(const Duration(hours: 3)),
          acceso: const AccesoPremium(),
        ),
      );
      expect(find.text(tituloComerciales), findsNothing);
    });
  });
}

class _Cliente implements ApiClient {
  String? ruta;
  Object? cuerpo;

  @override
  Future<T> patch<T>(String path, {Object? data, Object? cancelToken}) async {
    ruta = path;
    cuerpo = data;
    return {
          'id': 'u1',
          'email': 'a@b.pe',
          'nombre': 'Ana',
          'aceptaComerciales': true,
          'aceptaComercialesEn': '2026-10-19T17:00:00Z',
          'aceptaComercialesOrigen': 'fin_dia_gratis',
        }
        as T;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Repo implements ConsentimientoRepository {
  _Repo({this.fallasAntes = 0});

  int fallasAntes;
  final decisiones = <(bool, OrigenConsentimiento)>[];

  @override
  Future<User> decidir({
    required bool acepta,
    required OrigenConsentimiento origen,
  }) async {
    if (fallasAntes > 0) {
      fallasAntes--;
      throw const NetworkFailure();
    }
    decisiones.add((acepta, origen));
    return const User(
      id: 'u1',
      email: 'a@b.pe',
      nombre: 'Ana',
    ).copyWith(aceptaComerciales: acepta);
  }
}

class _ConSesion extends AuthController {
  _ConSesion(this.user);

  final User user;

  @override
  Future<AuthState> build() async => AuthSignedIn(user);
}

class _Analitica implements Analitica {
  /// «nombre clave=valor …», para comparar por contenido.
  final eventos = <String>[];

  @override
  void registrar(Evento evento, {Map<String, String> propiedades = const {}}) =>
      eventos.add(
        [
          evento.nombre,
          for (final MapEntry(:key, :value) in propiedades.entries)
            '$key=$value',
        ].join(' '),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
