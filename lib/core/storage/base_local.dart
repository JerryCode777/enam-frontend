import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// La base de datos del teléfono, para estudiar sin conexión (RF-30 a RF-33).
///
/// Solo abre y versiona el archivo; **quién guarda qué** vive en
/// `AlmacenOffline`. Separarlo permite abrir la misma base en las pruebas con
/// la implementación de escritorio y probar el almacén de verdad, en vez de
/// contra un doble que siempre se comporta bien.
///
/// Lo que se guarda aquí, y por qué cada cosa:
///
/// - **`paquetes`** — el banco de preguntas de un área, **cifrado**. Trae las
///   claves y las explicaciones: sin ellas no se puede corregir sin conexión.
///   Por eso el contenido nunca se escribe en claro (ver `CifradoLocal`).
/// - **`sesiones`** — las prácticas listas para usar sin señal y las que están
///   a medias. También cifradas: llevan las preguntas dentro.
/// - **`respuestas_pendientes`** — la bandeja de salida. Lo que se respondió
///   sin conexión y todavía no llegó al servidor. **No se cifra**: son ids y
///   marcas de tiempo, no contenido.
/// - **`envios_pendientes`** — sesiones terminadas sin señal a las que les
///   falta el cierre en el servidor, que es quien pone la nota oficial.
/// - **`catalogo`** — el temario, para poder elegir qué practicar sin señal.
///
/// Todo va con `usuario_id`: en un teléfono compartido, lo de una cuenta no se
/// mezcla con lo de otra ni aparece al iniciar sesión con la otra.
class BaseLocal {
  BaseLocal({DatabaseFactory? factory, String? ruta})
    : _factory = factory,
      _ruta = ruta;

  final DatabaseFactory? _factory;
  final String? _ruta;

  static const archivo = 'enam_offline.db';
  static const version = 1;

  Database? _db;
  Future<Database>? _abriendo;

  /// La base, abriéndola la primera vez.
  ///
  /// El futuro se guarda para que dos llamadas simultáneas —la pantalla de
  /// descargas y la sincronización al reconectar, por ejemplo— no abran el
  /// archivo dos veces.
  Future<Database> get db async {
    final abierta = _db;
    if (abierta != null) return abierta;
    return _db = await (_abriendo ??= _abrir());
  }

  Future<Database> _abrir() async {
    final fabrica = _factory ?? databaseFactory;
    final ruta = _ruta ?? p.join(await fabrica.getDatabasesPath(), archivo);

    return fabrica.openDatabase(
      ruta,
      options: OpenDatabaseOptions(
        version: version,
        onCreate: (db, _) => _crear(db),
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      ),
    );
  }

  Future<void> _crear(Database db) async {
    final lote = db.batch();

    lote.execute('''
      CREATE TABLE paquetes (
        usuario_id    TEXT    NOT NULL,
        area_id       TEXT    NOT NULL,
        generado_en   TEXT    NOT NULL,
        descargado_en TEXT    NOT NULL,
        total         INTEGER NOT NULL,
        bytes         INTEGER NOT NULL,
        contenido     BLOB    NOT NULL,
        PRIMARY KEY (usuario_id, area_id)
      )
    ''');

    lote.execute('''
      CREATE TABLE sesiones (
        usuario_id  TEXT NOT NULL,
        sesion_id   TEXT NOT NULL,
        area_id     TEXT NOT NULL,
        estado      TEXT NOT NULL,
        creada_en   TEXT NOT NULL,
        contenido   BLOB NOT NULL,
        PRIMARY KEY (usuario_id, sesion_id)
      )
    ''');

    // Una fila por pregunta y sesión: si el estudiante cambia de opinión sin
    // señal, la última respuesta pisa a la anterior en vez de encolar dos y
    // dejar que el servidor decida cuál gana.
    lote.execute('''
      CREATE TABLE respuestas_pendientes (
        usuario_id    TEXT    NOT NULL,
        sesion_id     TEXT    NOT NULL,
        pregunta_id   TEXT    NOT NULL,
        opcion_id     TEXT,
        tiempo_ms     INTEGER NOT NULL DEFAULT 0,
        marcada       INTEGER NOT NULL DEFAULT 0,
        respondida_en TEXT    NOT NULL,
        PRIMARY KEY (usuario_id, sesion_id, pregunta_id)
      )
    ''');

    // El temario, tal cual lo mandó el servidor.
    //
    // No es contenido premium —son nombres de áreas y temas, no preguntas— pero
    // sin él no se puede ni elegir qué practicar, así que sin esta copia el
    // modo sin conexión se cae en la primera pantalla.
    lote.execute('''
      CREATE TABLE catalogo (
        usuario_id  TEXT NOT NULL PRIMARY KEY,
        guardado_en TEXT NOT NULL,
        arbol       TEXT NOT NULL
      )
    ''');

    lote.execute('''
      CREATE TABLE envios_pendientes (
        usuario_id   TEXT NOT NULL,
        sesion_id    TEXT NOT NULL,
        terminada_en TEXT NOT NULL,
        PRIMARY KEY (usuario_id, sesion_id)
      )
    ''');

    // El orden de salida de la bandeja es el de respuesta, no el de inserción:
    // el servidor resuelve conflictos por marca de tiempo (contrato §7).
    lote.execute(
      'CREATE INDEX idx_pendientes_orden '
      'ON respuestas_pendientes (usuario_id, respondida_en)',
    );

    await lote.commit(noResult: true);
  }

  /// Borra **todo** lo de un usuario. Se llama al cerrar sesión.
  Future<void> borrarTodoDe(String usuarioId) async {
    final base = await db;
    final lote = base.batch();
    for (final tabla in const [
      'paquetes',
      'sesiones',
      'respuestas_pendientes',
      'envios_pendientes',
      'catalogo',
    ]) {
      lote.delete(tabla, where: 'usuario_id = ?', whereArgs: [usuarioId]);
    }
    await lote.commit(noResult: true);
  }

  Future<void> cerrar() async {
    await _db?.close();
    _db = null;
    _abriendo = null;
  }
}
