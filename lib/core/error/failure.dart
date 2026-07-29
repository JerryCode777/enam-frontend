/// Errores que la capa de datos puede devolver a la UI.
///
/// Las pantallas nunca ven un `DioException`: la capa de red los traduce a un
/// [Failure], que ya trae un mensaje mostrable al usuario en español.
///
/// El SSD §6 define el formato de error del backend:
/// `{"error": {"code", "message", "details"}}`
sealed class Failure implements Exception {
  const Failure(this.message, {this.code, this.details});

  /// Mensaje mostrable al usuario. En español, sin jerga técnica.
  final String message;

  /// Código del backend, para distinguir casos sin parsear el mensaje.
  final String? code;

  final Object? details;

  @override
  String toString() => '$runtimeType($code): $message';
}

/// No hay conexión, o el servidor no responde.
final class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'Sin conexión. Revisa tu internet e inténtalo de nuevo.',
  ]);
}

/// La petición tardó demasiado.
final class TimeoutFailure extends Failure {
  const TimeoutFailure([
    super.message = 'El servidor está tardando demasiado. Inténtalo de nuevo.',
  ]);
}

/// Credenciales inválidas, o sesión expirada sin poder renovarla (401).
final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([
    super.message = 'Tu sesión expiró. Vuelve a iniciar sesión.',
    String? code,
  ]) : super(code: code);
}

/// Autenticado, pero sin permiso (403).
///
/// El caso más común es contenido premium con plan free: RN-03 obliga a que la
/// validación sea del servidor, así que la app debe manejar este 403 mostrando
/// el paywall, no escondiendo el botón y asumiendo que basta.
final class ForbiddenFailure extends Failure {
  const ForbiddenFailure([
    super.message = 'Tu plan actual no incluye este contenido.',
    String? code,
  ]) : super(code: code);

  /// Si el 403 viene de haber agotado el límite diario del plan free (RN-03).
  bool get isPlanLimit => code == 'PLAN_LIMIT_REACHED';
}

/// El recurso no existe (404).
final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'No encontramos lo que buscabas.']);
}

/// Datos inválidos enviados por la app (422 o 400).
final class ValidationFailure extends Failure {
  const ValidationFailure(
    super.message, {
    super.code,
    this.fieldErrors = const {},
  });

  /// Errores por campo, para pintarlos en el formulario.
  final Map<String, String> fieldErrors;
}

/// Demasiadas peticiones (429). El SSD aplica rate limiting por IP y usuario.
final class RateLimitFailure extends Failure {
  const RateLimitFailure([
    super.message = 'Demasiados intentos. Espera un momento.',
    this.retryAfter,
  ]);

  final Duration? retryAfter;
}

/// Error del servidor (5xx).
final class ServerFailure extends Failure {
  const ServerFailure([
    super.message = 'Tuvimos un problema. Inténtalo en unos minutos.',
    String? code,
  ]) : super(code: code);
}

/// La app está en mantenimiento, o requiere actualizarse.
final class MaintenanceFailure extends Failure {
  const MaintenanceFailure([
    super.message = 'Estamos en mantenimiento. Vuelve pronto.',
  ]);
}

/// Cualquier otra cosa. Si esto aparece seguido, falta un caso arriba.
final class UnknownFailure extends Failure {
  // `details` es named en Failure, así que no puede pasarse como super formal
  // posicional: se reenvía explícitamente.
  const UnknownFailure([
    super.message = 'Ocurrió un error inesperado.',
    Object? details,
  ]) : super(details: details);
}
