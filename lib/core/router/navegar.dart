import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Ir a un destino de la app sin tener que saber cómo está montado el router.
///
/// ## El fallo que esto elimina
///
/// Las cuatro pestañas viven en un `StatefulShellRoute`, y cada una tiene su
/// propio `Navigator` con una `GlobalKey`. Apilar con `push` una ruta que vive
/// dentro de ese contenedor monta **un segundo Navigator con la misma llave**,
/// y Flutter muere con pantalla roja y sin botón de atrás. Ha pasado en el
/// temario, en «Seguir» del inicio, en el simulacro nacional y al empezar un
/// examen pasado: siempre el mismo error, siempre en un sitio nuevo.
///
/// Se arreglaba a mano cada vez, cambiando ese `push` por un `go`. Eso no es
/// una solución: es acordarse. Y la lista de qué ruta está dentro del
/// contenedor y cuál no cambia cada vez que se añade una pantalla.
///
/// ## Cómo lo resuelve
///
/// [irA] **le pregunta al router**. Con la ruta de destino busca su coincidencia
/// en la configuración real y mira si en el camino hay un `ShellRouteMatch`:
///
/// - **Vive en las pestañas** → `go`, que cambia de rama sin duplicar nada.
/// - **No vive ahí** —práctica, ajustes, exámenes pasados— → `push`, que la
///   apila encima y deja el botón de atrás donde corresponde.
///
/// Nadie tiene que recordar la lista, y no hay ninguna que mantener: la verdad
/// está en el árbol de rutas, que es el sitio donde de todas formas se declara.
///
/// `go` y `pushReplacement` siguen existiendo para lo que son —reemplazar la
/// pantalla actual, como al terminar de registrarse— y ninguno de los dos puede
/// provocar el fallo.
extension Navegar on BuildContext {
  void irA(String ruta, {Object? extra}) {
    if (_viveEnLasPestanas(this, ruta)) {
      go(ruta, extra: extra);
    } else {
      push<void>(ruta, extra: extra);
    }
  }

  /// Abre una pantalla **para que devuelva algo**, como el selector de áreas.
  ///
  /// Aquí no hay decisión que tomar: esperar un resultado obliga a apilar, y
  /// por eso mismo el destino no puede vivir en las pestañas. El `assert` lo
  /// deja claro en desarrollo en vez de esperar a la pantalla roja.
  Future<T?> irAPorUnResultado<T>(String ruta, {Object? extra}) {
    assert(
      !_viveEnLasPestanas(this, ruta),
      'De una ruta del contenedor de pestañas no se puede esperar un '
      'resultado: apilarla duplica el Navigator y tumba la app. Usa irA.',
    );
    return push<T>(ruta, extra: extra);
  }
}

bool _viveEnLasPestanas(BuildContext context, String ruta) {
  try {
    final coincidencias = GoRouter.of(
      context,
    ).configuration.findMatch(Uri.parse(ruta));

    return coincidencias.matches.any((m) => m is ShellRouteMatch);
  } catch (_) {
    // Una ruta que el router no reconoce no puede estar en el contenedor.
    // Apilar es lo prudente: acaba en la pantalla de «no encontrada» con su
    // botón de atrás, en vez de reemplazar lo que el usuario tenía.
    return false;
  }
}
