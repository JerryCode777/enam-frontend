import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../config/app_config.dart';
import '../network/api_client.dart';
import '../providers.dart';
import 'cola_de_eventos.dart';
import 'emisor_de_eventos.dart';
import 'identidad_anonima.dart';

/// Eventos del embudo que emite la app (contrato de eventos v1,
/// `enam-business/contrato/eventos.json`, que es el normativo).
///
/// Solo los de **cliente** que el contrato asigna a `ios` y `android`. Lo que
/// solo el servidor puede afirmar —cuenta creada, verificación, perfil,
/// prueba, primera práctica, pagos y accesos— lo emite el servidor, y si la
/// app lo mandara se rechazaría (`TIPO_NO_PERMITIDO`). `signup_verified` y
/// `profile_completed` estuvieron aquí y pasaron al servidor.
enum Evento {
  /// El formulario de registro se envía ya validado.
  signupStarted('signup_started'),

  /// Se abre una pantalla con planes o su renovación.
  plansViewed('plans_viewed'),

  /// iOS: se abre la hoja de compra de App Store. En Android el pago es en la
  /// web, y ahí lo emite la web.
  checkoutStarted('checkout_started');

  const Evento(this.nombre);

  /// El nombre del contrato, igual en todas las plataformas.
  final String nombre;
}

/// Qué propiedades admite cada evento en la app, y con qué valores: la lista
/// cerrada del contrato. Lo que no esté aquí no sale del teléfono.
const propiedadesDe = <Evento, Map<String, Set<String>>>{
  Evento.signupStarted: {
    'metodo': {'correo', 'google', 'apple'},
  },
  Evento.plansViewed: {
    'pantalla': {'planes', 'acceso_terminado', 'perfil', 'otra'},
  },
  Evento.checkoutStarted: {
    'plan_id': {'mensual', 'intensivo', 'semestral'},
    'medio': {'apple'},
  },
};

/// Las obligatorias. Sin ellas el servidor rechazaría el evento, así que ni se
/// encola.
const obligatoriasDe = <Evento, Set<String>>{
  Evento.signupStarted: {},
  Evento.plansViewed: {'pantalla'},
  Evento.checkoutStarted: {'plan_id', 'medio'},
};

/// En qué plataformas de la app existe cada evento.
const plataformasDe = <Evento, Set<String>>{
  Evento.signupStarted: {'ios', 'android'},
  Evento.plansViewed: {'ios', 'android'},
  Evento.checkoutStarted: {'ios'},
};

/// Versión del diseño, para comparar cohortes antes y después del rediseño.
const versionVisual = 'rediseno-2026-09';

/// Deja solo lo que el contrato admite para [evento], o `null` si falta una
/// obligatoria o el evento no es de esta plataforma.
///
/// Nunca pasa nada fuera de la lista: ni nombres, ni correos, ni tokens, ni
/// texto libre.
@visibleForTesting
Map<String, Object>? propiedadesValidas(
  Evento evento,
  Map<String, String> propiedades, {
  required String plataforma,
}) {
  if (!plataformasDe[evento]!.contains(plataforma)) return null;
  final admitidas = propiedadesDe[evento]!;
  final limpias = <String, Object>{
    for (final MapEntry(:key, :value) in propiedades.entries)
      if (admitidas[key]?.contains(value) ?? false) key: value,
  };
  if (!obligatoriasDe[evento]!.every(limpias.containsKey)) return null;
  return limpias;
}

/// La versión tal como la pide el contrato: la de pubspec (`1.0.0+7`), y en
/// cualquier compilación que no sea de tienda con `-dev` al final, para que
/// el servidor la cuente como prueba y no como gente.
@visibleForTesting
String versionApp({
  required String version,
  required String build,
  required bool release,
}) {
  final base = build.isEmpty ? version : '$version+$build';
  final v = base.isEmpty ? '0.0.0' : base;
  return release ? v : '$v-dev';
}

abstract interface class Analitica {
  void registrar(Evento evento, {Map<String, String> propiedades});

  /// Manda lo pendiente. La app lo llama al volver del segundo plano.
  Future<void> enviarPendientes();
}

/// No hace nada. Para las pruebas de pantallas y los modos sin servidor.
class AnaliticaNula implements Analitica {
  const AnaliticaNula();

  @override
  void registrar(Evento evento, {Map<String, String> propiedades = const {}}) {}

  @override
  Future<void> enviarPendientes() async {}
}

/// Escribe cada evento en la consola, ya filtrado. Para desarrollar con datos
/// de ejemplo, donde no hay servidor al que mandarlos.
class AnaliticaDeConsola implements Analitica {
  AnaliticaDeConsola({void Function(String)? escribir, String? plataforma})
    : _escribir = escribir ?? debugPrint,
      _plataforma = plataforma ?? plataformaDeLaApp;

  final void Function(String) _escribir;
  final String _plataforma;

  @override
  void registrar(Evento evento, {Map<String, String> propiedades = const {}}) {
    final limpias = propiedadesValidas(
      evento,
      propiedades,
      plataforma: _plataforma,
    );
    if (limpias != null) _escribir('[evento] ${evento.nombre} $limpias');
  }

  @override
  Future<void> enviarPendientes() async {}
}

/// La de verdad: encola en el teléfono y manda por lotes a `POST /eventos`.
///
/// Registrar es instantáneo y no espera a la red. Lo encolado se manda poco
/// después, al volver del segundo plano y al recuperar la conexión, y si no
/// se puede, sigue en la cola hasta siete días.
class AnaliticaConCola implements Analitica {
  AnaliticaConCola({
    required ColaDeEventos cola,
    required EmisorDeEventos emisor,
    required String plataforma,
    DateTime Function()? reloj,
    Duration demora = const Duration(seconds: 2),
  }) : _cola = cola,
       _emisor = emisor,
       _plataforma = plataforma,
       _reloj = reloj ?? DateTime.now,
       _demora = demora;

  final ColaDeEventos _cola;
  final EmisorDeEventos _emisor;
  final String _plataforma;
  final DateTime Function() _reloj;
  final Duration _demora;
  Timer? _programado;

  /// Lo que falta por guardar. Enviar espera a que termine, para no mandar un
  /// lote sin el último evento.
  Future<void> _guardando = Future.value();

  @override
  void registrar(Evento evento, {Map<String, String> propiedades = const {}}) {
    final limpias = propiedadesValidas(
      evento,
      propiedades,
      plataforma: _plataforma,
    );
    if (limpias == null) return;

    _guardando = _guardando.then(
      (_) => _cola.agregar((
        eventoId: uuidV4(),
        tipo: evento.nombre,
        ocurridoEn: _reloj().toUtc(),
        propiedades: limpias,
      )),
    );
    _programado?.cancel();
    _programado = Timer(_demora, () => unawaited(enviarPendientes()));
  }

  @override
  Future<void> enviarPendientes() async {
    try {
      await _guardando;
      await _emisor.vaciar();
    } catch (_) {}
  }
}

/// Las propiedades comunes del sobre: plataforma, versión de la app, versión
/// visual y `anonimo_id`. **Nunca `usuario_id`**: lo pone el servidor.
Future<Map<String, Object>> comunesDeLaApp(IdentidadAnonima identidad) async {
  var version = '0.0.0';
  try {
    final info = await PackageInfo.fromPlatform();
    version = versionApp(
      version: info.version,
      build: info.buildNumber,
      release: kReleaseMode,
    );
  } catch (_) {
    version = versionApp(version: '', build: '', release: false);
  }
  return {
    'plataforma': plataformaDeLaApp,
    'version_app': version,
    'version_visual': versionVisual,
    'anonimo_id': await identidad.id(),
  };
}

final colaDeEventosProvider = Provider<ColaDeEventos>(
  (ref) => ColaDeEventos(AlmacenDeColaPrefs()),
);

final transporteDeEventosProvider = Provider<TransporteDeEventos>(
  (ref) => TransporteDio(),
);

final analiticaProvider = Provider<Analitica>((ref) {
  // Con datos de ejemplo no hay servidor: a la consola.
  if (AppConfig.useMocks) return AnaliticaDeConsola();

  final tokens = ref.watch(tokenStorageProvider);
  final cliente = ref.watch(apiClientProvider);
  final identidad = ref.watch(identidadAnonimaProvider);

  return AnaliticaConCola(
    cola: ref.watch(colaDeEventosProvider),
    plataforma: plataformaDeLaApp,
    emisor: EmisorDeEventos(
      cola: ref.watch(colaDeEventosProvider),
      transporte: ref.watch(transporteDeEventosProvider),
      comunes: () => comunesDeLaApp(identidad),
      // Con sesión, el token; si venció, se renueva antes de mandar. Sin
      // sesión, el evento sale anónimo.
      token: () async {
        if (!await tokens.hasSession()) return null;
        if (await tokens.isExpired()) return cliente.renovarSesion();
        return tokens.readAccessToken();
      },
      renovarToken: cliente.renovarSesion,
    ),
  );
});
