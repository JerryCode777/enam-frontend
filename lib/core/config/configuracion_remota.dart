import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

import '../network/api_client.dart';
import 'api_endpoints.dart';
import 'contacto.dart';

/// Trae del servidor los datos del negocio que pueden cambiar sin previo aviso.
///
/// Hoy es solo el número de atención, y esa es la razón de existir: cambiar de
/// línea telefónica no puede obligar a publicar una versión en dos tiendas y
/// esperar a que las revisen. Se toca una variable de entorno y la app lo
/// recoge en el siguiente arranque.
///
/// **Nunca lanza y nunca bloquea.** Si el servidor no responde, la app arranca
/// igual con los valores compilados, que son números que funcionan. Un fallo al
/// leer una preferencia no puede impedir que alguien entre a estudiar.
class ConfiguracionRemota {
  ConfiguracionRemota(this._client, {this.alLeerVersionMinima});

  final ApiClient _client;

  /// Recibe la versión mínima de esta plataforma (`minVersionAndroid` o
  /// `minVersionIos`), o `null` si el servidor no pide ninguna.
  final void Function(String? minima)? alLeerVersionMinima;

  Future<void> cargar() async {
    try {
      final data = await _client.get<Map<String, dynamic>>(ApiEndpoints.config);

      Contacto.aplicar(
        numero: data['whatsappSoporte'] as String? ?? '',
        visible: data['whatsappSoporteVisible'] as String? ?? '',
      );

      final ios = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
      final minima = data[ios ? 'minVersionIos' : 'minVersionAndroid'];
      alLeerVersionMinima?.call(minima is String ? minima : null);
    } catch (_) {
      // A propósito en silencio: no hay nada que el usuario pueda hacer, y los
      // valores compilados ya sirven. Avisarle de esto sería ruido.
    }
  }
}
