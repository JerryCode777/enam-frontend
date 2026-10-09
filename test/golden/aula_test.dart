@Tags(['golden'])
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:enam_app/core/router/routes.dart';
import 'package:enam_app/features/subscription/domain/acceso.dart';
import 'package:enam_app/features/subscription/presentation/muro_de_venta_screen.dart';
import 'package:enam_app/core/theme/app_theme.dart';
import 'package:enam_app/features/aula/data/mock_aula_repository.dart';
import 'package:enam_app/features/aula/presentation/aula_providers.dart';
import 'package:enam_app/features/aula/presentation/clase_screen.dart';
import 'package:enam_app/features/aula/presentation/curso_screen.dart';
import 'package:enam_app/features/aula/presentation/cursos_screen.dart';
import 'package:enam_app/features/aula/presentation/widgets/presentacion.dart';
import 'package:enam_app/features/aula/domain/aula_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

/// Capturas del aula en un Android de referencia (412 × 915): el catálogo, el
/// curso en gratis con sus candados, la clase con el reproductor y el muro.
///
/// Los datos son los del doble (`MockAulaRepository`). El video es falso: el
/// recuadro sale negro, con los controles encima.
///
/// ```sh
/// flutter test --update-goldens test/golden/aula_test.dart
/// ```
void main() {
  setUpAll(() async {
    await _cargarFuentes();
    VideoPlayerPlatform.instance = _VideoQuieto();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(
          'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi'
          '.toggle',
          (_) async => const StandardMessageCodec().encodeMessage(<Object?>[]),
        );
  });

  const tamano = Size(412, 915);

  final capturas =
      <({String nombre, String ruta, bool premium, bool muro, bool portadas})>[
        (
          nombre: '8.1-cursos',
          ruta: Routes.cursos,
          premium: true,
          muro: false,
          portadas: false,
        ),
        (
          nombre: '8.2-curso-gratis',
          ruta: Routes.cursoOf('medicina'),
          premium: false,
          muro: false,
          portadas: false,
        ),
        (
          nombre: '8.3-clase',
          ruta: Routes.claseOf('pediatria', 'pediatria.01-02'),
          premium: true,
          muro: false,
          portadas: false,
        ),
        (
          nombre: '8.4-muro-cursos',
          ruta: Routes.cursoOf('medicina'),
          premium: false,
          muro: true,
          portadas: false,
        ),
        // Las portadas compuestas de producción (portada-v2.jpg).
        (
          nombre: '8.5-cursos-portadas',
          ruta: Routes.cursos,
          premium: true,
          muro: false,
          portadas: true,
        ),
        (
          nombre: '8.6-curso-portada',
          ruta: Routes.cursoOf('pediatria'),
          premium: true,
          muro: false,
          portadas: true,
        ),
      ];

  for (final c in capturas) {
    for (final oscuro in [false, true]) {
      final tema = oscuro ? 'oscuro' : 'claro';

      testWidgets('${c.nombre} · $tema', (tester) async {
        tester.view
          ..devicePixelRatio = 2
          ..physicalSize = tamano * 2;
        addTearDown(tester.view.reset);

        if (c.portadas) await _decodificarPortadas(tester);
        await tester.pumpWidget(
          _Marco(
            tamano: tamano,
            oscuro: oscuro,
            ruta: c.ruta,
            premium: c.premium,
            portadas: c.portadas,
          ),
        );
        for (var i = 0; i < 3; i++) {
          await tester.pump(const Duration(milliseconds: 600));
        }
        await precargarImagenes(tester);
        // Ya decodificadas: un cuadro para pintarlas y lo que dura su fundido.
        await tester.pump(const Duration(milliseconds: 300));

        if (c.muro) {
          final bloqueada = find.text('Esquema nacional de vacunación');
          await tester.ensureVisible(bloqueada);
          await tester.pump(const Duration(milliseconds: 600));
          await tester.tap(bloqueada);
          for (var i = 0; i < 4; i++) {
            await tester.pump(const Duration(milliseconds: 300));
          }
        }

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('_imagenes/android-412/${c.nombre}-$tema.png'),
        );

        // El reproductor manda lo visto al salir: se deja que termine.
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
      });
    }
  }
}

/// Las imágenes de assets se decodifican fuera del reloj falso.
Future<void> precargarImagenes(WidgetTester tester) =>
    tester.runAsync(() async {
      for (final e in find.byType(Image).evaluate()) {
        final imagen = e.widget as Image;
        await precacheImage(imagen.image, e);
      }
    });

class _Marco extends StatelessWidget {
  const _Marco({
    required this.tamano,
    required this.oscuro,
    required this.ruta,
    required this.premium,
    required this.portadas,
  });

  final Size tamano;
  final bool oscuro;
  final String ruta;
  final bool premium;
  final bool portadas;

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: ruta,
      routes: [
        GoRoute(
          path: Routes.cursos,
          builder: (_, _) => const CursosScreen(),
          routes: [
            GoRoute(
              path: ':curso',
              builder: (_, s) =>
                  CursoScreen(cursoId: s.pathParameters['curso']!),
              routes: [
                GoRoute(
                  path: 'clase/:clase',
                  builder: (_, s) => ClaseScreen(
                    cursoId: s.pathParameters['curso']!,
                    claseId: s.pathParameters['clase']!,
                  ),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: Routes.premium,
          builder: (_, s) => MuroDeVentaScreen(
            motivo:
                MotivoDeMuro.desdeConsulta(s.uri.queryParameters) ??
                const FuncionDePago(FuncionPremium.otra),
          ),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        aulaRepositoryProvider.overrideWithValue(
          _ConVideo(premium: premium, conPortadas: portadas),
        ),
        imagenDeRedProvider.overrideWithValue(_portadaLocal),
      ],
      child: MediaQuery(
        data: MediaQueryData(
          size: tamano,
          padding: const EdgeInsets.only(top: 24, bottom: 16),
        ),
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: oscuro ? AppTheme.dark : AppTheme.light,
          routerConfig: router,
        ),
      ),
    );
  }
}

/// El doble de los mocks, con video en la clase para que salga el
/// reproductor.
class _ConVideo extends MockAulaRepository {
  _ConVideo({required super.premium, required super.conPortadas})
    : super(delay: Duration.zero);

  @override
  Future<Clase> clase(String id) async =>
      (await super.clase(id)).copyWith(videoUrl: 'https://cdn.example/x.mp4');
}

/// Las portadas de producción, reducidas, en `test/fixtures/portadas`.
ImageProvider _portadaLocal(String url, {int? ancho}) {
  final curso = Uri.parse(url).pathSegments.first;
  // Una por curso, siempre la misma: un MemoryImage nuevo es otra clave para
  // la caché, y la imagen se volvería a cargar en cada construcción.
  return _portadas.putIfAbsent(curso, () {
    final archivo = File('test/fixtures/portadas/$curso.jpg');
    return MemoryImage(
      (archivo.existsSync()
              ? archivo
              : File('test/fixtures/portadas/medicina.jpg'))
          .readAsBytesSync(),
    );
  });
}

final _portadas = <String, MemoryImage>{};

/// Decodifica las portadas antes de montar la pantalla, con el reloj de
/// verdad: la decodificación no avanza con el reloj falso de la prueba, y la
/// captura salía con las tarjetas en blanco.
Future<void> _decodificarPortadas(WidgetTester tester) => tester.runAsync(
  () async {
    for (final curso in const [
      'repaso-final',
      'medicina',
      'pediatria',
      'gineco-obstetricia',
      'cirugia',
      'salud-publica',
      'emergencias',
      'ciencias-basicas',
      'etica',
      'gestion',
      'investigacion',
    ]) {
      final imagen = _portadaLocal('https://cdn.example/$curso/portada-v2.jpg');
      final lista = Completer<void>();
      final flujo = imagen.resolve(ImageConfiguration.empty);
      flujo.addListener(
        ImageStreamListener(
          (_, _) {
            if (!lista.isCompleted) lista.complete();
          },
          onError: (e, _) {
            if (!lista.isCompleted) lista.completeError(e);
          },
        ),
      );
      await lista.future;
    }
  },
);

/// Un video de 8 min 34 s parado en el 4:22, donde se quedó la clase.
class _VideoQuieto extends VideoPlayerPlatform {
  final _eventos = <int, StreamController<VideoEvent>>{};
  var _siguiente = 0;
  Duration _posicion = Duration.zero;

  @override
  Future<void> init() async {}

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    final id = _siguiente++;
    _eventos[id] = StreamController<VideoEvent>();
    return id;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) {
    // Se cierra en [dispose].
    // ignore: close_sinks
    final eventos = _eventos[playerId]!;
    scheduleMicrotask(
      () => eventos.add(
        VideoEvent(
          eventType: VideoEventType.initialized,
          duration: const Duration(seconds: 534),
          size: const Size(1920, 1080),
        ),
      ),
    );
    return eventos.stream;
  }

  @override
  Future<void> dispose(int playerId) async => _eventos[playerId]?.close();

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> play(int playerId) async {}

  @override
  Future<void> pause(int playerId) async {}

  @override
  Future<void> setVolume(int playerId, double volume) async {}

  @override
  Future<void> seekTo(int playerId, Duration position) async =>
      _posicion = position;

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<Duration> getPosition(int playerId) async => _posicion;

  @override
  Widget buildViewWithOptions(VideoViewOptions options) =>
      const ColoredBox(color: Color(0xFF1B2A3A));

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}
}

/// Carga las fuentes que usa la app.
///
/// `flutter_test` no lee las fuentes del pubspec: sin esto el texto sale como
/// rectángulos y los iconos como cuadrados vacíos, y las capturas no sirven
/// para revisar nada.
Future<void> _cargarFuentes() async {
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
    await cargar('packages/material_symbols_icons/MaterialSymbolsOutlined', [
      iconos,
    ]);
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
