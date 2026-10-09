import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Un evento esperando a salir. Lleva su `evento_id` desde que nace: un
/// reintento manda **el mismo**, y el servidor lo reconoce como duplicado.
///
/// También lleva sus [comunes] (plataforma, versión de la app, versión
/// visual, `anonimo_id`) **de cuando se generó** (contrato, §4). Si la app se
/// actualiza con eventos en cola, esos salen con la versión que tenían.
typedef EventoEnCola = ({
  String eventoId,
  String tipo,
  DateTime ocurridoEn,
  Map<String, Object> propiedades,
  Map<String, Object> comunes,
});

/// Dónde vive la cola entre ejecuciones.
abstract interface class AlmacenDeCola {
  Future<List<EventoEnCola>> leer();
  Future<void> guardar(List<EventoEnCola> eventos);
}

/// La cola de eventos del teléfono (contrato, §3): hasta [maximo] eventos y
/// [vigencia] de antigüedad, que es la ventana que el servidor acepta de la
/// app (siete días, por el modo sin conexión).
///
/// Se guarda **antes** de intentar mandar nada, así que cerrar la app a mitad
/// de un envío no pierde eventos: al volver siguen ahí, con sus mismos ids.
class ColaDeEventos {
  ColaDeEventos(
    this._almacen, {
    this.maximo = 500,
    this.vigencia = const Duration(days: 7),
    DateTime Function()? reloj,
  }) : _reloj = reloj ?? DateTime.now;

  final AlmacenDeCola _almacen;
  final int maximo;
  final Duration vigencia;
  final DateTime Function() _reloj;

  /// Los pendientes, ya sin los vencidos.
  Future<List<EventoEnCola>> pendientes() async {
    final todos = await _almacen.leer();
    final vigentes = _podar(todos);
    if (vigentes.length != todos.length) await _almacen.guardar(vigentes);
    return vigentes;
  }

  Future<void> agregar(EventoEnCola evento) async {
    final actuales = _podar(await _almacen.leer());
    final nuevos = [...actuales, evento];
    // Llena, se pierden los más viejos: son los que menos dicen del presente.
    final recortados = nuevos.length > maximo
        ? nuevos.sublist(nuevos.length - maximo)
        : nuevos;
    await _almacen.guardar(recortados);
  }

  /// Quita los que el servidor ya contestó (aceptados, duplicados o
  /// rechazados: los rechazos son definitivos y no se reintentan).
  Future<void> retirar(Set<String> eventoIds) async {
    if (eventoIds.isEmpty) return;
    final actuales = await _almacen.leer();
    await _almacen.guardar([
      for (final e in actuales)
        if (!eventoIds.contains(e.eventoId)) e,
    ]);
  }

  List<EventoEnCola> _podar(List<EventoEnCola> eventos) {
    final limite = _reloj().toUtc().subtract(vigencia);
    return [
      for (final e in eventos)
        if (e.ocurridoEn.isAfter(limite)) e,
    ];
  }
}

/// La cola en `shared_preferences`. No hay datos personales que proteger: son
/// tipos de evento, fechas y valores de una lista cerrada.
class AlmacenDeColaPrefs implements AlmacenDeCola {
  static const _clave = 'analitica.cola.v1';

  @override
  Future<List<EventoEnCola>> leer() async {
    try {
      final crudo = (await SharedPreferences.getInstance()).getString(_clave);
      if (crudo == null) return [];
      return [
        for (final e
            in (jsonDecode(crudo) as List).cast<Map<String, dynamic>>())
          // Los guardados sin sus comunes (formato anterior) se descartan:
          // ponerles las de ahora cambiaría su versión (contrato, §4).
          if (e['comunes'] case final Map<String, dynamic> comunes)
            (
              eventoId: e['evento_id'] as String,
              tipo: e['tipo'] as String,
              ocurridoEn: DateTime.parse(e['ocurrido_en'] as String),
              propiedades: (e['propiedades'] as Map).cast<String, Object>(),
              comunes: comunes.cast<String, Object>(),
            ),
      ];
    } catch (_) {
      // Una cola ilegible no puede romper nada: se empieza de nuevo.
      return [];
    }
  }

  @override
  Future<void> guardar(List<EventoEnCola> eventos) async {
    try {
      await (await SharedPreferences.getInstance()).setString(
        _clave,
        jsonEncode([
          for (final e in eventos) {...aJson(e), 'comunes': e.comunes},
        ]),
      );
    } catch (_) {}
  }
}

/// Un evento tal como viaja en el lote del contrato. Sus comunes van en el
/// sobre, no en el evento.
Map<String, Object> aJson(EventoEnCola e) => {
  'evento_id': e.eventoId,
  'tipo': e.tipo,
  'ocurrido_en': e.ocurridoEn.toUtc().toIso8601String(),
  'propiedades': e.propiedades,
};
