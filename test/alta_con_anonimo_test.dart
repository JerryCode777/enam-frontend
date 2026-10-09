import 'package:enam_app/core/network/api_client.dart';
import 'package:enam_app/core/storage/token_storage.dart';
import 'package:enam_app/features/auth/data/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Las altas llevan el `anonimo_id` del dispositivo (contrato de eventos): así
/// el servidor une la visita anónima con la cuenta en `account_created`.
void main() {
  const anonimo = '3f0c9a1e-6b2d-4e8f-9a51-2c7d8e4b1f60';

  late _Cliente cliente;
  late ApiAuthRepository repo;

  setUp(() {
    cliente = _Cliente();
    repo = ApiAuthRepository(
      client: cliente,
      tokens: _Tokens(),
      anonimoId: () async => anonimo,
    );
  });

  test('registro por correo', () async {
    await repo.register(
      email: 'a@b.pe',
      password: 'una-clave-larga',
      nombre: 'Ana',
      aceptaTerminos: true,
    );
    expect(cliente.cuerpo['anonimoId'], anonimo);
  });

  test('alta con Google', () async {
    try {
      await repo.loginConGoogle('id-token', aceptaTerminos: true);
    } catch (_) {}
    expect(cliente.cuerpo['anonimoId'], anonimo);
  });

  test('alta con Apple', () async {
    try {
      await repo.loginConApple(identityToken: 'jwt', aceptaTerminos: true);
    } catch (_) {}
    expect(cliente.cuerpo['anonimoId'], anonimo);
  });

  test('sin identidad disponible, el alta sale igual, sin el campo', () async {
    final sin = ApiAuthRepository(
      client: cliente,
      tokens: _Tokens(),
      anonimoId: () async => throw StateError('sin almacenamiento'),
    );
    await sin.register(
      email: 'a@b.pe',
      password: 'una-clave-larga',
      nombre: 'Ana',
      aceptaTerminos: true,
    );
    expect(cliente.cuerpo.containsKey('anonimoId'), isFalse);
  });
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
    // El registro no mira la respuesta; Google y Apple esperan una sesión que
    // aquí no hace falta: la prueba solo mira lo que se mandó.
    return <String, dynamic>{} as T;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Tokens extends TokenStorage {}
