import 'package:enam_app/core/security/cifrado_local.dart';
import 'package:enam_app/core/storage/base_local.dart';
import 'package:enam_app/features/offline/data/almacen_offline.dart';
import 'package:enam_app/features/offline/domain/offline_models.dart';
import 'package:enam_app/features/session/domain/session_models.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Piezas compartidas por las pruebas del modo sin conexión.
///
/// La base es **SQLite de verdad**, en memoria: las pruebas ejercitan el mismo
/// SQL que corre en el teléfono. Con un doble que guarda en un `Map` pasarían
/// igual estando el esquema mal.

/// El Keychain, en un mapa.
class AlmacenDeLlavesFalso implements AlmacenDeLlaves {
  final Map<String, String> datos = {};

  @override
  Future<String?> leer(String nombre) async => datos[nombre];

  @override
  Future<void> guardar(String nombre, String valor) async =>
      datos[nombre] = valor;

  @override
  Future<void> borrar(String nombre) async => datos.remove(nombre);
}

/// Una base en memoria, lista para usar. Llamar dentro de `setUp`.
BaseLocal baseEnMemoria() {
  sqfliteFfiInit();
  return BaseLocal(
    factory: databaseFactoryFfi,
    ruta: inMemoryDatabasePath,
  );
}

/// El almacén completo sobre una base en memoria.
({AlmacenOffline almacen, BaseLocal base}) almacenEnMemoria() {
  final base = baseEnMemoria();
  return (
    almacen: AlmacenOfflineSqlite(
      base: base,
      cifrado: CifradoLocal(almacen: AlmacenDeLlavesFalso()),
    ),
    base: base,
  );
}

/// Una pregunta con su clave, como llegan en un paquete offline.
Question preguntaDePrueba(String id, {String correcta = 'b'}) => Question(
  id: id,
  enunciado: 'Varón de 62 años con dolor torácico opresivo de 2 horas ($id)',
  areaId: 'medicina',
  explicacion: 'La elevación del ST en cara inferior obliga a reperfundir.',
  opciones: [
    for (final letra in const ['a', 'b', 'c', 'd'])
      QuestionOption(
        id: '$id-$letra',
        texto: 'Alternativa $letra',
        esCorrecta: letra == correcta,
      ),
  ],
);

/// Una sesión de práctica con [cuantas] preguntas, como la devuelve el servidor.
StudySession sesionDePrueba({
  String id = 'sesion-1',
  int cuantas = 3,
  SessionType tipo = SessionType.practica,
}) => StudySession(
  id: id,
  tipo: tipo,
  estado: SessionStatus.enCurso,
  iniciadaEn: DateTime(2026, 7, 30, 9),
  preguntas: [for (var i = 1; i <= cuantas; i++) preguntaDePrueba('$id-p$i')],
);

/// El almacén en un mapa, para las pruebas de pantalla.
///
/// **Por qué existe teniendo el de SQLite.** Dentro de `testWidgets` el reloj
/// es falso, y una consulta a SQLite es E/S de verdad: su futuro no se resuelve
/// nunca por mucho que se bombee, así que la prueba se queda colgada. Este
/// doble responde en el mismo turno y deja probar la pantalla.
///
/// El SQL de verdad se prueba aparte, en `almacen_offline_test.dart`, contra
/// SQLite real.
class AlmacenEnMemoria implements AlmacenOffline {
  final Map<String, Map<String, PaqueteOffline>> _paquetes = {};
  final Map<String, DateTime> _descargadoEn = {};
  final Map<String, Map<String, SesionLocal>> _sesiones = {};
  final Map<String, List<RespuestaPendiente>> _pendientes = {};
  final Map<String, List<String>> _porEnviar = {};
  final Map<String, List<String>> _porRegistrar = {};
  final Map<String, List<dynamic>> _catalogo = {};

  Map<String, PaqueteOffline> _deUsuario(String id) =>
      _paquetes.putIfAbsent(id, () => {});

  @override
  Future<void> guardarPaquete(String usuarioId, PaqueteOffline paquete) async {
    _deUsuario(usuarioId)[paquete.areaId] = paquete;
    _descargadoEn['$usuarioId/${paquete.areaId}'] = DateTime.now();
  }

  @override
  Future<List<ResumenDePaquete>> resumenes(String usuarioId) async => [
    for (final p in _deUsuario(usuarioId).values)
      (
        areaId: p.areaId,
        generadoEn: p.generadoEn,
        descargadoEn: _descargadoEn['$usuarioId/${p.areaId}'] ?? DateTime.now(),
        total: p.total,
        // Un tamaño verosímil: lo que importa en pantalla es que no sea cero.
        bytes: p.total * 1200,
      ),
  ];

  @override
  Future<PaqueteOffline?> paquete(String usuarioId, String areaId) async =>
      _deUsuario(usuarioId)[areaId];

  @override
  Future<void> borrarPaquete(String usuarioId, String areaId) async =>
      _deUsuario(usuarioId).remove(areaId);

  @override
  Future<void> guardarSesion(
    String usuarioId, {
    required String areaId,
    required EstadoSesionLocal estado,
    required StudySession sesion,
    DateTime? creadaEn,
  }) async {
    _sesiones.putIfAbsent(usuarioId, () => {})[sesion.id] = (
      areaId: areaId,
      estado: estado,
      creadaEn: creadaEn ?? DateTime.now(),
      sesion: sesion,
    );
  }

  @override
  Future<SesionLocal?> sesion(String usuarioId, String sesionId) async =>
      _sesiones[usuarioId]?[sesionId];

  @override
  Future<List<SesionLocal>> sesiones(
    String usuarioId, {
    EstadoSesionLocal? estado,
  }) async => [
    for (final s in (_sesiones[usuarioId] ?? {}).values)
      if (estado == null || s.estado == estado) s,
  ];

  @override
  Future<void> borrarSesion(String usuarioId, String sesionId) async =>
      _sesiones[usuarioId]?.remove(sesionId);

  @override
  Future<void> encolar(String usuarioId, RespuestaPendiente respuesta) async {
    final cola = _pendientes.putIfAbsent(usuarioId, () => []);
    cola.removeWhere(
      (r) =>
          r.sesionId == respuesta.sesionId &&
          r.preguntaId == respuesta.preguntaId,
    );
    cola.add(respuesta);
    cola.sort((a, b) => a.respondidaEn.compareTo(b.respondidaEn));
  }

  @override
  Future<List<RespuestaPendiente>> pendientes(String usuarioId) async =>
      List.of(_pendientes[usuarioId] ?? const []);

  @override
  Future<int> cuantasPendientes(String usuarioId) async =>
      (_pendientes[usuarioId] ?? const []).length;

  @override
  Future<void> quitarPendientes(
    String usuarioId,
    String sesionId,
    Iterable<String> preguntaIds,
  ) async {
    _pendientes[usuarioId]?.removeWhere(
      (r) => r.sesionId == sesionId && preguntaIds.contains(r.preguntaId),
    );
  }

  @override
  Future<void> marcarPorEnviar(
    String usuarioId,
    String sesionId,
    DateTime cuando,
  ) async {
    final cola = _porEnviar.putIfAbsent(usuarioId, () => []);
    if (!cola.contains(sesionId)) cola.add(sesionId);
  }

  @override
  Future<List<String>> porEnviar(String usuarioId) async =>
      List.of(_porEnviar[usuarioId] ?? const []);

  @override
  Future<void> quitarPorEnviar(String usuarioId, String sesionId) async =>
      _porEnviar[usuarioId]?.remove(sesionId);

  @override
  Future<void> marcarPorRegistrar(
    String usuarioId,
    String sesionId,
    DateTime creadaEn,
  ) async {
    final cola = _porRegistrar.putIfAbsent(usuarioId, () => []);
    if (!cola.contains(sesionId)) cola.add(sesionId);
  }

  @override
  Future<List<String>> porRegistrar(String usuarioId) async =>
      List.of(_porRegistrar[usuarioId] ?? const []);

  @override
  Future<void> quitarPorRegistrar(String usuarioId, String sesionId) async =>
      _porRegistrar[usuarioId]?.remove(sesionId);

  @override
  Future<void> guardarCatalogo(String usuarioId, List<dynamic> arbol) async =>
      _catalogo[usuarioId] = arbol;

  @override
  Future<List<dynamic>?> catalogo(String usuarioId) async =>
      _catalogo[usuarioId];

  @override
  Future<void> olvidarTodo(String usuarioId) async {
    _paquetes.remove(usuarioId);
    _sesiones.remove(usuarioId);
    _pendientes.remove(usuarioId);
    _porEnviar.remove(usuarioId);
    _porRegistrar.remove(usuarioId);
    _catalogo.remove(usuarioId);
  }
}
