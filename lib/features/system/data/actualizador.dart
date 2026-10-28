import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';

/// La ficha de la app en cada tienda.
const fichaEnPlay =
    'https://play.google.com/store/apps/details?id=pe.jakstech.enam_app';
const fichaEnAppStore = 'https://apps.apple.com/app/id6797157623';

/// Habla con la tienda para actualizar la app.
///
/// En Android usa Play In-App Updates: la **inmediata** (pantalla completa de
/// Play, no se puede seguir sin actualizar) cuando la versión ya no sirve, y
/// la **flexible** (se descarga mientras se estudia) cuando solo hay una más
/// nueva. Si Play no la ofrece —una app instalada fuera de Play, o la versión
/// nueva todavía sin llegar al teléfono—, se abre la ficha. En iOS no existe
/// nada parecido: se abre App Store.
abstract interface class Actualizador {
  /// Actualiza ya: la inmediata de Play, o la ficha de la tienda.
  Future<void> actualizarYa();

  /// Si Play tiene una versión nueva, la descarga en segundo plano (Play
  /// pregunta antes). `true` si quedó descargada y lista para instalar.
  Future<bool> descargarSiHayNueva();

  /// Instala lo descargado. La app se reinicia.
  Future<void> instalarDescargada();
}

class ActualizadorDeTiendas implements Actualizador {
  bool get _android => !kIsWeb && Platform.isAndroid;

  @override
  Future<void> actualizarYa() async {
    if (_android) {
      try {
        final info = await InAppUpdate.checkForUpdate();
        if (info.updateAvailability == UpdateAvailability.updateAvailable &&
            info.immediateUpdateAllowed) {
          final r = await InAppUpdate.performImmediateUpdate();
          if (r == AppUpdateResult.success) return;
        }
      } catch (_) {
        // Sin Play (o Play sin la versión todavía): la ficha.
      }
    }
    await _abrir(_android ? fichaEnPlay : fichaEnAppStore);
  }

  @override
  Future<bool> descargarSiHayNueva() async {
    if (!_android) return false;
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.installStatus == InstallStatus.downloaded) return true;
      if (info.updateAvailability != UpdateAvailability.updateAvailable ||
          !info.flexibleUpdateAllowed) {
        return false;
      }
      return await InAppUpdate.startFlexibleUpdate() == AppUpdateResult.success;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> instalarDescargada() async {
    try {
      await InAppUpdate.completeFlexibleUpdate();
    } catch (_) {
      await _abrir(fichaEnPlay);
    }
  }

  Future<void> _abrir(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      // Sin tienda en el dispositivo: no hay a dónde mandar.
    }
  }
}

/// No hace nada: con datos de ejemplo y en las pruebas.
class ActualizadorNulo implements Actualizador {
  const ActualizadorNulo();

  @override
  Future<void> actualizarYa() async {}

  @override
  Future<bool> descargarSiHayNueva() async => false;

  @override
  Future<void> instalarDescargada() async {}
}

final actualizadorProvider = Provider<Actualizador>((ref) {
  if (AppConfig.useMocks) return const ActualizadorNulo();
  return ActualizadorDeTiendas();
});
