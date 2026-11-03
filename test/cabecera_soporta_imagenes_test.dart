import 'package:enam_app/core/network/api_client.dart';
import 'package:enam_app/core/storage/token_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// `X-Soporta-Imagenes: 1`: sin ella, el servidor esconde las preguntas con
/// imagen (las apps hasta la 1.1.10 solo pintaban un ícono).
void main() {
  test('toda petición dice que la app muestra imágenes', () {
    FlutterSecureStorage.setMockInitialValues({});
    final client = ApiClient(
      tokenStorage: TokenStorage(),
      onSessionExpired: () {},
    );
    final cabeceras = client.raw.options.headers;
    expect(cabeceras['X-Soporta-Imagenes'], '1');
    expect(cabeceras['X-Plataforma'], isNotNull);
  });
}
