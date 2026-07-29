import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Almacenamiento de tokens de sesión.
///
/// Usa `flutter_secure_storage`, que en Android respalda con **EncryptedSharedPreferences
/// / Keystore**. NO uses `shared_preferences` para esto: ahí los valores quedan
/// en un XML en texto plano, legible en un dispositivo con root. Esa es la
/// deficiencia que arrastra la app hermana y que aquí no repetimos.
///
/// El access token además se cachea en memoria para no pagar una lectura del
/// Keystore en cada petición HTTP.
class TokenStorage {
  // En flutter_secure_storage 10 el cifrado en Android ya es el comportamiento
  // por defecto (Jetpack Security quedó obsoleto y migra a cifrados propios),
  // así que no hace falta pasar opciones para obtener respaldo en Keystore.
  TokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'enam.access_token';
  static const _refreshTokenKey = 'enam.refresh_token';
  static const _expiresAtKey = 'enam.expires_at';

  String? _cachedAccessToken;
  DateTime? _cachedExpiresAt;

  /// Guarda la sesión completa tras un login o un refresh.
  Future<void> save({
    required String accessToken,
    required String refreshToken,
    required DateTime expiresAt,
  }) async {
    _cachedAccessToken = accessToken;
    _cachedExpiresAt = expiresAt;

    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
      _storage.write(key: _expiresAtKey, value: expiresAt.toIso8601String()),
    ]);
  }

  /// Reemplaza solo el access token, tras renovarlo.
  Future<void> updateAccessToken({
    required String accessToken,
    required DateTime expiresAt,
  }) async {
    _cachedAccessToken = accessToken;
    _cachedExpiresAt = expiresAt;

    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _expiresAtKey, value: expiresAt.toIso8601String()),
    ]);
  }

  Future<String?> readAccessToken() async {
    return _cachedAccessToken ??= await _storage.read(key: _accessTokenKey);
  }

  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<DateTime?> readExpiresAt() async {
    if (_cachedExpiresAt != null) return _cachedExpiresAt;
    final raw = await _storage.read(key: _expiresAtKey);
    if (raw == null) return null;
    return _cachedExpiresAt = DateTime.tryParse(raw);
  }

  /// Si el access token caducó o está por caducar.
  ///
  /// El margen evita mandar una petición con un token que expira en el camino.
  Future<bool> isExpired({
    Duration margin = const Duration(seconds: 30),
  }) async {
    final expiresAt = await readExpiresAt();
    if (expiresAt == null) return true;
    return DateTime.now().add(margin).isAfter(expiresAt);
  }

  Future<bool> hasSession() async =>
      (await readRefreshToken())?.isNotEmpty ?? false;

  /// Borra todo. Se llama en logout y cuando el refresh token ya no sirve.
  Future<void> clear() async {
    _cachedAccessToken = null;
    _cachedExpiresAt = null;
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _expiresAtKey),
    ]);
  }
}
