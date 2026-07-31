import 'dart:io';

import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/error/failure.dart';

/// Obtiene del dispositivo el `identityToken` de Apple.
///
/// Mismo reparto que con Google: esto habla con el SDK nativo y solo devuelve
/// un token; quién lo canjea por una sesión es [AuthRepository].
abstract interface class AppleSignInService {
  /// Si el dispositivo puede ofrecerlo.
  ///
  /// En Android existe un flujo web, pero pide un Service ID y una URL de
  /// retorno propias, y nadie con un Android espera entrar con Apple. Se
  /// ofrece solo donde es natural y donde App Store lo exige.
  Future<bool> disponible();

  /// Devuelve el `identityToken`, o `null` si el usuario canceló.
  Future<AppleCredential?> obtenerCredencial();
}

/// Lo que Apple devuelve y el backend necesita.
///
/// [nombre] llega **solo la primera vez** que este usuario autoriza la app. Si
/// no se guarda en ese momento, no hay forma de volver a pedirlo: Apple no lo
/// reenvía nunca más.
typedef AppleCredential = ({String identityToken, String? nombre});

class AppleSignInServiceImpl implements AppleSignInService {
  @override
  Future<bool> disponible() async {
    if (!Platform.isIOS) return false;
    return SignInWithApple.isAvailable();
  }

  @override
  Future<AppleCredential?> obtenerCredencial() async {
    try {
      final credencial = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final token = credencial.identityToken;
      if (token == null) {
        throw const UnknownFailure(
          'Apple no devolvió un token válido. Revisa la configuración de la '
          'app en el portal de Apple Developer.',
        );
      }

      final nombre = [
        ?credencial.givenName,
        ?credencial.familyName,
      ].join(' ').trim();

      return (identityToken: token, nombre: nombre.isEmpty ? null : nombre);
    } on SignInWithAppleAuthorizationException catch (e) {
      // Cancelar no es un error: es una decisión del usuario y la pantalla no
      // debe mostrarle nada rojo por ello.
      if (e.code == AuthorizationErrorCode.canceled) return null;
      throw UnknownFailure('No se pudo continuar con Apple.', e.message);
    }
  }
}

/// Simula el lado del dispositivo, para desarrollar sin cuenta de Apple.
class MockAppleSignInService implements AppleSignInService {
  @override
  Future<bool> disponible() async => true;

  @override
  Future<AppleCredential?> obtenerCredencial() async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    return (
      identityToken: 'mock-apple-identity-token',
      nombre: 'Estudiante Apple',
    );
  }
}
