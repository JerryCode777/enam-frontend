import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Eventos del recorrido comercial (plan de rediseño §12).
///
/// **No hay ningún proveedor de analítica conectado.** Esta es la interfaz:
/// la app ya dice qué pasó y dónde, y cuando el negocio elija proveedor basta
/// con una implementación nueva de [Analitica]. Hasta entonces los eventos van
/// a [AnaliticaNula] (release) o a la consola (desarrollo), y **no cuentan
/// como medición**: nadie los recibe.
///
/// Solo están los que la app puede afirmar por sí misma. Los que dependen de
/// una confirmación del servidor —primera práctica terminada, pago confirmado,
/// acceso concedido— los tiene que emitir el backend, que es quien lo sabe y
/// quien puede deduplicar por cuenta. Ver `diseno/rediseno/EVENTOS.md`.
enum Evento {
  /// Se envió el formulario de registro con datos válidos.
  signupStarted('signup_started'),

  /// El código del correo se aceptó y la cuenta quedó activa.
  signupVerified('signup_verified'),

  /// Se guardó el perfil obligatorio y el router deja pasar.
  profileCompleted('profile_completed'),

  /// Se abrió una pantalla que presenta planes o su renovación.
  plansViewed('plans_viewed');

  const Evento(this.nombre);

  /// El nombre del diccionario, igual en web, app y backend.
  final String nombre;
}

/// Lo que se puede adjuntar a un evento.
///
/// Una lista cerrada a propósito: nunca nombres, correos, tokens ni texto de
/// preguntas (plan §12). Lo que no esté aquí se descarta antes de salir.
const propiedadesPermitidas = {
  'plataforma',
  'version_visual',
  'pantalla',
  'origen',
};

/// Versión del diseño, para comparar cohortes antes y después del rediseño.
const versionVisual = 'rediseno-2026-09';

abstract interface class Analitica {
  void registrar(Evento evento, {Map<String, String> propiedades});
}

/// No hace nada. Es la que corre en release mientras no haya proveedor.
class AnaliticaNula implements Analitica {
  const AnaliticaNula();

  @override
  void registrar(Evento evento, {Map<String, String> propiedades = const {}}) {}
}

/// Escribe cada evento en la consola, ya filtrado. Solo en desarrollo: sirve
/// para comprobar que los disparadores están donde el diccionario dice.
class AnaliticaDeConsola implements Analitica {
  AnaliticaDeConsola({void Function(String)? escribir})
    : _escribir = escribir ?? debugPrint;

  final void Function(String) _escribir;

  @override
  void registrar(Evento evento, {Map<String, String> propiedades = const {}}) {
    _escribir('[evento] ${evento.nombre} ${filtrar(propiedades)}');
  }
}

/// Deja solo las propiedades permitidas y añade las comunes.
@visibleForTesting
Map<String, String> filtrar(Map<String, String> propiedades) => {
  for (final MapEntry(:key, :value) in propiedades.entries)
    if (propiedadesPermitidas.contains(key)) key: value,
  'plataforma': defaultTargetPlatform.name,
  'version_visual': versionVisual,
};

final analiticaProvider = Provider<Analitica>((ref) {
  if (kReleaseMode) return const AnaliticaNula();
  return AnaliticaDeConsola();
});
