import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers.dart';
import '../../auth/domain/auth_models.dart';

/// Dónde se decidió, como lo guarda el servidor en
/// `users.acepta_comerciales_origen`.
enum OrigenConsentimiento {
  ajustes('ajustes'),

  /// La tarjeta del inicio al terminar el día gratis (19/10/2026).
  finDiaGratis('fin_dia_gratis');

  const OrigenConsentimiento(this.valor);

  final String valor;
}

/// El permiso de correos comerciales de la cuenta.
abstract class ConsentimientoRepository {
  /// Guarda la decisión y devuelve el perfil como queda.
  Future<User> decidir({
    required bool acepta,
    required OrigenConsentimiento origen,
  });
}

class ApiConsentimientoRepository implements ConsentimientoRepository {
  ApiConsentimientoRepository(this._client);

  final ApiClient _client;

  @override
  Future<User> decidir({
    required bool acepta,
    required OrigenConsentimiento origen,
  }) async {
    final data = await _client.patch<Map<String, dynamic>>(
      ApiEndpoints.me,
      data: {'aceptaComerciales': acepta, 'origenConsentimiento': origen.valor},
    );
    return User.fromJson(data);
  }
}

final consentimientoRepositoryProvider = Provider<ConsentimientoRepository>(
  (ref) => ApiConsentimientoRepository(ref.watch(apiClientProvider)),
);
