import 'package:enam_app/core/analitica/analitica.dart';
import 'package:enam_app/core/error/failure.dart';
import 'package:enam_app/core/network/api_client.dart';
import 'package:enam_app/core/providers.dart';
import 'package:enam_app/core/storage/token_storage.dart';
import 'package:enam_app/features/auth/data/auth_repository.dart';
import 'package:enam_app/features/auth/data/mock_auth_repository.dart';
import 'package:enam_app/features/auth/presentation/register_screen.dart';
import 'package:enam_app/features/consentimiento/presentation/casilla_de_comerciales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// La casilla de correos comerciales del alta (Ley 29733). El servidor la
/// aceptaba desde el 10/10 en correo, Google y Apple, y la app nunca la mandó:
/// en Android solo el 2 % de las cuentas lo había aceptado, frente al 12 % de
/// la web.
void main() {
  group('lo que viaja al servidor', () {
    late _Cliente cliente;
    late ApiAuthRepository repo;

    setUp(() {
      cliente = _Cliente();
      repo = ApiAuthRepository(
        client: cliente,
        tokens: _Tokens(),
        anonimoId: () async => 'anonimo',
      );
    });

    test('registro por correo, marcada y sin marcar', () async {
      for (final acepta in [true, false]) {
        await repo.register(
          email: 'a@b.pe',
          password: 'una-clave-larga',
          nombre: 'Ana',
          aceptaTerminos: true,
          aceptaComerciales: acepta,
        );
        expect(cliente.cuerpo['aceptaComerciales'], acepta);
      }
    });

    test('alta con Google y con Apple', () async {
      try {
        await repo.loginConGoogle(
          'id-token',
          aceptaTerminos: true,
          aceptaComerciales: true,
        );
      } catch (_) {}
      expect(cliente.cuerpo['aceptaComerciales'], isTrue);

      try {
        await repo.loginConApple(
          identityToken: 'jwt',
          aceptaTerminos: true,
          aceptaComerciales: false,
        );
      } catch (_) {}
      expect(cliente.cuerpo['aceptaComerciales'], isFalse);
    });

    test('sin decidir, el campo no va (la cuenta queda sin decidir)', () async {
      await repo.register(
        email: 'a@b.pe',
        password: 'una-clave-larga',
        nombre: 'Ana',
        aceptaTerminos: true,
      );
      expect(cliente.cuerpo.containsKey('aceptaComerciales'), isFalse);
    });
  });

  group('la pantalla de registro', () {
    late _Registro auth;

    Future<void> montar(WidgetTester tester) async {
      auth = _Registro();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(auth),
            analiticaProvider.overrideWithValue(_Analitica()),
          ],
          child: const MaterialApp(home: RegisterScreen()),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> llenarYEnviar(WidgetTester tester) async {
      final campos = find.byType(TextField);
      await tester.enterText(campos.at(0), 'Ana');
      await tester.enterText(campos.at(1), 'ana@unsa.pe');
      await tester.enterText(campos.at(2), 'UnaClaveLarga123');
      // La de los términos es la primera casilla.
      await tester.tap(find.byType(Checkbox).first);
      await tester.pump();
      await tester.ensureVisible(find.text('Crear cuenta'));
      await tester.tap(find.text('Crear cuenta'));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'arranca desmarcada, y sin marcarla la cuenta queda sin decidir',
      (tester) async {
        await montar(tester);

        expect(find.text(textoCasillaComerciales), findsOneWidget);
        final casilla = tester.widget<Checkbox>(
          find.descendant(
            of: find.byType(CasillaDeComerciales),
            matching: find.byType(Checkbox),
          ),
        );
        expect(casilla.value, isFalse);

        await llenarYEnviar(tester);
        // Ni «no»: sin el campo. Así le sigue saliendo la pregunta del fin del
        // día gratis.
        expect(auth.comerciales, [null]);
      },
    );

    testWidgets('tocar el texto la marca, y viaja marcada', (tester) async {
      await montar(tester);

      await tester.tap(find.text(textoCasillaComerciales));
      await tester.pump();
      await llenarYEnviar(tester);

      expect(auth.comerciales, [true]);
    });
  });

  test('sin marcar no se manda nada: la cuenta queda sin decidir', () {
    // Vale para el correo, Google y Apple: las tres altas pasan por aquí.
    expect(comercialesDelAlta(false), isNull);
    expect(comercialesDelAlta(true), isTrue);
  });

  test('el texto no habla de la web, de pagos ni de descuentos', () {
    // Política de pagos de Google Play: nada en la app que lleve a pagar
    // fuera de la tienda.
    final texto = textoCasillaComerciales.toLowerCase();
    for (final p in ['web', 'pag', 'descuento', 'precio', 'enamprep.com']) {
      expect(texto, isNot(contains(p)), reason: p);
    }
  });
}

/// Anota lo que llega y falla como un correo ya registrado, para que la
/// pantalla se quede donde está (sin navegación que montar).
class _Registro extends MockAuthRepository {
  final comerciales = <bool?>[];

  @override
  Future<void> register({
    required String email,
    required String password,
    required String nombre,
    required bool aceptaTerminos,
    bool? aceptaComerciales,
  }) async {
    comerciales.add(aceptaComerciales);
    throw const ValidationFailure(
      'Ese correo ya está registrado.',
      code: 'EMAIL_TAKEN',
      fieldErrors: {'email': 'Ese correo ya está registrado.'},
    );
  }
}

class _Analitica implements Analitica {
  @override
  void registrar(Evento evento, {Map<String, String> propiedades = const {}}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Cliente implements ApiClient {
  Map<String, dynamic> cuerpo = {};

  @override
  Future<T> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Object? cancelToken,
  }) async {
    cuerpo = Map<String, dynamic>.from(data! as Map);
    return <String, dynamic>{} as T;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Tokens extends TokenStorage {}
