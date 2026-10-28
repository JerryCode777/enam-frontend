import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/version_de_la_app.dart';

/// Actualizar la app: la versión instalada y la mínima que pide el servidor.
///
/// Existe por lo que pasó en octubre de 2026: la mayoría de quienes topaban el
/// límite gratis en Android seguían en la 1.1.0 o la 1.1.1, que no tienen Play
/// Billing, y no había forma de decirles que actualizaran. Desde la 1.1.9:
///
/// - el servidor dice la versión mínima en `/config` (`minVersionAndroid`,
///   `minVersionIos`), y por debajo la app queda tras «Actualiza para
///   continuar», con la actualización inmediata de Play en Android;
/// - cada petición lleva `X-Version-App`, para que el servidor sepa con qué
///   versión habla sin depender de la analítica.

/// Compara dos versiones `x.y.z` por sus números: `-1`, `0` o `1`.
///
/// Ignora el `+build` y lo que no sea número; lo que falta cuenta como 0
/// (`1.1` es `1.1.0`). Como texto, `1.1.10` sería menor que `1.1.9`.
int compararVersiones(String a, String b) {
  List<int> partes(String v) => v
      .split('+')
      .first
      .split('.')
      .map((p) => int.tryParse(p.replaceAll(RegExp(r'\D'), '')) ?? 0)
      .toList();

  final pa = partes(a);
  final pb = partes(b);
  for (var i = 0; i < 3; i++) {
    final x = i < pa.length ? pa[i] : 0;
    final y = i < pb.length ? pb[i] : 0;
    if (x != y) return x < y ? -1 : 1;
  }
  return 0;
}

/// Si [instalada] está por debajo de [minima]. Sin alguna de las dos, no.
bool debajoDeLaMinima({required String? instalada, required String? minima}) {
  if (instalada == null || minima == null || minima.trim().isEmpty) {
    return false;
  }
  return compararVersiones(instalada, minima) < 0;
}

/// La versión mínima que el servidor pide para esta plataforma, o `null` si
/// no pide ninguna (o todavía no respondió).
class VersionMinima extends Notifier<String?> {
  @override
  String? build() => null;

  void fijar(String? minima) {
    final m = minima?.trim();
    state = m == null || m.isEmpty ? null : m;
  }
}

final versionMinimaProvider = NotifierProvider<VersionMinima, String?>(
  VersionMinima.new,
);

/// La versión instalada. Es un provider para que las pruebas la cambien.
final versionInstaladaProvider = Provider<String?>(
  (ref) => VersionDeLaApp.instalada,
);

/// Si la app tiene que actualizarse antes de seguir.
final actualizacionObligatoriaProvider = Provider<bool>(
  (ref) => debajoDeLaMinima(
    instalada: ref.watch(versionInstaladaProvider),
    minima: ref.watch(versionMinimaProvider),
  ),
);
