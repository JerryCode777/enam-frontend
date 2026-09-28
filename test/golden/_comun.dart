import 'dart:convert';
import 'dart:io';

import 'package:enam_app/core/providers.dart';
import 'package:enam_app/core/storage/app_prefs.dart';
import 'package:enam_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

/// Piezas compartidas por los bancos de capturas.

/// Tamaños lógicos de los tres dispositivos de referencia.
const dispositivos = <({String nombre, Size tamano})>[
  // El más estrecho y el más bajo: aquí es donde se desborda primero.
  (nombre: 'iphone-13-mini', tamano: Size(375, 812)),
  (nombre: 'iphone-14-pro', tamano: Size(393, 852)),
  (nombre: 'iphone-17-pro-max', tamano: Size(440, 956)),
];

/// Monta una pantalla al tamaño exacto de un dispositivo.
class Marco extends StatelessWidget {
  const Marco({
    super.key,
    required this.tamano,
    required this.oscuro,
    required this.child,
    this.overrides = const [],
  });

  final Size tamano;
  final bool oscuro;
  final Widget child;

  /// Lo que cada banco necesita cambiar además de las preferencias: un usuario
  /// con sesión, un repositorio con una práctica ya creada…
  final List<Override> overrides;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        // El onboarding escribe en preferencias al salir; sin esto, el test
        // tocaría el almacenamiento real de la máquina.
        appPrefsProvider.overrideWithValue(PrefsEnMemoria()),
        ...overrides,
      ],
      child: MediaQuery(
        data: MediaQueryData(
          size: tamano,
          // La muesca y el indicador de inicio del iPhone. Sin esto, el
          // contenido se dibujaría donde el sistema lo taparía.
          padding: const EdgeInsets.only(top: 47, bottom: 34),
        ),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: oscuro ? AppTheme.dark : AppTheme.light,
          home: child,
        ),
      ),
    );
  }
}

/// Carga las fuentes que usa la app.
///
/// `flutter_test` no lee las fuentes del pubspec: sin esto el texto sale como
/// rectángulos y los iconos como cuadrados vacíos, y las capturas no sirven
/// para revisar nada.
Future<void> cargarFuentes() async {
  Future<void> cargar(String familia, List<String> rutas) async {
    final cargador = FontLoader(familia);
    for (final ruta in rutas) {
      cargador.addFont(
        File(ruta).readAsBytes().then((b) => ByteData.view(b.buffer)),
      );
    }
    await cargador.load();
  }

  await cargar('Nunito', [
    for (final peso in [400, 600, 700, 800, 900])
      'assets/fonts/Nunito-$peso.ttf',
  ]);

  // Los iconos vienen de un paquete, así que están en el caché de pub y no en
  // `assets/`. Y el nombre lleva el prefijo `packages/<paquete>/`: es como
  // Flutter registra las fuentes que no son de la app. Sin el prefijo el
  // registro funciona pero nadie lo encuentra, y los iconos salen como
  // cuadrados vacíos.
  final iconos = await _rutaSimbolos();
  if (iconos != null) {
    await cargar(
      'packages/material_symbols_icons/MaterialSymbolsOutlined',
      [iconos],
    );
  }
}

/// Ruta del `.ttf` de Material Symbols dentro del caché de pub.
///
/// Se resuelve desde `package_config.json` en vez de escribirla a mano: el
/// número de versión cambia en cada actualización, y una ruta fija se rompería
/// en silencio dejando las capturas llenas de cuadrados.
Future<String?> _rutaSimbolos() async {
  final config = File('.dart_tool/package_config.json');
  if (!config.existsSync()) return null;

  final paquetes =
      (jsonDecode(await config.readAsString())
              as Map<String, dynamic>)['packages']
          as List<dynamic>;

  for (final p in paquetes.cast<Map<String, dynamic>>()) {
    if (p['name'] != 'material_symbols_icons') continue;
    // La barra final es obligatoria: sin ella, `resolve` trata el último
    // segmento como un archivo y lo reemplaza, dejando una ruta al padre.
    var texto = p['rootUri'] as String;
    if (!texto.endsWith('/')) texto = '$texto/';

    final raiz = Uri.parse(texto);
    final base = raiz.isAbsolute ? raiz : config.parent.uri.resolveUri(raiz);
    return base.resolve('lib/fonts/MaterialSymbolsOutlined.ttf').toFilePath();
  }
  return null;
}

class PrefsEnMemoria implements AppPrefs {
  bool _visto = false;
  DateTime? _inicioPrueba;

  @override
  Future<bool> onboardingVisto() async => _visto;

  @override
  Future<void> marcarOnboardingVisto() async => _visto = true;

  @override
  Future<Set<String>> nacionalesInscritos() async => _nacionales;

  @override
  Future<void> marcarInscritoEnNacional(String id) async =>
      _nacionales.add(id);

  // El reloj de la prueba (D-02). En las capturas siempre arranca sin empezar,
  // que es como nace todo usuario: así el inicio se retrata en su estado real
  // de primer uso y no en uno a medias.
  @override
  Future<DateTime?> inicioPrueba() async => _inicioPrueba;

  @override
  Future<DateTime> marcarInicioPrueba() async =>
      _inicioPrueba = DateTime.now();

  @override
  Future<void> reiniciarPrueba() async => _inicioPrueba = null;

  final _nacionales = <String>{};
}
