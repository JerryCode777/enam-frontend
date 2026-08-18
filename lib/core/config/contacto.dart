import 'package:url_launcher/url_launcher.dart';

/// Los canales de WhatsApp por donde se cierra el cobro (M10).
///
/// El bot no es parte de la app: es el canal donde se vende. La app da un día,
/// corta, y empuja aquí. Del otro lado se atiende, se cobra y se activa el plan.
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
  /// Asistente de WhatsApp: suscripciones, planes y pagos.
  static const String botNumero = '51906944489';

  /// Soporte humano (Jaks Tech SAC): problemas y dudas que necesitan persona.
  ///
  /// Lo pisa [aplicar] con lo que responda el servidor.
  static String soporteNumero = _soportePorDefecto;
  static const String _soportePorDefecto = '51964235124';

  /// Para mostrar: `+51 906 944 489`.
  static const String botVisible = '+51 906 944 489';

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

  /// Activar la cuenta: va al **soporte humano**, no al bot.
  ///
  /// Del otro lado se cobra y se activa a mano, así que quien contesta tiene
  /// que poder hacerlo. El bot todavía no cierra el cobro.
  static Uri activarPlan({String? codigoDescuento}) => _enlace(
    soporteNumero,
    codigoDescuento == null
        ? 'hola, quiero activar mi cuenta de ENAM Prep'
        : 'hola, quiero activar mi cuenta de ENAM Prep con mi código de '
              'descuento: $codigoDescuento',
  );

  static Uri soporte({String? mensaje}) => _enlace(soporteNumero, mensaje);

  /// Abre WhatsApp. Devuelve `false` si el dispositivo no puede.
  ///
  /// No lanza: quien llama está en medio de una pantalla de pago y un error sin
  /// capturar ahí es la peor forma de perder una venta.
  static Future<bool> abrir(Uri enlace) async {
    try {
      return await launchUrl(enlace, mode: LaunchMode.externalApplication);
    } on Exception {
      return false;
    }
  }
}
