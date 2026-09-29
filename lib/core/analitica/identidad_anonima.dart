import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// El `anonimo_id` del contrato de eventos: un UUID v4 aleatorio, generado la
/// primera vez que se necesita y guardado en el teléfono.
///
/// No se deriva de nada de la persona. Sobrevive a cerrar sesión (es del
/// dispositivo, no de la cuenta) y se manda también con sesión iniciada: es lo
/// que une la visita anónima con la cuenta que se crea después.
class IdentidadAnonima {
  IdentidadAnonima({Random? azar}) : _azar = azar ?? Random.secure();

  static const _clave = 'enam.anonimo';

  final Random _azar;
  String? _enMemoria;

  Future<String> id() async {
    if (_enMemoria case final id?) return id;
    try {
      final prefs = await SharedPreferences.getInstance();
      final guardado = prefs.getString(_clave);
      if (guardado != null && esUuid(guardado)) return _enMemoria = guardado;
      final nuevo = uuidV4(_azar);
      await prefs.setString(_clave, nuevo);
      return _enMemoria = nuevo;
    } catch (_) {
      // Sin almacenamiento, uno para esta ejecución: mejor eso que ninguno.
      return _enMemoria ??= uuidV4(_azar);
    }
  }
}

/// UUID v4 en minúsculas y forma canónica, como exige el contrato.
String uuidV4([Random? azar]) {
  final r = azar ?? Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40; // versión 4
  b[8] = (b[8] & 0x3f) | 0x80; // variante RFC 4122
  String hex(int i) => b[i].toRadixString(16).padLeft(2, '0');
  final h = [for (var i = 0; i < 16; i++) hex(i)].join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
      '${h.substring(16, 20)}-${h.substring(20)}';
}

final _uuid = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

bool esUuid(String valor) => _uuid.hasMatch(valor);

/// Una por app: el id se lee del teléfono una vez y se recuerda.
final identidadAnonimaProvider = Provider<IdentidadAnonima>(
  (ref) => IdentidadAnonima(),
);
