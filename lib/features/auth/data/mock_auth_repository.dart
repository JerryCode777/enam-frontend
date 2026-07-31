import '../../../core/error/failure.dart';
import '../domain/auth_models.dart';
import 'auth_repository.dart';

/// Autenticación falsa, para desarrollar sin backend.
///
/// Reglas para probar los caminos de error sin tocar código:
/// - `nuevo@enam.pe` → login falla con credenciales inválidas
/// - contraseña `error` → falla con credenciales inválidas
/// - correo `sinverificar@enam.pe` → usuario con el correo sin verificar
/// - correo `nuevo2@enam.pe` → usuario con el perfil incompleto (RF-04)
/// - cualquier otro correo con contraseña válida → entra como usuario completo
///
/// El **estado de la suscripción** también se elige por correo, pero vive en
/// `mockEstadosPorCorreo` (`core/providers.dart`): el plan no es dato del
/// usuario, lo decide el backend por suscripción.
class MockAuthRepository implements AuthRepository {
  User? _current;

  /// Latencia simulada, para que los estados de carga se vean de verdad.
  static const _delay = Duration(milliseconds: 600);

  @override
  Future<void> register({
    required String email,
    required String password,
    required String nombre,
    required bool aceptaTerminos,
  }) async {
    await Future<void>.delayed(_delay);
    if (email == 'existente@enam.pe') {
      throw const ValidationFailure(
        'Ese correo ya está registrado.',
        code: 'EMAIL_TAKEN',
        fieldErrors: {'email': 'Ese correo ya está registrado.'},
      );
    }
    // El mock rechaza igual que el servidor. Un mock permisivo aquí dejaría el
    // camino sin probar justo hasta producción, que es como se llegó a tener
    // una app incapaz de registrar a nadie contra el backend real.
    if (!aceptaTerminos) {
      throw const ValidationFailure(
        'Necesitas aceptar los términos y la política de privacidad '
        'para crear tu cuenta.',
        code: 'CONSENT_REQUIRED',
        fieldErrors: {
          'aceptaTerminos': 'Necesitas aceptar los términos para continuar.',
        },
      );
    }
    _current = User(
      id: 'mock-user',
      email: email,
      nombre: nombre,
      emailVerificado: false,
    );
  }

  @override
  Future<User> login({required String email, required String password}) async {
    await Future<void>.delayed(_delay);

    if (email == 'nuevo@enam.pe' || password == 'error') {
      throw const UnauthorizedFailure(
        'Correo o contraseña incorrectos.',
        'INVALID_CREDENTIALS',
      );
    }

    return _current = User(
      id: 'mock-user',
      email: email,
      nombre: 'Estudiante de prueba',
      emailVerificado: email != 'sinverificar@enam.pe',
      universidad: email == 'nuevo2@enam.pe' ? null : 'UNSA',
      condicion: email == 'nuevo2@enam.pe' ? null : StudentCondition.interno,
      fechaObjetivo: email == 'nuevo2@enam.pe'
          ? null
          : DateTime.now().add(const Duration(days: 96)),
    );
  }

  @override
  Future<User> loginConGoogle(String idToken, {bool aceptaTerminos = false}) async {
    await Future<void>.delayed(_delay);

    // Cuenta nueva sin consentimiento: el servidor real responde lo mismo, y
    // es lo que hace que la app enseñe los términos y reintente.
    if (!aceptaTerminos) {
      throw const ValidationFailure(
        'Necesitas aceptar los términos y la política de privacidad '
        'para crear tu cuenta.',
        code: 'CONSENT_REQUIRED',
      );
    }

    // Cuenta de Google recién creada: entra sin perfil, así se puede recorrer
    // el flujo de completar perfil (RF-04) que es el caso real más común.
    return _current = const User(
      id: 'mock-user-google',
      email: 'estudiante@gmail.com',
      nombre: 'Estudiante Google',
      // Google ya verificó el correo, así que no se vuelve a pedir.
      emailVerificado: true,
    );
  }

  @override
  Future<User> loginConApple({
    required String identityToken,
    String? nombre,
    bool aceptaTerminos = false,
  }) async {
    await Future<void>.delayed(_delay);

    if (!aceptaTerminos) {
      throw const ValidationFailure(
        'Necesitas aceptar los términos y la política de privacidad '
        'para crear tu cuenta.',
        code: 'CONSENT_REQUIRED',
      );
    }

    return _current = User(
      id: 'mock-user-apple',
      // Apple deja ocultar el correo real y da uno de reenvío. El backend no
      // debe tratarlo distinto, pero conviene verlo en desarrollo.
      email: 'abc123@privaterelay.appleid.com',
      nombre: nombre ?? 'Estudiante Apple',
      emailVerificado: true,
    );
  }

  @override
  Future<void> logout() async {
    await Future<void>.delayed(_delay);
    _current = null;
  }

  @override
  Future<User?> currentUser() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _current;
  }

  @override
  Future<void> forgotPassword(String email) =>
      Future<void>.delayed(_delay);

  @override
  Future<void> reenviarVerificacion(String email) => Future<void>.delayed(_delay);

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) => Future<void>.delayed(_delay);

  @override
  Future<User> updateProfile({
    String? nombre,
    String? universidad,
    StudentCondition? condicion,
    DateTime? fechaObjetivo,
    bool? ocultoEnRanking,
  }) async {
    await Future<void>.delayed(_delay);
    final user = _current;
    if (user == null) {
      throw const UnauthorizedFailure();
    }
    return _current = user.copyWith(
      nombre: nombre ?? user.nombre,
      universidad: universidad ?? user.universidad,
      condicion: condicion ?? user.condicion,
      fechaObjetivo: fechaObjetivo ?? user.fechaObjetivo,
      ocultoEnRanking: ocultoEnRanking ?? user.ocultoEnRanking,
    );
  }
}
