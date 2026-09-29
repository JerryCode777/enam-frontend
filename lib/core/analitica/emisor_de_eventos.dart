import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show mapEquals;

import '../config/api_endpoints.dart';
import '../config/app_config.dart';
import 'cola_de_eventos.dart';

/// Lo que contestó el servidor a un lote. `status` 0 = no hubo respuesta (sin
/// red, tiempo agotado).
typedef RespuestaDeEventos = ({
  int status,
  Map<String, dynamic>? cuerpo,
  Duration? reintentarEn,
});

/// El tramo de red, aparte para poder probar el emisor sin servidor.
abstract interface class TransporteDeEventos {
  Future<RespuestaDeEventos> enviar(
    Map<String, Object> cuerpo, {
    String? token,
  });
}

/// `POST /api/v1/eventos` con un Dio propio, **sin** el interceptor de sesión.
///
/// A propósito: un 401 de la analítica no puede acabar cerrando la sesión de
/// nadie. El emisor decide qué hacer con cada respuesta según el contrato.
class TransporteDio implements TransporteDeEventos {
  TransporteDio({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: AppConfig.apiUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
              contentType: Headers.jsonContentType,
              validateStatus: (_) => true,
            ),
          );

  final Dio _dio;

  @override
  Future<RespuestaDeEventos> enviar(
    Map<String, Object> cuerpo, {
    String? token,
  }) async {
    try {
      final r = await _dio.post<dynamic>(
        ApiEndpoints.eventos,
        data: cuerpo,
        options: Options(
          headers: {'Authorization': ?(token == null ? null : 'Bearer $token')},
        ),
      );
      final segundos = int.tryParse(r.headers.value('retry-after') ?? '');
      return (
        status: r.statusCode ?? 0,
        cuerpo: r.data is Map<String, dynamic>
            ? r.data as Map<String, dynamic>
            : null,
        reintentarEn: segundos == null ? null : Duration(seconds: segundos),
      );
    } on DioException {
      return (status: 0, cuerpo: null, reintentarEn: null);
    }
  }
}

/// Manda la cola al servidor en lotes (contrato de eventos, §4).
///
/// Un sobre por cada combinación distinta de comunes: cada evento sale con
/// las que tenía al generarse, no con las de quien lo envía.
///
/// **Nunca rompe el producto.** No lanza, no muestra nada y no se reporta a sí
/// mismo como error: si no puede mandar, lo deja en la cola y lo intenta
/// después.
class EmisorDeEventos {
  EmisorDeEventos({
    required ColaDeEventos cola,
    required TransporteDeEventos transporte,
    required Future<String?> Function() token,
    required Future<String?> Function() renovarToken,
    DateTime Function()? reloj,
    Random? azar,
  }) : _cola = cola,
       _transporte = transporte,
       _token = token,
       _renovar = renovarToken,
       _reloj = reloj ?? DateTime.now,
       _azar = azar ?? Random();

  static const eventosPorLote = 50;
  static const bytesPorCuerpo = 64 * 1024;
  static const versionContrato = 1;

  final ColaDeEventos _cola;
  final TransporteDeEventos _transporte;
  final Future<String?> Function() _token;
  final Future<String?> Function() _renovar;
  final DateTime Function() _reloj;
  final Random _azar;

  bool _enviando = false;
  int _fallosSeguidos = 0;
  DateTime? _noAntesDe;

  /// Cuándo se puede volver a intentar tras un fallo, o `null` si ya.
  DateTime? get noAntesDe => _noAntesDe;

  /// Manda todo lo pendiente, lote a lote, hasta vaciar la cola o toparse con
  /// un fallo que pide esperar. Dos llamadas a la vez no mandan dos veces.
  Future<void> vaciar() async {
    if (_enviando) return;
    if (_noAntesDe case final espera? when _reloj().isBefore(espera)) return;
    _enviando = true;
    try {
      var tamano = eventosPorLote;
      while (true) {
        final pendientes = await _cola.pendientes();
        if (pendientes.isEmpty) return;

        // Las comunes del más viejo, y solo los que las comparten.
        final comunes = pendientes.first.comunes;
        final lote = pendientes
            .where((e) => mapEquals(e.comunes, comunes))
            .take(tamano)
            .toList();
        final cuerpo = _cuerpo(comunes, lote);

        // Un cuerpo de más de 64 KiB se parte antes de salir.
        if (utf8.encode(jsonEncode(cuerpo)).length > bytesPorCuerpo &&
            lote.length > 1) {
          tamano = max(1, lote.length ~/ 2);
          continue;
        }

        final r = await _enviarConToken(cuerpo);
        switch (r.status) {
          case 200:
            final contestados = _contestados(lote, r.cuerpo);
            await _cola.retirar(contestados);
            _fallosSeguidos = 0;
            _noAntesDe = null;
            tamano = eventosPorLote;
            // Lo que el servidor no nombró se queda para la próxima ronda. Si
            // no nombró nada, se espera: reenviar al instante sería un bucle.
            if (contestados.isEmpty) {
              _esperar(null);
              return;
            }
            if (contestados.length < lote.length) return;
          case 400:
            // Sobre inválido: el mismo cuerpo fallará igual. Se descarta.
            await _cola.retirar({for (final e in lote) e.eventoId});
          case 413 when lote.length > 1:
            tamano = max(1, lote.length ~/ 2);
          case 413:
            await _cola.retirar({lote.single.eventoId});
          case 429:
            _esperar(r.reintentarEn);
            return;
          default:
            // Sin red, 5xx o tiempo agotado: se reintenta más tarde con los
            // mismos `evento_id`.
            _esperar(null);
            return;
        }
      }
    } on Object {
      // Nada de la analítica sube a quien la usa.
    } finally {
      _enviando = false;
    }
  }

  /// Con token si lo hay. Si el servidor dice que no vale (401), se renueva
  /// una vez y se reintenta; si vuelve a fallar, se manda sin token: el
  /// evento sigue siendo útil, solo que anónimo.
  Future<RespuestaDeEventos> _enviarConToken(Map<String, Object> cuerpo) async {
    final token = await _token();
    var r = await _transporte.enviar(cuerpo, token: token);
    if (r.status != 401 || token == null) return r;

    final renovado = await _renovar();
    if (renovado != null) {
      r = await _transporte.enviar(cuerpo, token: renovado);
      if (r.status != 401) return r;
    }
    return _transporte.enviar(cuerpo);
  }

  Map<String, Object> _cuerpo(
    Map<String, Object> comunes,
    List<EventoEnCola> lote,
  ) => {
    'version_contrato': versionContrato,
    'comunes': comunes,
    'eventos': [for (final e in lote) aJson(e)],
  };

  /// Los ids que el servidor contestó: aceptados, duplicados o rechazados.
  /// Lo que no nombre se queda en la cola.
  Set<String> _contestados(List<EventoEnCola> lote, Map<String, dynamic>? r) {
    if (r == null) return {for (final e in lote) e.eventoId};
    final indices = <int>{
      ...((r['aceptados'] as List?) ?? const []).whereType<int>(),
      ...((r['duplicados'] as List?) ?? const []).whereType<int>(),
      for (final x in (r['rechazados'] as List?) ?? const [])
        if (x is Map && x['indice'] is int) x['indice'] as int,
    };
    return {
      for (final i in indices)
        if (i >= 0 && i < lote.length) lote[i].eventoId,
    };
  }

  /// Espera antes del siguiente intento: lo que diga `Retry-After`, o un
  /// retroceso de 1 a 60 s que se dobla con cada fallo seguido, con algo de
  /// azar para que mil teléfonos no vuelvan a la vez.
  void _esperar(Duration? pedido) {
    _fallosSeguidos++;
    final base =
        pedido ??
        Duration(seconds: min(60, pow(2, _fallosSeguidos - 1).toInt()));
    final azar = Duration(milliseconds: _azar.nextInt(1000));
    _noAntesDe = _reloj().add(base + azar);
  }
}
