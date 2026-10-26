import 'package:enam_app/core/config/app_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// El botón de Google no puede desaparecer por un parámetro que nadie sabe.
///
/// El client ID estuvo vacío por defecto, y el síntoma no se parecía a la
/// causa: al apagar los mocks para probar contra el servidor, el botón **se
/// iba**. Nadie relaciona «quité los datos falsos» con «se fue un botón», así
/// que se perdían tardes en un `--dart-define` que solo tenía quien hizo la
/// última build.
void main() {
  test('el client ID viene puesto por defecto', () {
    expect(AppConfig.googleServerClientId, isNotEmpty);
  });

  test('es el client ID WEB, no el de iOS ni el de Android', () {
    // El de tipo web es el que hace que el `idToken` lleve el `aud` que el
    // backend sabe verificar. Con el de iOS —el que está en Info.plist— o el de
    // Android, el token no le sirve al servidor.
    expect(
      AppConfig.googleServerClientId,
      endsWith('.apps.googleusercontent.com'),
    );
    expect(
      AppConfig.googleServerClientId,
      startsWith('776242647673-'),
      reason: 'tiene que ser del proyecto enam-prep-ff260',
    );
    expect(
      AppConfig.googleServerClientId,
      isNot(contains('sknu20f23ircn9h50qssen6p7nh1mhk5')),
      reason: 'ese es el de iOS, el que vive en Info.plist',
    );
  });

  group('por plataforma', () {
    test('Android usa el client ID web del proyecto enam-play', () {
      // En el proyecto viejo faltaba la huella SHA-1 de Google Play y nadie
      // puede entrar a agregarla; los clientes Android están en enam-play.
      final id = AppConfig.googleServerClientIdPara(TargetPlatform.android);
      expect(id, AppConfig.googleServerClientIdAndroid);
      expect(id, startsWith('253395866936-'));
      expect(id, endsWith('.apps.googleusercontent.com'));
    });

    test('iOS sigue con el del proyecto viejo, donde vive su cliente iOS', () {
      expect(
        AppConfig.googleServerClientIdPara(TargetPlatform.iOS),
        AppConfig.googleServerClientId,
      );
      expect(
        AppConfig.googleServerClientIdPara(TargetPlatform.iOS),
        startsWith('776242647673-'),
      );
    });
  });

  test('el botón se ofrece sin pasar ningún define', () {
    // Que `flutter run` a secas lo enseñe es el objetivo de todo esto.
    expect(AppConfig.googleSignInHabilitado, isTrue);
  });
}
