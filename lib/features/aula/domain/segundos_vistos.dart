/// Los segundos **distintos** que se vieron de una clase.
///
/// Es lo que el servidor usa para marcarla completada al 90 %, así que
/// adelantar hasta el final no puede contar como vista. Igual que la web
/// (`lib/segundosVistos.ts`):
///
/// - Se suma solo reproduciendo, y entre dos marcas seguidas de como mucho
///   2 s: un salto mayor es un adelanto, no algo visto.
/// - Al saltar o pausar se corta la racha ([cortar]).
/// - Lo visto en visitas anteriores llega como un total, sin saber qué
///   segundos fueron; se suponen los primeros.
class SegundosVistos {
  SegundosVistos({int previos = 0}) {
    for (var s = 0; s < previos; s++) {
      _vistos.add(s);
    }
  }

  final _vistos = <int>{};
  int? _ultimo;

  int get total => _vistos.length;

  /// Anota la posición [t] del video.
  void registrar(Duration t, {required bool reproduciendo}) {
    final ahora = t.inSeconds;
    final ultimo = _ultimo;
    if (reproduciendo && ultimo != null) {
      final salto = ahora - ultimo;
      if (salto >= 0 && salto <= 2) {
        for (var s = ultimo; s <= ahora; s++) {
          _vistos.add(s);
        }
      }
    }
    _ultimo = ahora;
  }

  /// La siguiente marca no continúa la anterior: hubo un salto o una pausa.
  void cortar() => _ultimo = null;
}

/// Si con [segundosVistos] de [duracionS] la clase ya cuenta como vista.
bool completa(int segundosVistos, int duracionS) =>
    duracionS > 0 && segundosVistos >= 0.9 * duracionS;

/// «45 s», «8 min», «1 h 20 min», «2 h»: minutos redondeados, como la web.
String duracionCorta(int segundos) {
  if (segundos < 60) return '$segundos s';
  final minutos = (segundos / 60).round();
  if (minutos < 60) return '$minutos min';
  final h = minutos ~/ 60;
  final m = minutos % 60;
  return m == 0 ? '$h h' : '$h h $m min';
}

/// «1 clase», «3 clases».
String clasesEnTexto(int n) => n == 1 ? '1 clase' : '$n clases';

/// «4:05» o «1:02:09», para «sigues donde lo dejaste».
String posicionEnTexto(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$s' : '$m:$s';
}
