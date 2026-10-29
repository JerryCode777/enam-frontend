import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/recordatorios/presentation/pre_pantalla_de_recordatorio.dart';
import '../../features/recordatorios/presentation/recordatorios_controller.dart';
import '../analitica/analitica.dart';
import '../domain/blueprint.dart';
import '../providers.dart';

/// Después de qué buen resultado se pidió (`momento` de `valoracion_pedida`).
enum MomentoDeValoracion {
  practica('practica'),
  simulacro('simulacro'),
  examenPasado('examen_pasado'),
  clase('clase');

  const MomentoDeValoracion(this.codigo);

  final String codigo;
}

/// Pide valorar la app en la tienda, en el momento bueno. Copiado de Rumbo
/// (`nucleo/avisos/pedir_valoracion.dart`).
///
/// El momento bueno es justo después de un buen resultado: quien acaba de
/// sacar un 80 % está contento con la app; quien acaba de fallar la mitad, no.
/// Pedirlo mal no solo molesta: baja la nota media, que es lo que se quería
/// subir (en Play había una sola reseña, de 1★, de la 1.1.1).
///
/// Se llama **directo** al diálogo del sistema. Nada de un «¿te gusta la
/// app?» propio que mande a la tienda solo a los contentos: Google Play y
/// Apple lo prohíben (*review gating*), y tampoco va ningún diálogo nuestro
/// antes del nativo.
///
/// Además del buen resultado, solo si:
/// - la cuenta tiene [diasDeCuenta] días o más,
/// - lleva [sesionesMinimas] sesiones terminadas o más,
/// - pasaron [diasEntrePeticiones] días desde la última vez que se pidió.
class PedirValoracion {
  PedirValoracion({InAppReview? tienda, Analitica? analitica})
    : _tienda = tienda,
      _analitica = analitica;

  /// Se sustituye en las pruebas, que no pueden abrir el diálogo del sistema.
  final InAppReview? _tienda;
  final Analitica? _analitica;

  InAppReview get _valoracion => _tienda ?? InAppReview.instance;

  static const _claveUltima = 'valoracion_pedida_ms';
  static const _claveSesiones = 'valoracion_sesiones_terminadas';
  static const _claveDesde = 'valoracion_desde_ms';

  /// El id de ENAM Prep en App Store, para abrir su ficha.
  static const appStoreId = '6797157623';

  /// Acierto mínimo de una práctica para contar como buen resultado, como en
  /// Rumbo.
  static const aciertoMinimo = 0.70;

  /// Una práctica más corta no dice mucho: 3 de 4 es suerte.
  static const preguntasMinimas = 10;

  static const diasDeCuenta = 3;
  static const sesionesMinimas = 3;

  /// Un mes entre peticiones. El sistema tiene su propio tope y puede no
  /// enseñar nada, pero eso no se sabe desde aquí: la cuenta se lleva igual.
  static const diasEntrePeticiones = 30;

  /// Una práctica es buen resultado con [aciertoMinimo] de acierto o más en
  /// [preguntasMinimas] preguntas o más.
  static bool practicaBuena({required int correctas, required int total}) =>
      total >= preguntasMinimas && correctas / total >= aciertoMinimo;

  /// Un simulacro o un examen pasado, si aprueba (RN-01).
  static bool notaBuena(double nota) => Blueprint.isPassing(nota);

  /// Anota una sesión terminada, una vez por [sessionId] aunque se vuelva a
  /// abrir su resumen. Va siempre, también tras un mal resultado: cuenta para
  /// el mínimo de [sesionesMinimas].
  Future<void> anotarSesionTerminada(
    String sessionId, {
    DateTime? ahora,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await _anotarDesde(prefs, ahora ?? DateTime.now());
    final ids = prefs.getStringList(_claveSesiones) ?? const <String>[];
    if (ids.contains(sessionId)) return;
    // Basta con saber que pasó de [sesionesMinimas]: no hace falta guardar
    // todas.
    final nuevos = [...ids, sessionId];
    await prefs.setStringList(
      _claveSesiones,
      nuevos.length > 20 ? nuevos.sublist(nuevos.length - 20) : nuevos,
    );
  }

  /// Pide la valoración si toca. Devuelve si se llegó a pedir; falso es lo
  /// normal, casi siempre no toca.
  ///
  /// [cuentaCreada] es la fecha de alta que manda el servidor. Sin ella se usa
  /// el primer día que esta instalación vio una sesión terminada, que nunca
  /// es antes del alta: se queda corto, nunca largo.
  Future<bool> siTocara({
    required MomentoDeValoracion momento,
    required bool buenResultado,
    DateTime? cuentaCreada,
    DateTime? ahora,
  }) async {
    if (!buenResultado) return false;

    final momentoActual = ahora ?? DateTime.now();
    final prefs = await SharedPreferences.getInstance();

    final desde = cuentaCreada ?? await _anotarDesde(prefs, momentoActual);
    if (momentoActual.difference(desde).inDays < diasDeCuenta) return false;

    final sesiones = prefs.getStringList(_claveSesiones)?.length ?? 0;
    if (sesiones < sesionesMinimas) return false;

    final ultima = prefs.getInt(_claveUltima);
    if (ultima != null) {
      final dias = momentoActual
          .difference(DateTime.fromMillisecondsSinceEpoch(ultima))
          .inDays;
      if (dias < diasEntrePeticiones) return false;
    }

    if (!await _valoracion.isAvailable()) return false;

    // Se anota antes y aunque el sistema no enseñe nada: si no, se volvería a
    // intentar en cada buen resultado hasta que lo enseñara.
    await prefs.setInt(_claveUltima, momentoActual.millisecondsSinceEpoch);
    _analitica?.registrar(
      Evento.valoracionPedida,
      propiedades: {'momento': momento.codigo},
    );
    await _valoracion.requestReview();
    return true;
  }

  /// La ficha de la app en la tienda, desde Ajustes: ahí quien quiera la
  /// califica cuando quiera, bien o mal.
  Future<void> abrirFicha() =>
      _valoracion.openStoreListing(appStoreId: appStoreId);

  Future<DateTime> _anotarDesde(SharedPreferences prefs, DateTime ahora) async {
    final guardado = prefs.getInt(_claveDesde);
    if (guardado != null) return DateTime.fromMillisecondsSinceEpoch(guardado);
    await prefs.setInt(_claveDesde, ahora.millisecondsSinceEpoch);
    return ahora;
  }
}

final pedirValoracionProvider = Provider<PedirValoracion>(
  (ref) => PedirValoracion(analitica: ref.watch(analiticaProvider)),
);

/// Anota la sesión terminada y, si fue un buen resultado, pide la valoración.
/// Sin esperar: la pantalla de resultados no depende de esto, y un fallo de la
/// tienda no puede romperla.
void alTerminarSesion(
  WidgetRef ref, {
  required String sessionId,
  required MomentoDeValoracion momento,
  required bool buenResultado,
}) {
  final valoracion = ref.read(pedirValoracionProvider);
  final cuentaCreada = ref.read(currentUserProvider)?.creadoEn;
  unawaited(() async {
    try {
      await valoracion.anotarSesionTerminada(sessionId);
      await valoracion.siTocara(
        momento: momento,
        buenResultado: buenResultado,
        cuentaCreada: cuentaCreada,
      );
    } on Object {
      // La tienda puede fallar o no estar; da igual: no se pide.
    }
  }());
}

/// Si [finalizadaEn] es de hace un momento. Un resumen que se vuelve a abrir
/// días después desde el historial no es «justo después» de nada. Sin fecha,
/// se da por recién terminada: el resumen se abre al terminar.
bool recienTerminada(DateTime? finalizadaEn, {DateTime? ahora}) =>
    finalizadaEn == null ||
    (ahora ?? DateTime.now()).difference(finalizadaEn).inMinutes < 15;

/// Anota la sesión y pide la valoración una vez, al aparecer la pantalla de
/// resultados. Como `SonarAlAparecer`: envuelve el contenido y no pinta nada.
class ValoracionAlAparecer extends ConsumerStatefulWidget {
  const ValoracionAlAparecer({
    required this.sessionId,
    required this.momento,
    required this.buenResultado,
    required this.child,
    this.finalizadaEn,
    super.key,
  });

  final String sessionId;
  final MomentoDeValoracion momento;
  final bool buenResultado;
  final DateTime? finalizadaEn;
  final Widget child;

  @override
  ConsumerState<ValoracionAlAparecer> createState() =>
      _ValoracionAlAparecerState();
}

class _ValoracionAlAparecerState extends ConsumerState<ValoracionAlAparecer> {
  @override
  void initState() {
    super.initState();
    // Tras el primer cuadro: que el resultado se vea antes que el diálogo.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final recien = recienTerminada(widget.finalizadaEn);
      final recordatorios = ref.read(recordatoriosProvider.notifier);

      // La primera sesión terminada es cuando se ofrece el recordatorio. Esa
      // vez no se pide además la valoración: dos diálogos seguidos son uno de
      // más (la sesión igual se anota).
      var ofrecido = false;
      if (recien) {
        unawaited(recordatorios.sesionTerminada());
        if (await recordatorios.debePreguntar() && mounted) {
          ofrecido = true;
          await ofrecerRecordatorio(context, ref);
        }
      }
      if (!mounted) return;
      alTerminarSesion(
        ref,
        sessionId: widget.sessionId,
        momento: widget.momento,
        buenResultado: widget.buenResultado && recien && !ofrecido,
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
