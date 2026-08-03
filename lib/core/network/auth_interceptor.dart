import 'dart:async';

import 'package:dio/dio.dart';

import '../config/api_endpoints.dart';
import '../storage/token_storage.dart';

/// Adjunta el access token a cada petición y lo renueva cuando caduca.
///
/// Puntos de diseño:
///
/// 1. **Un solo refresh a la vez.** Si cinco peticiones fallan con 401 al mismo
///    tiempo, solo una llama a `/auth/refresh`; las otras esperan ese mismo
///    Future. Sin esto, se dispararían cinco refresh en paralelo y el backend
///    (que rota el refresh token) invalidaría los tokens de las demás.
///
/// 2. **Cliente aparte para el refresh.** La llamada a `/auth/refresh` usa un
///    Dio sin este interceptor. Si usara el mismo, un 401 del propio refresh
///    dispararía otro refresh: recursión infinita.
///
/// 3. **Cierre de sesión limpio.** Si el refresh falla, se borran los tokens y
///    se avisa por [onSessionExpired] para que el router mande al login.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required TokenStorage tokenStorage,
    required Dio refreshClient,
    required this.onSessionExpired,
  }) : _tokens = tokenStorage,
       _refreshClient = refreshClient;

  final TokenStorage _tokens;

  /// Dio sin este interceptor, para no recursar al renovar el token.
  final Dio _refreshClient;

  /// Se dispara cuando la sesión ya no se puede recuperar.
  final void Function() onSessionExpired;

  /// El refresh en vuelo, si hay uno. Las peticiones concurrentes lo comparten.
  Future<String?>? _inFlightRefresh;

  /// Rutas por las que se ENTRA. Ninguna puede exigir estar dentro.
  ///
  /// Google y Apple faltaban, y el efecto era que no se podía entrar con
  /// ninguno de los dos: sin sesión válida `isExpired()` es cierto, el refresh
  /// proactivo de [onRequest] no encuentra token que renovar y rechaza la
  /// petición **antes de que salga del teléfono**, con un 401 fabricado y sin
  /// cuerpo. El usuario elegía su cuenta en la hoja de Google, volvía a la app y
  /// se encontraba «Tu sesión expiró», que era el texto por defecto de un 401
  /// sin mensaje. El servidor nunca llegó a enterarse del intento.
  ///
  /// Se notaba solo cuando de verdad no había sesión —instalación nueva, o la
  /// anterior ya vencida—, que es justo cuando alguien pulsa el botón.
  static const _skipAuthPaths = {
    ApiEndpoints.login,
    ApiEndpoints.register,
    ApiEndpoints.google,
    ApiEndpoints.apple,
    ApiEndpoints.refresh,
    ApiEndpoints.forgotPassword,
    ApiEndpoints.resetPassword,

    // Verificar el correo y pedir otro código pasan por aquí, y faltaban.
    //
    // Al registrarse no hay sesión —`/auth/register` devuelve un mensaje, no
    // tokens—, así que el efecto era el mismo que con Google: la petición se
    // rechazaba en el teléfono con un 401 fabricado y la pantalla decía «Tu
    // sesión expiró» a alguien que acababa de crear su cuenta y nunca había
    // tenido una. El servidor no llegaba a enterarse del intento.
    ApiEndpoints.verifyCode,
    ApiEndpoints.resendVerification,

    // Pedir el enlace de activación por correo: el correo va en el cuerpo y el
    // servidor no mira el token. NO confundir con `activationLinkDirect`, que
    // cuelga de esta misma ruta y **sí** exige sesión — por eso la comparación
    // de abajo es exacta.
    ApiEndpoints.activationLink,
  };

  /// Comparación EXACTA, no por prefijo.
  ///
  /// Con `startsWith`, añadir `/billing/activation-link` a la lista dejaría
  /// también sin token a `/billing/activation-link/direct`, que sí necesita
  /// saber quién llama. Un prefijo que se traga a su propia ruta hija es un
  /// fallo que no se ve hasta que alguien añade la ruta hija, y ninguna de
  /// estas rutas lleva parámetros que justifiquen el prefijo.
  bool _needsAuth(RequestOptions options) =>
      !_skipAuthPaths.contains(options.path);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_needsAuth(options)) {
      return handler.next(options);
    }

    // Renovar de forma proactiva evita un 401 y un reintento por cada petición.
    if (await _tokens.isExpired()) {
      final refreshed = await _refreshToken();
      if (refreshed == null) {
        return handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: Response(requestOptions: options, statusCode: 401),
            error: 'No se pudo renovar la sesión',
          ),
        );
      }
    }

    final token = await _tokens.readAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final isAuthError = err.response?.statusCode == 401;
    final alreadyRetried = err.requestOptions.extra['retried'] == true;

    if (!isAuthError || alreadyRetried || !_needsAuth(err.requestOptions)) {
      return handler.next(err);
    }

    final token = await _refreshToken();
    if (token == null) {
      return handler.next(err);
    }

    // Reintentar la petición original una sola vez, con el token nuevo.
    final options = err.requestOptions
      ..headers['Authorization'] = 'Bearer $token'
      ..extra['retried'] = true;

    try {
      final response = await _refreshClient.fetch<dynamic>(options);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }

  /// Renueva el access token. Devuelve `null` si la sesión ya no es válida.
  Future<String?> _refreshToken() {
    // Si ya hay un refresh en curso, súmate a ese en vez de lanzar otro.
    return _inFlightRefresh ??= _doRefresh().whenComplete(() {
      _inFlightRefresh = null;
    });
  }

  Future<String?> _doRefresh() async {
    final refreshToken = await _tokens.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      onSessionExpired();
      return null;
    }

    try {
      final response = await _refreshClient.post<Map<String, dynamic>>(
        ApiEndpoints.refresh,
        data: {'refreshToken': refreshToken},
      );

      final data = response.data;
      if (data == null) {
        await _failSession();
        return null;
      }

      final accessToken = data['accessToken'] as String?;
      final newRefreshToken = data['refreshToken'] as String?;
      final expiresAtRaw = data['expiresAt'] as String?;

      if (accessToken == null || expiresAtRaw == null) {
        await _failSession();
        return null;
      }

      final expiresAt =
          DateTime.tryParse(expiresAtRaw) ??
          DateTime.now().add(const Duration(minutes: 15));

      // El backend rota el refresh token (RNF-04): si manda uno nuevo, guárdalo.
      if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
        await _tokens.save(
          accessToken: accessToken,
          refreshToken: newRefreshToken,
          expiresAt: expiresAt,
        );
      } else {
        await _tokens.updateAccessToken(
          accessToken: accessToken,
          expiresAt: expiresAt,
        );
      }

      return accessToken;
    } on DioException {
      await _failSession();
      return null;
    }
  }

  Future<void> _failSession() async {
    await _tokens.clear();
    onSessionExpired();
  }
}
