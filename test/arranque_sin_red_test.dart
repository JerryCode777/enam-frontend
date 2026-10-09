import 'package:enam_app/core/error/failure.dart';
import 'package:enam_app/core/network/api_client.dart';
import 'package:enam_app/core/storage/token_storage.dart';
import 'package:enam_app/features/auth/data/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Abrir la app sin señal, con la sesión iniciada.
///
/// Arrancar pide `GET /me`. Sin red esa petición fallaba, el estado de sesión
/// quedaba en error y el router no salía nunca del splash: justo quien había
/// descargado áreas para estudiar en el metro no podía entrar a usarlas.
///
/// Ahora el repositorio recuerda el último perfil que vio y entra con él
/// cuando **no se pudo preguntar**. Si el servidor sí responde, manda él.
void main() {
  late _TokensEnMemoria tokens;
  late _ClienteFalso cliente;
  late ApiAuthRepository repo;

  setUp(() {
    tokens = _TokensEnMemoria();
    cliente = _ClienteFalso();
    repo = ApiAuthRepository(client: cliente, tokens: tokens);
  });

  const perfil = {
    'id': 'u1',
    'email': 'valeria@unmsm.edu.pe',
    'nombre': 'Valeria',
    'emailVerificado': true,
    'universidad': 'UNMSM',
    'condicion': 'interno',
    'fechaObjetivo': '2026-12-12T00:00:00.000Z',
  };

  test('con red, el perfil se recuerda para la próxima vez', () async {
    cliente.respuesta = perfil;
    final user = await repo.currentUser();

    expect(user?.id, 'u1');
    expect(tokens.usuario, isNotNull);
  });

  test('sin red, entra con el último perfil conocido', () async {
    cliente.respuesta = perfil;
    await repo.currentUser();

    cliente.fallo = const NetworkFailure();
    final user = await repo.currentUser();

    expect(user?.id, 'u1');
    expect(user?.email, 'valeria@unmsm.edu.pe');
  });

  test('con el servidor tardando demasiado, también', () async {
    cliente.respuesta = perfil;
    await repo.currentUser();

    cliente.fallo = const TimeoutFailure();
    expect((await repo.currentUser())?.id, 'u1');
  });

  test('sin red y sin perfil guardado, el fallo sube tal cual', () async {
    cliente.fallo = const NetworkFailure();
    // El splash lo recoge y ofrece reintentar; no hay con qué entrar.
    expect(repo.currentUser, throwsA(isA<NetworkFailure>()));
  });

  test('si el servidor dice que la sesión no vale, eso manda', () async {
    cliente.respuesta = perfil;
    await repo.currentUser();

    // Un 401 no es «no se pudo preguntar»: se preguntó y la respuesta fue no.
    cliente.fallo = const UnauthorizedFailure();
    expect(await repo.currentUser(), isNull);
    expect(tokens.usuario, isNull, reason: 'el perfil se va con la sesión');
  });

  test('cerrar sesión borra también el perfil guardado', () async {
    cliente.respuesta = perfil;
    await repo.currentUser();

    await repo.logout();
    expect(tokens.usuario, isNull);
  });
}

class _TokensEnMemoria extends TokenStorage {
  String? usuario;
  bool sesion = true;

  @override
  Future<bool> hasSession() async => sesion;

  @override
  Future<void> guardarUsuario(String json) async => usuario = json;

  @override
  Future<String?> leerUsuario() async => usuario;

  @override
  Future<void> clear() async {
    sesion = false;
    usuario = null;
  }
}

class _ClienteFalso implements ApiClient {
  Map<String, dynamic>? respuesta;
  Failure? fallo;

  @override
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Object? cancelToken,
    Object? onReceiveProgress,
  }) async {
    if (fallo case final f?) throw f;
    return respuesta as T;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
