import 'package:url_launcher/url_launcher.dart';

/// Los canales de WhatsApp por donde se cierra el cobro (M10).
///
/// El bot no es parte de la app: es el canal donde se vende. La app da un día,
/// corta, y empuja aquí. Del otro lado se atiende, se cobra y se activa el plan.
///
/// > **Provisional.** Estos son los números de Rumbo SERUMS, la app hermana.
/// > ENAM todavía no tiene los suyos, y hasta que los tenga estos enlaces
/// > llevan a un canal que no conoce a estos usuarios.
/// > TODO(negocio): reemplazar por los números de ENAM antes de publicar.
///
/// Los números viven aquí y no repartidos por las pantallas: cuando cambien —y
/// van a cambiar— se toca un archivo, no ocho.
abstract final class Contacto {
  /// Asistente de WhatsApp: suscripciones, planes y pagos.
  static const String botNumero = '51906944489';

  /// Soporte humano (Jaks Tech SAC): problemas y dudas que necesitan persona.
  static const String soporteNumero = '51987391203';

  /// Para mostrar: `+51 906 944 489`.
  static const String botVisible = '+51 906 944 489';

  static const String soporteVisible = '+51 987 391 203';

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
