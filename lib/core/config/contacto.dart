import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:url_launcher/url_launcher.dart';

/// El WhatsApp de soporte.
///
/// **Ya no es un canal de cobro.** Lo fue: por aquí se pagaba con Yape y se
/// activaba el plan a mano. Ahora se cobra con App Store en iPhone y con
/// Mercado Pago en la web, y el acceso se activa solo. WhatsApp queda para
/// ayudar: un pago que no se refleja, una duda, un reporte.
///
/// El número de soporte lo **sirve el servidor** (`GET /config`) y lo que hay
/// aquí es solo el valor de respaldo. Es lo que evita que cambiar de línea
/// obligue a publicar en dos tiendas y esperar sus revisiones: se toca una
/// variable de entorno y la app lo recoge en el siguiente arranque.
///
/// El respaldo es el número REAL y no una cadena vacía. Si la petición falla
/// —sin red, servidor caído, primer arranque en modo avión— el botón de ayuda
/// tiene que seguir llevando a alguien. Un botón de soporte que no lleva a
/// ningún sitio es peor que uno con un número viejo.
///
/// Los números viven aquí y no repartidos por las pantallas: cuando cambien —y
/// van a cambiar— se toca un archivo, no ocho.
abstract final class Contacto {
  /// Soporte humano (operador de ENAM Prep; PENDIENTE(titular): pasa a
  /// AidaSoft): problemas y dudas que necesitan persona.
  ///
  /// Lo pisa [aplicar] con lo que responda el servidor.
  static String soporteNumero = _soportePorDefecto;
  static const String _soportePorDefecto = '51964235124';

  static String soporteVisible = _soporteVisiblePorDefecto;
  static const String _soporteVisiblePorDefecto = '+51 964 235 124';

  /// Reemplaza el número de soporte con el que sirve el servidor.
  ///
  /// Ignora lo que venga vacío o sin dígitos suficientes: una configuración a
  /// medias en el servidor no puede dejar la app sin canal de ayuda, y el
  /// respaldo compilado siempre es un número que funciona.
  static void aplicar({required String numero, required String visible}) {
    final digitos = numero.replaceAll(RegExp(r'\D'), '');
    if (digitos.length < 8) return;

    soporteNumero = digitos;
    soporteVisible = visible.trim().isEmpty ? '+$digitos' : visible.trim();
  }

  /// Vuelve al valor compilado. Solo para las pruebas: sin esto, un test que
  /// aplique un número se lo deja puesto al siguiente.
  static void restablecer() {
    soporteNumero = _soportePorDefecto;
    soporteVisible = _soporteVisiblePorDefecto;
  }

  /// Enlace `wa.me` con el mensaje ya escrito.
  ///
  /// Es un enlace, no una API: funciona sin integración de ningún tipo, que es
  /// exactamente lo que hace la app hermana.
  static Uri _enlace(String numero, String? mensaje) {
    final base = 'https://wa.me/$numero';
    if (mensaje == null || mensaje.isEmpty) return Uri.parse(base);
    return Uri.parse('$base?text=${Uri.encodeComponent(mensaje)}');
  }

  /// Pedir ayuda con el acceso o la suscripción.
  ///
  /// Solo ayuda, no cobro: el mensaje no pide activar nada, porque el pago y la
  /// activación ya no pasan por aquí.
  static Uri ayudaConElAcceso() =>
      _enlace(soporteNumero, 'hola, necesito ayuda con mi acceso a ENAM Prep');

  static Uri soporte({String? mensaje}) => _enlace(soporteNumero, mensaje);

  /// Abre WhatsApp. Devuelve `false` si el dispositivo no puede.
  ///
  /// No lanza: quien llama está en medio de una pantalla de pago y un error sin
  /// capturar ahí es la peor forma de perder una venta.
  static Future<bool> abrir(Uri enlace) async {
    try {
      return await lanzador(enlace);
    } on Exception {
      return false;
    }
  }

  /// Lo que de verdad abre el enlace. Se puede sustituir en las pruebas, donde
  /// no hay WhatsApp ni plugin de sistema al que llamar.
  @visibleForTesting
  static Future<bool> Function(Uri) lanzador = _lanzar;

  static Future<bool> _lanzar(Uri enlace) =>
      launchUrl(enlace, mode: LaunchMode.externalApplication);
}
