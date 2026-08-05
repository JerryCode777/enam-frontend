import '../../../core/config/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../domain/duelo_models.dart';

/// Los endpoints del modo duelo (SSD-ENAM-004 §6).
///
/// Todo lo de aquí es HTTP normal: crear el duelo, entrar por código, pedir el
/// ticket. **La partida en sí NO pasa por aquí** — va por el socket, que abre
/// `DueloSocket`.
///
/// Se declara como interfaz aunque hoy solo tenga una implementación, igual que
/// el resto del proyecto: es lo que permite que los tests de las pantallas no
/// necesiten un servidor.
abstract interface class DueloRepository {
  /// Busca rival al azar.
  ///
  /// Devuelve un duelo en `esperando` si no había nadie, o uno `en_curso` si
  /// enganchó con alguien que ya estaba en la cola. El cliente distingue por
  /// `completo`, no por el código de respuesta.
  Future<DueloDTO> buscarAleatorio();

  /// Crea un duelo con PIN para compartir.
  Future<DueloDTO> crearPorEnlace();

  /// Mira a qué lleva un PIN, sin entrar todavía.
  Future<DueloDTO> mirarCodigo(String codigo);

  /// Entra al duelo de un PIN.
  Future<DueloDTO> unirsePorCodigo(String codigo);

  /// Mete al bot como rival. Solo vale si el duelo sigue esperando, y el
  /// servidor lo rechaza a quien entró con el pase diario (RF-65).
  Future<DueloDTO> aceptarBot(String dueloId);

  Future<DueloDTO> duelo(String dueloId);

  /// Canjea la sesión por un permiso de un solo uso para abrir el socket.
  ///
  /// Hace falta porque **no se puede mandar la cabecera `Authorization` al
  /// abrir un WebSocket**. El ticket vive 30 segundos y vale una vez.
  Future<TicketDeDuelo> pedirTicket(String dueloId);

  /// Crea —o encuentra— la revancha contra el mismo rival (RF-61).
  Future<DueloDTO> revancha(String dueloId);

  /// Si el rival ya pidió la revancha de este duelo.
  ///
  /// Lo consulta la pantalla de resultado, que para entonces **ya no tiene
  /// socket**: la sala se cierra al terminar la partida, así que no hay por
  /// dónde avisar. Responde 404 mientras nadie la haya pedido, que es la
  /// respuesta normal y no un fallo.
  Future<DueloDTO> revanchaDe(String dueloId);

  /// Cierra un duelo que sigue esperando rival.
  ///
  /// Hace falta de verdad y no basta con navegar hacia atrás: solo se admite un
  /// duelo abierto por persona, así que dejarlo colgado impide empezar otro
  /// hasta que caduque solo.
  Future<void> cancelar(String dueloId);

  /// Cuántos duelos gratuitos le quedan hoy a quien no tiene plan (RF-65).
  ///
  /// Se pregunta en vez de saberlo porque el número vive en el servidor
  /// (`DUELO_GRATIS_POR_DIA`): así apagarlo allí apaga el botón aquí, sin
  /// publicar una versión nueva de la app.
  Future<PaseDeDuelo> paseDelDia();
}

class ApiDueloRepository implements DueloRepository {
  const ApiDueloRepository(this._client);

  final ApiClient _client;

  @override
  Future<DueloDTO> buscarAleatorio() => _duelo(
    () => _client.post<Map<String, dynamic>>(ApiEndpoints.duelRandom),
  );

  @override
  Future<DueloDTO> crearPorEnlace() =>
      _duelo(() => _client.post<Map<String, dynamic>>(ApiEndpoints.duelLink));

  @override
  Future<DueloDTO> mirarCodigo(String codigo) => _duelo(
    () => _client.get<Map<String, dynamic>>(
      ApiEndpoints.duelByCode(Uri.encodeComponent(codigo)),
    ),
  );

  @override
  Future<DueloDTO> unirsePorCodigo(String codigo) => _duelo(
    () => _client.post<Map<String, dynamic>>(
      ApiEndpoints.joinDuelByCode(Uri.encodeComponent(codigo)),
    ),
  );

  @override
  Future<DueloDTO> aceptarBot(String dueloId) => _duelo(
    () => _client.post<Map<String, dynamic>>(ApiEndpoints.duelBot(dueloId)),
  );

  @override
  Future<DueloDTO> duelo(String dueloId) =>
      _duelo(() => _client.get<Map<String, dynamic>>(ApiEndpoints.duel(dueloId)));

  @override
  Future<DueloDTO> revancha(String dueloId) => _duelo(
    () => _client.post<Map<String, dynamic>>(ApiEndpoints.duelRematch(dueloId)),
  );

  @override
  Future<DueloDTO> revanchaDe(String dueloId) => _duelo(
    () => _client.get<Map<String, dynamic>>(ApiEndpoints.duelRematch(dueloId)),
  );

  @override
  Future<TicketDeDuelo> pedirTicket(String dueloId) async {
    final json = await _client.post<Map<String, dynamic>>(
      ApiEndpoints.duelTicket(dueloId),
    );
    return TicketDeDuelo.fromJson(json);
  }

  @override
  Future<void> cancelar(String dueloId) async {
    // Devuelve 204 sin cuerpo, así que se pide `dynamic`: pedir un mapa haría
    // fallar la única llamada del duelo que no responde nada.
    await _client.post<dynamic>(ApiEndpoints.duelCancel(dueloId));
  }

  @override
  Future<PaseDeDuelo> paseDelDia() async {
    final json = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.duelPass,
    );
    return PaseDeDuelo.fromJson(json);
  }

  Future<DueloDTO> _duelo(Future<Map<String, dynamic>> Function() pedir) async =>
      DueloDTO.fromJson(await pedir());
}
