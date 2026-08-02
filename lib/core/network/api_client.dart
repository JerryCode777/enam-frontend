import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../error/failure.dart';
import '../storage/token_storage.dart';
import 'auth_interceptor.dart';

/// Cliente HTTP de la app.
///
/// Responsabilidades:
/// - Configurar base URL y timeouts según el entorno.
/// - Adjuntar y renovar el token (vía [AuthInterceptor]).
/// - Traducir cualquier `DioException` a un [Failure] con mensaje en español.
///
/// Los repositorios usan esta clase; nunca crean su propio `Dio`.
class ApiClient {
  ApiClient({
    required TokenStorage tokenStorage,
    required this.onSessionExpired,
  }) : _tokens = tokenStorage {
    _dio = Dio(_baseOptions);

    // Cliente separado para el refresh: sin AuthInterceptor, para no recursar.
    final refreshClient = Dio(_baseOptions);

    _dio.interceptors.add(
      AuthInterceptor(
        tokenStorage: _tokens,
        refreshClient: refreshClient,
        onSessionExpired: onSessionExpired,
      ),
    );

    if (AppConfig.logHttp) {
      _dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestBody: true,
          responseBody: true,
          // Nunca loguear headers: ahí viaja el Bearer token.
          requestHeader: false,
          responseHeader: false,
          logPrint: (o) => debugPrint('[http] $o'),
        ),
      );
    }
  }

  late final Dio _dio;
  final TokenStorage _tokens;

  /// Se dispara cuando la sesión expira sin poder renovarse.
  final void Function() onSessionExpired;

  BaseOptions get _baseOptions => BaseOptions(
    baseUrl: AppConfig.apiUrl,
    connectTimeout: AppConfig.connectTimeout,
    receiveTimeout: AppConfig.receiveTimeout,
    contentType: Headers.jsonContentType,
    // Manejamos los códigos de error nosotros, en _toFailure.
    validateStatus: (status) => status != null && status < 400,
  );

  Dio get raw => _dio;

  /// [onReceiveProgress] existe para las descargas grandes —el paquete de un
  /// área son cientos de preguntas—, donde una barra de verdad es la diferencia
  /// entre esperar y creer que se colgó. En respuestas normales no se usa.
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) => _request(
    () => _dio.get<T>(
      path,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    ),
  );

  Future<T> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) => _request(
    () => _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
    ),
  );

  Future<T> patch<T>(String path, {Object? data, CancelToken? cancelToken}) =>
      _request(() => _dio.patch<T>(path, data: data, cancelToken: cancelToken));

  Future<T> delete<T>(String path, {Object? data, CancelToken? cancelToken}) =>
      _request(
        () => _dio.delete<T>(path, data: data, cancelToken: cancelToken),
      );

  Future<T> _request<T>(Future<Response<T>> Function() send) async {
    try {
      final response = await send();
      final data = response.data;
      if (data == null) {
        throw const UnknownFailure('El servidor devolvió una respuesta vacía.');
      }
      return data;
    } on DioException catch (e) {
      throw _toFailure(e);
    }
  }

  /// Traduce un error de Dio al [Failure] correspondiente.
  ///
  /// El backend responde `{"error": {"code", "message", "details"}}` (SSD §6),
  /// así que preferimos su mensaje cuando viene; si no, usamos el genérico.
  Failure _toFailure(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutFailure();
      case DioExceptionType.connectionError:
        return const NetworkFailure();
      case DioExceptionType.cancel:
        return const UnknownFailure('Petición cancelada.');
      case DioExceptionType.badCertificate:
        return const NetworkFailure('No pudimos verificar la conexión segura.');
      // badResponse y unknown siguen abajo, donde se inspecciona el status.
      // Un `default` aquí escondería casos nuevos de Dio, así que se enumeran.
      default:
        break;
    }

    final response = e.response;
    final status = response?.statusCode;
    final parsed = _parseErrorBody(response?.data);
    final message = parsed.message;
    final code = parsed.code;

    return switch (status) {
      400 || 422 => ValidationFailure(
        message ?? 'Revisa los datos ingresados.',
        code: code,
        fieldErrors: parsed.fieldErrors,
      ),
      401 => UnauthorizedFailure(
        message ?? 'Tu sesión expiró. Vuelve a iniciar sesión.',
        code,
      ),
      403 => ForbiddenFailure(
        message ?? 'Tu plan actual no incluye este contenido.',
        code,
      ),
      404 => NotFoundFailure(message ?? 'No encontramos lo que buscabas.'),
      429 => RateLimitFailure(
        message ?? 'Demasiados intentos. Espera un momento.',
        _retryAfter(response),
      ),
      503 => MaintenanceFailure(message ?? 'Estamos en mantenimiento.'),
      _ when status != null && status >= 500 => ServerFailure(
        message ?? 'Tuvimos un problema. Inténtalo en unos minutos.',
        code,
      ),
      _ => UnknownFailure(message ?? 'Ocurrió un error inesperado.', e),
    };
  }

  ({String? message, String? code, Map<String, String> fieldErrors})
  _parseErrorBody(Object? body) {
    if (body is! Map) return (message: null, code: null, fieldErrors: const {});

    final error = body['error'];
    if (error is! Map) {
      return (message: null, code: null, fieldErrors: const {});
    }

    final details = error['details'];
    final fieldErrors = <String, String>{};
    if (details is Map) {
      details.forEach((key, value) {
        if (key is String) fieldErrors[key] = value.toString();
      });
    }

    return (
      message: error['message'] as String?,
      code: error['code'] as String?,
      fieldErrors: fieldErrors,
    );
  }

  Duration? _retryAfter(Response<dynamic>? response) {
    final header = response?.headers.value('retry-after');
    final seconds = int.tryParse(header ?? '');
    return seconds == null ? null : Duration(seconds: seconds);
  }
}
