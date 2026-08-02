import 'package:dio/dio.dart';
import 'package:enam_app/core/config/api_endpoints.dart';
import 'package:enam_app/core/network/auth_interceptor.dart';
import 'package:enam_app/core/storage/token_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// Las rutas por las que se ENTRA no pueden exigir estar dentro.
///
/// El interceptor renueva el token de forma proactiva antes de cada petición.
/// Para una ruta de login eso es al revés de lo que hace falta: sin sesión
/// —instalación nueva, o la anterior ya vencida— no hay token que renovar, y la
/// petición se rechazaba con un 401 fabricado **sin llegar a salir del
/// teléfono**. El usuario elegía su cuenta de Google, volvía a la app y veía
/// «Tu sesión expiró»; el servidor nunca supo del intento.
///
/// `/auth/login` y `/auth/register` sí estaban exentas desde el principio. Las
/// de Google y Apple se añadieron después y nadie las agregó a la lista, así
/// que entrar con cualquiera de las dos era imposible.
void main() {
  late AuthInterceptor interceptor;

  setUp(() {
    // Almacén de una instalación recién puesta: sin access ni refresh token.
    FlutterSecureStorage.setMockInitialValues({});
    interceptor = AuthInterceptor(
      tokenStorage: TokenStorage(),
      refreshClient: Dio(),
      onSessionExpired: () {},
    );
  });

  /// Pasa la petición por el interceptor y dice si la dejó salir.
  Future<bool> dejaSalir(String ruta) async {
    final opciones = RequestOptions(path: ruta);
    var salio = false;
    final manejador = _Handler(alContinuar: () => salio = true);

    await interceptor.onRequest(opciones, manejador);
    return salio;
  }

  for (final ruta in [
    ApiEndpoints.login,
    ApiEndpoints.register,
    ApiEndpoints.google,
    ApiEndpoints.apple,
    ApiEndpoints.refresh,
    ApiEndpoints.forgotPassword,
    ApiEndpoints.resetPassword,
  ]) {
    test('sin sesión, $ruta sale igual', () async {
      expect(
        await dejaSalir(ruta),
        isTrue,
        reason: 'es una ruta de entrada: exigir sesión la vuelve inalcanzable',
      );
    });
  }

  test('sin sesión, una ruta privada sí se corta', () async {
    // El contraste importa: si el interceptor dejara pasar todo, los tests de
    // arriba pasarían sin comprobar nada.
    expect(await dejaSalir(ApiEndpoints.me), isFalse);
  });
}

class _Handler extends RequestInterceptorHandler {
  _Handler({required this.alContinuar});

  final void Function() alContinuar;

  @override
  void next(RequestOptions options) => alContinuar();

  @override
  void reject(DioException error, [bool callFollowingErrorInterceptor = false]) {}
}
