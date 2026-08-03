import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/providers.dart';
import '../../catalog/domain/catalog_models.dart';
import '../domain/offline_models.dart';

/// Lo que la pantalla de descargas necesita saber, y lo que puede hacer.

/// Las áreas del catálogo cruzadas con lo que hay guardado en el teléfono.
///
/// La lista sale del catálogo y no de lo descargado: la pantalla tiene que
/// ofrecer **todas** las áreas, y marcar cuáles ya están. El tamaño y el número
/// de preguntas guardadas salen del resumen, que no descifra nada.
class DescargasNotifier extends AsyncNotifier<List<PaqueteEnPantalla>> {
  /// Descargas en marcha: área → progreso de 0 a 1, o `null` si el servidor no
  /// dice cuánto pesa.
  final Map<String, double?> _bajando = {};

  @override
  Future<List<PaqueteEnPantalla>> build() async {
    final arbol = await ref.watch(catalogProvider.future);
    final servicio = ref.watch(servicioOfflineProvider);
    if (servicio == null) return const [];

    final guardados = {
      for (final resumen in await servicio.resumenes()) resumen.areaId: resumen,
    };

    return [for (final area in arbol) _aPantalla(area, guardados[area.id])];
  }

  PaqueteEnPantalla _aPantalla(CatalogNode area, ResumenDePaquete? guardado) {
    final disponibles = area.preguntasDisponibles;
    final bajando = _bajando.containsKey(area.id);

    final estado = switch (guardado) {
      _ when bajando => EstadoDescarga.descargando,
      null => EstadoDescarga.noDescargada,
      // El catálogo dice cuántas preguntas hay hoy; el paquete, cuántas se
      // bajaron. Si el banco creció, hay algo nuevo que traer. Es la señal más
      // barata que existe: no hace falta un endpoint que diga «hay cambios».
      final g when g.total < disponibles => EstadoDescarga.actualizable,
      _ => EstadoDescarga.descargada,
    };

    return (
      areaId: area.id,
      nombre: area.nombre,
      estado: estado,
      guardadas: guardado?.total ?? 0,
      disponibles: disponibles,
      bytes: guardado?.bytes ?? 0,
      progreso: _bajando[area.id] ?? 0,
    );
  }

  /// Baja un área. Devuelve el error para que la pantalla lo cuente; no lo
  /// esconde en el estado, que aquí es la lista y no debe caerse entera porque
  /// una descarga falló.
  Future<Failure?> descargar(String areaId) async {
    final servicio = ref.read(servicioOfflineProvider);
    if (servicio == null) return null;
    if (_bajando.containsKey(areaId)) return null;

    _bajando[areaId] = null;
    _repintar();

    try {
      await servicio.descargar(
        areaId,
        // Crear la práctica lista arranca las 24 h de prueba, así que a quien
        // todavía no las gastó no se le tocan: descarga el banco y la reserva
        // se crea la primera vez que practique.
        //
        // Se **espera** a la suscripción en vez de mirar el valor que hubiera
        // en ese instante: si todavía estaba cargando, el valor es nulo y la
        // reserva no se creaba nunca. Si no se puede saber, no se reserva, que
        // es el lado que no le gasta el día a nadie.
        reservar: !(await _pruebaSinEmpezar() ?? true),
        progreso: (recibidos, total) {
          _bajando[areaId] = total > 0 ? (recibidos / total).clamp(0, 1) : null;
          _repintar();
        },
      );
      return null;
    } on Failure catch (e) {
      return e;
    } finally {
      _bajando.remove(areaId);
      if (ref.mounted) ref.invalidateSelf();
    }
  }

  Future<bool?> _pruebaSinEmpezar() async {
    try {
      return (await ref.read(subscriptionProvider.future)).pruebaSinEmpezar;
    } catch (_) {
      return null;
    }
  }

  Future<void> eliminar(String areaId) async {
    final servicio = ref.read(servicioOfflineProvider);
    if (servicio == null) return;

    await servicio.eliminar(areaId);
    ref.invalidateSelf();
  }

  /// Refresca la lista con lo que ya hay en memoria, sin volver a la base.
  ///
  /// Es lo que hace avanzar la barra: `invalidateSelf` en cada byte recibido
  /// dispararía una consulta a SQLite por fotograma.
  void _repintar() {
    // La descarga sigue aunque el usuario salga de la pantalla; si el provider
    // ya no está vivo, tocar su estado revienta.
    if (!ref.mounted) return;

    final actual = state.value;
    if (actual == null) return;
    state = AsyncData([
      for (final p in actual)
        if (_bajando.containsKey(p.areaId))
          (
            areaId: p.areaId,
            nombre: p.nombre,
            estado: EstadoDescarga.descargando,
            guardadas: p.guardadas,
            disponibles: p.disponibles,
            bytes: p.bytes,
            progreso: _bajando[p.areaId] ?? 0,
          )
        else
          p,
    ]);
  }
}

final descargasProvider =
    AsyncNotifierProvider<DescargasNotifier, List<PaqueteEnPantalla>>(
      DescargasNotifier.new,
    );

/// Qué áreas están guardadas en el teléfono.
///
/// Es lo que decide qué se puede practicar sin señal, así que las pantallas de
/// elección lo miran para poner el candado en lo demás. Vacío si no hay sesión
/// iniciada.
///
/// Va aparte de [descargasProvider] a propósito: aquel necesita el catálogo del
/// servidor para cruzarlo, y sin conexión eso es justo lo que puede faltar.
final areasDescargadasProvider = FutureProvider<Set<String>>((ref) async {
  final servicio = ref.watch(servicioOfflineProvider);
  if (servicio == null) return const {};

  // Se recuenta cuando cambia lo descargado. Se observa el estado y no el
  // futuro: aquel depende del catálogo del servidor, y si el catálogo falla
  // —que es justo lo que puede pasar sin señal— esperar su futuro haría fallar
  // también a esto, y la pantalla acabaría sin saber qué hay descargado
  // precisamente cuando más importa.
  ref.watch(descargasProvider);
  return {for (final r in await servicio.resumenes()) r.areaId};
});

/// Cuántas prácticas hay listas para usar sin señal.
final reservasProvider = FutureProvider<int>((ref) async {
  final servicio = ref.watch(servicioOfflineProvider);
  if (servicio == null) return 0;
  // Se recuenta cuando cambia lo descargado: descargar un área crea una.
  await ref.watch(descargasProvider.future);
  return servicio.cuantasReservas();
});

/// Estado de la bandeja de salida.
typedef EstadoDeSync = ({
  int pendientes,
  bool enMarcha,
  int aceptadas,
  List<ConflictoDeSync> conflictos,
});

/// Manda al servidor lo que se hizo sin conexión (RF-32).
///
/// Se dispara sola cuando vuelve la red. No hace falta que el usuario sepa que
/// existe: lo único que ve es que sus respuestas aparecen en el progreso.
class SincronizacionNotifier extends AsyncNotifier<EstadoDeSync> {
  @override
  Future<EstadoDeSync> build() async {
    final servicio = ref.watch(servicioOfflineProvider);
    if (servicio == null) {
      return (
        pendientes: 0,
        enMarcha: false,
        aceptadas: 0,
        conflictos: const <ConflictoDeSync>[],
      );
    }

    // El disparo va aquí y no en un widget: así ocurre esté donde esté el
    // usuario, y no solo si tiene abierta la pantalla de descargas.
    ref.listen(hayRedProvider, (_, siguiente) {
      if (siguiente.value == true) unawaited(sincronizar());
    });

    return (
      pendientes: await servicio.cuantasPendientes(),
      enMarcha: false,
      aceptadas: 0,
      conflictos: const <ConflictoDeSync>[],
    );
  }

  /// Vacía la bandeja. Silenciosa: si no hay red, se vuelve a intentar sola.
  Future<void> sincronizar() async {
    final servicio = ref.read(servicioOfflineProvider);
    final actual = state.value;
    if (servicio == null || actual == null || actual.enMarcha) return;

    state = AsyncData((
      pendientes: actual.pendientes,
      enMarcha: true,
      aceptadas: actual.aceptadas,
      conflictos: actual.conflictos,
    ));

    try {
      // Reponer crea sesiones, y crear una sesión arranca las 24 h de la
      // prueba (D-02). A quien todavía no las gastó no se le tocan.
      var reponer = false;
      try {
        reponer = !(await ref.read(
          subscriptionProvider.future,
        )).pruebaSinEmpezar;
      } catch (_) {
        reponer = false;
      }

      final resultado = await servicio.sincronizar(reponerReservas: reponer);

      state = AsyncData((
        pendientes: await servicio.cuantasPendientes(),
        enMarcha: false,
        aceptadas: resultado?.aceptadas ?? 0,
        conflictos: resultado?.conflictos ?? const <ConflictoDeSync>[],
      ));

      ref.invalidate(reservasProvider);

      if (resultado != null && resultado.aceptadas > 0) {
        // Lo que se estudió en el bus ya cuenta: el progreso y la racha tienen
        // que reflejarlo sin que el usuario tenga que reabrir la app.
        ref.invalidate(dashboardProvider);
        ref.invalidate(sesionesAbiertasProvider);
      }
    } on Failure {
      state = AsyncData((
        pendientes: actual.pendientes,
        enMarcha: false,
        aceptadas: 0,
        conflictos: const <ConflictoDeSync>[],
      ));
    }
  }
}

final sincronizacionProvider =
    AsyncNotifierProvider<SincronizacionNotifier, EstadoDeSync>(
      SincronizacionNotifier.new,
    );
