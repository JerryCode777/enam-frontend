import '../../../core/config/api_endpoints.dart';
import '../../../core/network/api_client.dart';

/// Lo que devuelve el servidor al recibir un reporte.
typedef ReporteRecibido = ({String id, String estado});

/// Reportes de preguntas (RN-06), `POST /questions/{id}/reports`.
///
/// El servidor deduplica: el mismo motivo sobre la misma pregunta, mientras el
/// reporte siga abierto, devuelve el mismo id. Pulsar dos veces no crea dos.
abstract interface class ReportesRepository {
  /// [motivo] es uno de `clave`, `texto`, `imagen`, `explicacion`.
  ///
  /// Lanza `RateLimitFailure` tras varios seguidos, `NotFoundFailure` si la
  /// pregunta no existe **o si el servidor todavía no tiene el endpoint**: los
  /// dos 404 llegan igual, y quien llama cae al canal de respaldo en ambos.
  Future<ReporteRecibido> reportar({
    required String preguntaId,
    required String motivo,
    String? comentario,
    String? sessionId,
  });
}

class ApiReportesRepository implements ReportesRepository {
  ApiReportesRepository(this._client);

  final ApiClient _client;

  @override
  Future<ReporteRecibido> reportar({
    required String preguntaId,
    required String motivo,
    String? comentario,
    String? sessionId,
  }) async {
    final data = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.reportarPregunta(preguntaId),
      data: {
        'motivo': motivo,
        'comentario': ?comentario,
        'sessionId': ?sessionId,
      },
    );
    return (
      id: data['id'] as String? ?? '',
      estado: data['estado'] as String? ?? 'recibido',
    );
  }
}

class MockReportesRepository implements ReportesRepository {
  int _siguiente = 0;

  @override
  Future<ReporteRecibido> reportar({
    required String preguntaId,
    required String motivo,
    String? comentario,
    String? sessionId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return (id: 'reporte-${++_siguiente}', estado: 'recibido');
  }
}
