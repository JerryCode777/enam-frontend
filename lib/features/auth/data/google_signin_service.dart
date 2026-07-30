import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/config/app_config.dart';
import '../../../core/error/failure.dart';

/// Obtiene del dispositivo el `idToken` de Google del usuario.
///
/// Está separado del repositorio a propósito: esto habla con el SDK nativo y
/// solo devuelve un token; quién lo canjea por una sesión es [AuthRepository].
/// Así el mock puede simular la parte del dispositivo sin necesitar un proyecto
/// de Google Cloud configurado.
abstract interface class GoogleSignInService {
  /// Devuelve el `idToken`, o `null` si el usuario canceló el diálogo.
  ///
  /// Cancelar no es un error: es una decisión del usuario y la pantalla no
  /// debe mostrarle nada rojo por ello.
  Future<String?> obtenerIdToken();

  /// Olvida la cuenta elegida, para que el próximo login vuelva a preguntar.
  Future<void> cerrarSesion();
}

class GoogleSignInServiceImpl implements GoogleSignInService {
  bool _inicializado = false;

  Future<void> _inicializar() async {
    if (_inicializado) return;
    await GoogleSignIn.instance.initialize(
      serverClientId: AppConfig.googleServerClientId,
    );
    _inicializado = true;
  }

  @override
  Future<String?> obtenerIdToken() async {
    await _inicializar();

    // En web y en algunos escritorios no existe el flujo de un solo paso; ahí
    // hay que usar el botón que renderiza el propio SDK. La app es solo
    // Android, pero si eso cambia conviene enterarse con un mensaje claro y no
    // con un fallo del plugin.
    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw const UnknownFailure(
        'El inicio de sesión con Google no está disponible en esta plataforma.',
      );
    }

    try {
      final cuenta = await GoogleSignIn.instance.authenticate();
      final idToken = cuenta.authentication.idToken;
      if (idToken == null) {
        // Pasa cuando falta el serverClientId o la huella SHA-1 no coincide con
        // la registrada en Google Cloud. El SDK no lo reporta como error.
        throw const UnknownFailure(
          'Google no devolvió un token válido. Revisa la configuración de la '
          'app en Google Cloud.',
        );
      }
      return idToken;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      throw UnknownFailure('No se pudo continuar con Google.', e.description);
    }
  }

  @override
  Future<void> cerrarSesion() async {
    if (!_inicializado) return;
    await GoogleSignIn.instance.signOut();
  }
}

/// Simula el lado del dispositivo: devuelve un token falso tras una espera.
class MockGoogleSignInService implements GoogleSignInService {
  @override
  Future<String?> obtenerIdToken() async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    return 'mock-google-id-token';
  }

  @override
  Future<void> cerrarSesion() async {}
}
