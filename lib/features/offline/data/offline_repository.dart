import '../../../core/config/api_endpoints.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/network/api_client.dart';
import '../domain/offline_models.dart';

/// Los dos endpoints del modo sin conexión (M7 del SSD).
///
/// El servidor ya los tiene montados; esto es el lado del teléfono:
/// - `GET /offline/packages/:areaId` — el banco de un área, con claves.
/// - `POST /offline/sync` — las respuestas hechas sin señal.
abstract interface class OfflineRepository {
  /// El paquete de un área (RF-30).
  ///
  /// Devuelve 403 con `SUBSCRIPTION_REQUIRED` si el usuario no tiene plan: es
  /// contenido premium y la validación es del servidor (RN-03/RF-29).
  ///
  /// [progreso] recibe los bytes recibidos y el total. El total llega en `-1`
  /// cuando el servidor no manda `content-length`, así que quien pinta la barra
  /// tiene que estar preparado para no saber cuánto falta.
  Future<PaqueteOffline> paquete(
    String areaId, {
    void Function(int recibidos, int total)? progreso,
  });

  /// Manda lo respondido sin conexión (RF-32).
  ///
  /// El servidor resuelve los choques por marca de tiempo y devuelve cuáles no
  /// pudo aplicar. Los simulacros nacionales los rechaza siempre (RF-33).
  Future<ResultadoDeSync> sincronizar(List<RespuestaPendiente> respuestas);
}

class ApiOfflineRepository implements OfflineRepository {
  ApiOfflineRepository(this._client);

  final ApiClient _client;

  @override
  Future<PaqueteOffline> paquete(
    String areaId, {
    void Function(int recibidos, int total)? progreso,
  }) async {
    final data = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.offlinePackage(areaId),
      onReceiveProgress: progreso == null
          ? null
          : (recibidos, total) => progreso(recibidos, total),
    );
    return PaqueteOffline.fromJson(data);
  }

  @override
  Future<ResultadoDeSync> sincronizar(
    List<RespuestaPendiente> respuestas,
  ) async {
    final data = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.offlineSync,
      data: {
        'respuestas': [
          for (final r in respuestas)
            {
              'sessionId': r.sesionId,
              'questionId': r.preguntaId,
              'optionId': r.opcionId,
              'tiempoMs': r.tiempoMs,
              'marcada': r.marcada,
              // El servidor descarta la del teléfono si ya tenía una más
              // reciente, así que esta fecha es el dato que decide.
              'respondidaEn': r.respondidaEn.toUtc().toIso8601String(),
            },
        ],
      },
    );
    return ResultadoDeSync.fromJson(data);
  }
}

/// Paquetes de mentira, para recorrer la pantalla sin backend.
class MockOfflineRepository implements OfflineRepository {
  static const _demora = Duration(milliseconds: 700);

  @override
  Future<PaqueteOffline> paquete(
    String areaId, {
    void Function(int recibidos, int total)? progreso,
  }) async {
    // Se simula la descarga por partes para poder ver la barra avanzar.
    for (var parte = 1; parte <= 4; parte++) {
      await Future<void>.delayed(_demora ~/ 4);
      progreso?.call(parte * 250, 1000);
    }
    return PaqueteOffline(
      areaId: areaId,
      generadoEn: DateTime.now(),
      // Con las claves puestas: es lo que distingue un paquete offline de la
      // lista de preguntas de un examen en curso.
      preguntas: MockData.questions(cantidad: 40, conRespuestas: true),
      total: 40,
    );
  }

  @override
  Future<ResultadoDeSync> sincronizar(
    List<RespuestaPendiente> respuestas,
  ) async {
    await Future<void>.delayed(_demora);
    return ResultadoDeSync(aceptadas: respuestas.length);
  }
}
