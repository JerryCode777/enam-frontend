import '../../../core/config/api_endpoints.dart';
import '../../../core/error/failure.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/auth_models.dart';

/// Contrato de autenticación (Módulo 1 del SSD).
///
/// La UI depende de esta interfaz, nunca de una implementación concreta. Así el
/// front avanza contra [MockAuthRepository] mientras el backend no existe, y el
/// día que exista solo cambia qué implementación se inyecta.
abstract interface class AuthRepository {
  /// RF-01. Tras registrarse, el correo llega con un **enlace** de verificación.
  Future<void> register({
    required String email,
    required String password,
    required String nombre,
  });

  /// RF-02. Guarda los tokens y devuelve el usuario.
  Future<User> login({required String email, required String password});

  /// Canjea el `idToken` de Google por una sesión propia.
  ///
  /// El token de Google **no** se guarda ni se usa como credencial: solo sirve
  /// para que el backend verifique la identidad una vez y emita sus propios
  /// tokens. A partir de ahí la sesión es idéntica a la de correo y contraseña.
  ///
  /// Si el correo ya existía registrado con contraseña, el backend vincula la
  /// cuenta en vez de crear una nueva.
  Future<User> loginConGoogle(String idToken);

  /// Canjea el `identityToken` de Apple por una sesión propia.
  ///
  /// [nombre] solo viaja la primera vez que el usuario autoriza la app: Apple
  /// no lo reenvía después. Si el backend no lo guarda en ese momento, se
  /// pierde para siempre.
  Future<User> loginConApple({required String identityToken, String? nombre});

  Future<void> logout();

  /// El usuario de la sesión guardada, o `null` si no hay sesión válida.
  Future<User?> currentUser();

  /// RF-03.
  Future<void> forgotPassword(String email);

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  });

  /// RF-04. Completa o actualiza el perfil.
  Future<User> updateProfile({
    String? nombre,
    String? universidad,
    StudentCondition? condicion,
    DateTime? fechaObjetivo,
    bool? ocultoEnRanking,
  });
}

/// Implementación real contra la API.
class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository({required ApiClient client, required TokenStorage tokens})
    : _client = client,
      _tokens = tokens;

  final ApiClient _client;
  final TokenStorage _tokens;

  @override
  Future<void> register({
    required String email,
    required String password,
    required String nombre,
  }) async {
    await _client.post<Map<String, dynamic>>(
      ApiEndpoints.register,
      data: {'email': email, 'password': password, 'nombre': nombre},
    );
  }

  @override
  Future<User> login({required String email, required String password}) async {
    final data = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
    );

    final session = AuthSession.fromJson(data);
    await _tokens.save(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      expiresAt: session.expiresAt,
    );
    return session.user;
  }

  @override
  Future<User> loginConGoogle(String idToken) async {
    final data = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.google,
      data: {'idToken': idToken},
    );

    final session = AuthSession.fromJson(data);
    await _tokens.save(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      expiresAt: session.expiresAt,
    );
    return session.user;
  }

  @override
  Future<User> loginConApple({
    required String identityToken,
    String? nombre,
  }) async {
    final data = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.apple,
      data: {'identityToken': identityToken, 'nombre': ?nombre},
    );

    final session = AuthSession.fromJson(data);
    await _tokens.save(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      expiresAt: session.expiresAt,
    );
    return session.user;
  }

  @override
  Future<void> logout() => _tokens.clear();

  @override
  Future<User?> currentUser() async {
    if (!await _tokens.hasSession()) return null;
    try {
      final data = await _client.get<Map<String, dynamic>>(ApiEndpoints.me);
      return User.fromJson(data);
    } on UnauthorizedFailure {
      await _tokens.clear();
      return null;
    }
  }

  @override
  Future<void> forgotPassword(String email) async {
    await _client.post<Map<String, dynamic>>(
      ApiEndpoints.forgotPassword,
      data: {'email': email},
    );
  }

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _client.post<Map<String, dynamic>>(
      ApiEndpoints.resetPassword,
      data: {'token': token, 'password': newPassword},
    );
  }

  @override
  Future<User> updateProfile({
    String? nombre,
    String? universidad,
    StudentCondition? condicion,
    DateTime? fechaObjetivo,
    bool? ocultoEnRanking,
  }) async {
    final data = await _client.patch<Map<String, dynamic>>(
      ApiEndpoints.me,
      // Solo se mandan los campos presentes: es un PATCH, no un PUT, así que
      // omitir un campo lo deja intacto en el servidor.
      data: {
        'nombre': ?nombre,
        'universidad': ?universidad,
        'condicion': ?condicion?.name,
        'fechaObjetivo': ?fechaObjetivo?.toIso8601String(),
        'ocultoEnRanking': ?ocultoEnRanking,
      },
    );
    return User.fromJson(data);
  }
}
