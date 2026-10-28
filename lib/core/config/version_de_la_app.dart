import 'package:package_info_plus/package_info_plus.dart';

/// La versión instalada, sin el número de compilación (`1.1.9`).
///
/// Se lee una vez, en `main`, antes de arrancar: así la cabecera de la primera
/// petición ya la lleva. `null` si no se pudo leer (en las pruebas, por
/// ejemplo): sin versión no hay cabecera ni bloqueo.
abstract final class VersionDeLaApp {
  static String? instalada;

  static Future<void> cargar() async {
    try {
      final v = (await PackageInfo.fromPlatform()).version.trim();
      instalada = v.isEmpty ? null : v;
    } catch (_) {
      instalada = null;
    }
  }
}
