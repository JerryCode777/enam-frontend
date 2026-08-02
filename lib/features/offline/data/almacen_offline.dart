import 'dart:convert';
import 'dart:typed_data';

import 'package:sqflite/sqflite.dart';

import '../../../core/security/cifrado_local.dart';
import '../../../core/storage/base_local.dart';
import '../../session/domain/session_models.dart';
import '../domain/offline_models.dart';

/// Guarda y devuelve lo que la app necesita sin conexión.
///
/// Es la única puerta a la base local: nadie más escribe SQL. Así el cifrado no
/// se puede olvidar en un sitio —todo lo que lleva enunciados pasa por aquí— y
/// el resto del código habla de paquetes y sesiones, no de tablas.
abstract interface class AlmacenOffline {
  /// Guarda el paquete de un área, pisando el anterior si lo había.
  Future<void> guardarPaquete(String usuarioId, PaqueteOffline paquete);

  /// Qué hay descargado, sin descifrar nada.
  Future<List<ResumenDePaquete>> resumenes(String usuarioId);

  /// El paquete completo de un área, o `null` si no está descargada.
  ///
  /// Devuelve `null` también si el contenido no se puede descifrar: pasa si se
  /// cerró sesión y se volvió a entrar, o si el archivo fue manipulado. Se
  /// trata como «no descargada», que es lo que el usuario puede arreglar
  /// volviendo a descargar.
  Future<PaqueteOffline?> paquete(String usuarioId, String areaId);

  Future<void> borrarPaquete(String usuarioId, String areaId);

  /// Guarda una sesión completa —preguntas y respuestas— para usarla sin señal.
  Future<void> guardarSesion(
    String usuarioId, {
    required String areaId,
    required EstadoSesionLocal estado,
    required StudySession sesion,
    DateTime? creadaEn,
  });

  Future<SesionLocal?> sesion(String usuarioId, String sesionId);

  Future<List<SesionLocal>> sesiones(
    String usuarioId, {
    EstadoSesionLocal? estado,
  });

  Future<void> borrarSesion(String usuarioId, String sesionId);

  /// Encola una respuesta. Si ya había una de esa pregunta, la reemplaza.
  Future<void> encolar(String usuarioId, RespuestaPendiente respuesta);

  /// La bandeja de salida, de la más antigua a la más nueva.
  Future<List<RespuestaPendiente>> pendientes(String usuarioId);

  Future<int> cuantasPendientes(String usuarioId);

  /// Saca de la bandeja las respuestas de esas preguntas en esa sesión.
  Future<void> quitarPendientes(
    String usuarioId,
    String sesionId,
    Iterable<String> preguntaIds,
  );

  /// Apunta que una sesión terminó sin conexión y falta cerrarla en el servidor.
  Future<void> marcarPorEnviar(
    String usuarioId,
    String sesionId,
    DateTime cuando,
  );

  Future<List<String>> porEnviar(String usuarioId);

  Future<void> quitarPorEnviar(String usuarioId, String sesionId);

  /// Guarda el temario para poder elegir qué practicar sin señal.
  Future<void> guardarCatalogo(String usuarioId, List<dynamic> arbol);

  /// El temario guardado, o `null` si nunca se llegó a guardar.
  Future<List<dynamic>?> catalogo(String usuarioId);

  /// Borra todo lo del usuario. Al cerrar sesión.
  Future<void> olvidarTodo(String usuarioId);
}

/// La implementación de verdad, sobre SQLite y con el contenido cifrado.
class AlmacenOfflineSqlite implements AlmacenOffline {
  AlmacenOfflineSqlite({required BaseLocal base, required CifradoLocal cifrado})
    : _base = base,
      _cifrado = cifrado;

  final BaseLocal _base;
  final CifradoLocal _cifrado;

  @override
  Future<void> guardarPaquete(String usuarioId, PaqueteOffline paquete) async {
    final db = await _base.db;
    final contenido = await _cifrado.cifrar(
      usuarioId,
      jsonEncode(paquete.toJson()),
    );

    await db.insert('paquetes', {
      'usuario_id': usuarioId,
      'area_id': paquete.areaId,
      'generado_en': paquete.generadoEn.toIso8601String(),
      'descargado_en': DateTime.now().toIso8601String(),
      'total': paquete.total,
      'bytes': contenido.length,
      'contenido': contenido,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<List<ResumenDePaquete>> resumenes(String usuarioId) async {
    final db = await _base.db;
    final filas = await db.query(
      'paquetes',
      columns: const [
        'area_id',
        'generado_en',
        'descargado_en',
        'total',
        'bytes',
      ],
      where: 'usuario_id = ?',
      whereArgs: [usuarioId],
      orderBy: 'descargado_en DESC',
    );

    return [
      for (final fila in filas)
        (
          areaId: fila['area_id'] as String,
          generadoEn: DateTime.parse(fila['generado_en'] as String),
          descargadoEn: DateTime.parse(fila['descargado_en'] as String),
          total: fila['total'] as int,
          bytes: fila['bytes'] as int,
        ),
    ];
  }

  @override
  Future<PaqueteOffline?> paquete(String usuarioId, String areaId) async {
    final db = await _base.db;
    final filas = await db.query(
      'paquetes',
      columns: const ['contenido'],
      where: 'usuario_id = ? AND area_id = ?',
      whereArgs: [usuarioId, areaId],
      limit: 1,
    );
    if (filas.isEmpty) return null;

    final json = await _descifrar(usuarioId, filas.first['contenido']);
    if (json == null) {
      // Ilegible: se limpia para que la pantalla ofrezca descargarla otra vez
      // en vez de dejar una fila que nunca se va a poder abrir.
      await borrarPaquete(usuarioId, areaId);
      return null;
    }
    return PaqueteOffline.fromJson(json);
  }

  @override
  Future<void> borrarPaquete(String usuarioId, String areaId) async {
    final db = await _base.db;
    await db.delete(
      'paquetes',
      where: 'usuario_id = ? AND area_id = ?',
      whereArgs: [usuarioId, areaId],
    );
  }

  @override
  Future<void> guardarSesion(
    String usuarioId, {
    required String areaId,
    required EstadoSesionLocal estado,
    required StudySession sesion,
    DateTime? creadaEn,
  }) async {
    final db = await _base.db;
    final contenido = await _cifrado.cifrar(
      usuarioId,
      jsonEncode(sesion.toJson()),
    );

    await db.insert('sesiones', {
      'usuario_id': usuarioId,
      'sesion_id': sesion.id,
      'area_id': areaId,
      'estado': estado.name,
      'creada_en': (creadaEn ?? DateTime.now()).toIso8601String(),
      'contenido': contenido,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<SesionLocal?> sesion(String usuarioId, String sesionId) async {
    final db = await _base.db;
    final filas = await db.query(
      'sesiones',
      where: 'usuario_id = ? AND sesion_id = ?',
      whereArgs: [usuarioId, sesionId],
      limit: 1,
    );
    if (filas.isEmpty) return null;
    return _aSesionLocal(usuarioId, filas.first);
  }

  @override
  Future<List<SesionLocal>> sesiones(
    String usuarioId, {
    EstadoSesionLocal? estado,
  }) async {
    final db = await _base.db;
    final filas = await db.query(
      'sesiones',
      where: estado == null
          ? 'usuario_id = ?'
          : 'usuario_id = ? AND estado = ?',
      whereArgs: [usuarioId, ?estado?.name],
      orderBy: 'creada_en ASC',
    );

    final sesiones = <SesionLocal>[];
    for (final fila in filas) {
      final sesion = await _aSesionLocal(usuarioId, fila);
      if (sesion != null) sesiones.add(sesion);
    }
    return sesiones;
  }

  Future<SesionLocal?> _aSesionLocal(
    String usuarioId,
    Map<String, Object?> fila,
  ) async {
    final json = await _descifrar(usuarioId, fila['contenido']);
    if (json == null) {
      await borrarSesion(usuarioId, fila['sesion_id'] as String);
      return null;
    }

    return (
      areaId: fila['area_id'] as String,
      estado: EstadoSesionLocal.values.firstWhere(
        (e) => e.name == fila['estado'],
        orElse: () => EstadoSesionLocal.enCurso,
      ),
      creadaEn: DateTime.parse(fila['creada_en'] as String),
      sesion: StudySession.fromJson(json),
    );
  }

  @override
  Future<void> borrarSesion(String usuarioId, String sesionId) async {
    final db = await _base.db;
    await db.delete(
      'sesiones',
      where: 'usuario_id = ? AND sesion_id = ?',
      whereArgs: [usuarioId, sesionId],
    );
  }

  @override
  Future<void> encolar(String usuarioId, RespuestaPendiente respuesta) async {
    final db = await _base.db;
    await db.insert('respuestas_pendientes', {
      'usuario_id': usuarioId,
      'sesion_id': respuesta.sesionId,
      'pregunta_id': respuesta.preguntaId,
      'opcion_id': respuesta.opcionId,
      'tiempo_ms': respuesta.tiempoMs,
      'marcada': respuesta.marcada ? 1 : 0,
      'respondida_en': respuesta.respondidaEn.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<List<RespuestaPendiente>> pendientes(String usuarioId) async {
    final db = await _base.db;
    final filas = await db.query(
      'respuestas_pendientes',
      where: 'usuario_id = ?',
      whereArgs: [usuarioId],
      orderBy: 'respondida_en ASC',
    );

    return [
      for (final fila in filas)
        (
          sesionId: fila['sesion_id'] as String,
          preguntaId: fila['pregunta_id'] as String,
          opcionId: fila['opcion_id'] as String?,
          tiempoMs: fila['tiempo_ms'] as int,
          marcada: (fila['marcada'] as int) == 1,
          respondidaEn: DateTime.parse(fila['respondida_en'] as String),
        ),
    ];
  }

  @override
  Future<int> cuantasPendientes(String usuarioId) async {
    final db = await _base.db;
    final filas = await db.rawQuery(
      'SELECT COUNT(*) AS cuantas FROM respuestas_pendientes WHERE usuario_id = ?',
      [usuarioId],
    );
    return (filas.first['cuantas'] as int?) ?? 0;
  }

  @override
  Future<void> quitarPendientes(
    String usuarioId,
    String sesionId,
    Iterable<String> preguntaIds,
  ) async {
    if (preguntaIds.isEmpty) return;
    final db = await _base.db;
    final huecos = List.filled(preguntaIds.length, '?').join(', ');

    await db.delete(
      'respuestas_pendientes',
      where: 'usuario_id = ? AND sesion_id = ? AND pregunta_id IN ($huecos)',
      whereArgs: [usuarioId, sesionId, ...preguntaIds],
    );
  }

  @override
  Future<void> marcarPorEnviar(
    String usuarioId,
    String sesionId,
    DateTime cuando,
  ) async {
    final db = await _base.db;
    await db.insert('envios_pendientes', {
      'usuario_id': usuarioId,
      'sesion_id': sesionId,
      'terminada_en': cuando.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<List<String>> porEnviar(String usuarioId) async {
    final db = await _base.db;
    final filas = await db.query(
      'envios_pendientes',
      columns: const ['sesion_id'],
      where: 'usuario_id = ?',
      whereArgs: [usuarioId],
      orderBy: 'terminada_en ASC',
    );
    return [for (final fila in filas) fila['sesion_id'] as String];
  }

  @override
  Future<void> quitarPorEnviar(String usuarioId, String sesionId) async {
    final db = await _base.db;
    await db.delete(
      'envios_pendientes',
      where: 'usuario_id = ? AND sesion_id = ?',
      whereArgs: [usuarioId, sesionId],
    );
  }

  @override
  Future<void> guardarCatalogo(String usuarioId, List<dynamic> arbol) async {
    final db = await _base.db;
    await db.insert('catalogo', {
      'usuario_id': usuarioId,
      'guardado_en': DateTime.now().toIso8601String(),
      // En claro y no cifrado: son nombres de áreas y temas, no preguntas.
      // Cifrar lo que no lo necesita solo añade una forma de perder el dato.
      'arbol': jsonEncode(arbol),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<List<dynamic>?> catalogo(String usuarioId) async {
    final db = await _base.db;
    final filas = await db.query(
      'catalogo',
      columns: const ['arbol'],
      where: 'usuario_id = ?',
      whereArgs: [usuarioId],
      limit: 1,
    );
    if (filas.isEmpty) return null;

    try {
      return jsonDecode(filas.first['arbol'] as String) as List<dynamic>;
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> olvidarTodo(String usuarioId) async {
    await _base.borrarTodoDe(usuarioId);
    await _cifrado.olvidar(usuarioId);
  }

  /// Descifra una columna, devolviendo `null` si no se puede leer.
  Future<Map<String, dynamic>?> _descifrar(
    String usuarioId,
    Object? columna,
  ) async {
    if (columna is! Uint8List) return null;
    try {
      final texto = await _cifrado.descifrar(usuarioId, columna);
      return jsonDecode(texto) as Map<String, dynamic>;
    } on DatoIlegible {
      return null;
    } on FormatException {
      return null;
    }
  }
}
