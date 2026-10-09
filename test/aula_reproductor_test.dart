import 'dart:async';

import 'package:enam_app/core/theme/app_theme.dart';
import 'package:enam_app/features/aula/data/aula_repository.dart';
import 'package:enam_app/features/aula/domain/aula_models.dart';
import 'package:enam_app/features/aula/presentation/aula_providers.dart';
import 'package:enam_app/features/aula/presentation/clase_screen.dart';
import 'package:enam_app/features/aula/presentation/reproductor/reproductor_de_clase.dart';
import 'package:enam_app/features/session/domain/session_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

/// El reproductor de la clase, con un video falso.
///
/// Lo que se prueba es lo que no se ve en una captura: qué se manda como
/// visto, dónde se retoma y qué pasa cuando la URL firmada caduca.
void main() {
  late _VideoFalso video;
  late _Repo repo;

  setUp(() {
    video = _VideoFalso();
    VideoPlayerPlatform.instance = video;
    repo = _Repo();
    // wakelock_plus habla con la plataforma por su canal: aquí se le contesta
    // que sí, sin pantalla que mantener encendida.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(
          'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi'
          '.toggle',
          (_) async => const StandardMessageCodec().encodeMessage(<Object?>[]),
        );
  });

  Future<void> montar(WidgetTester tester) async {
    tester.view
      ..devicePixelRatio = 3
      ..physicalSize = const Size(412 * 3, 915 * 3);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [aulaRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ClaseScreen(cursoId: 'pediatria', claseId: 'p.01-01'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  EstadoDelReproductor reproductor(WidgetTester tester) =>
      tester.state<EstadoDelReproductor>(find.byType(ReproductorDeClase));

  /// Reproduce [segundos] de video, como lo haría el teléfono: la posición
  /// avanza y el controlador la consulta cada medio segundo.
  Future<void> reproducir(WidgetTester tester, int segundos) async {
    for (var i = 0; i < segundos * 2; i++) {
      video.posicion += const Duration(milliseconds: 500);
      await tester.pump(const Duration(milliseconds: 500));
    }
  }

  Future<void> cerrar(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('manda lo visto cada 15 s de reproducción', (tester) async {
    await montar(tester);

    await reproductor(tester).alternarReproduccion();
    await reproducir(tester, 16);

    expect(repo.progresos, isNotEmpty);
    final (vistos, posicion) = repo.progresos.last;
    expect(vistos, inInclusiveRange(14, 17));
    expect(posicion, inInclusiveRange(14, 16));

    await cerrar(tester);
  });

  testWidgets('adelantar no cuenta como visto; pausar manda al momento', (
    tester,
  ) async {
    await montar(tester);
    final estado = reproductor(tester);

    await estado.alternarReproduccion();
    await reproducir(tester, 5);
    await estado.irA(const Duration(seconds: 95));
    video.posicion = const Duration(seconds: 95);
    await reproducir(tester, 3);
    await estado.alternarReproduccion();
    await tester.pump();

    final (vistos, posicion) = repo.progresos.last;
    // Los 5 del principio y los 3 del final, no los 90 del salto.
    expect(vistos, lessThan(12));
    expect(posicion, inInclusiveRange(97, 99));

    await cerrar(tester);
  });

  testWidgets('retoma donde se quedó y deja empezar de cero', (tester) async {
    repo.inicial = const ProgresoDeClase(segundosVistos: 40, posicionS: 42);
    await montar(tester);

    expect(video.saltos, contains(const Duration(seconds: 42)));
    expect(find.text('Sigues donde lo dejaste, en el 0:42.'), findsOneWidget);

    await tester.tap(find.text('Desde el inicio'));
    await tester.pump();
    expect(video.saltos.last, Duration.zero);
    expect(find.textContaining('Sigues donde lo dejaste'), findsNothing);

    await cerrar(tester);
  });

  testWidgets('una clase ya vista empieza desde el principio', (tester) async {
    repo.inicial = const ProgresoDeClase(
      segundosVistos: 95,
      posicionS: 60,
      completada: true,
    );
    await montar(tester);

    expect(video.saltos, isEmpty);
    expect(find.textContaining('Sigues donde lo dejaste'), findsNothing);

    await cerrar(tester);
  });

  testWidgets('si la URL caduca, pide la clase otra vez y sigue donde iba', (
    tester,
  ) async {
    await montar(tester);
    final estado = reproductor(tester);
    await estado.alternarReproduccion();
    await reproducir(tester, 10);
    expect(repo.pedidasDeClase, 1);

    // CloudFront responde 403 a la firma vencida.
    video.fallar();
    await tester.pumpAndSettle();

    expect(repo.pedidasDeClase, 2);
    expect(video.urls, hasLength(2));
    expect(video.urls.last, contains('firma=2'));
    expect(video.saltos.last.inSeconds, inInclusiveRange(9, 10));
    expect(find.text('No pudimos reproducir la clase.'), findsNothing);

    await cerrar(tester);
  });

  testWidgets('si falla otra vez enseguida, lo dice y deja reintentar', (
    tester,
  ) async {
    await montar(tester);

    video.fallar();
    await tester.pumpAndSettle();
    video.fallar();
    await tester.pumpAndSettle();

    expect(repo.pedidasDeClase, 2);
    expect(find.text('No pudimos reproducir la clase.'), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(repo.pedidasDeClase, 3);

    await cerrar(tester);
  });

  testWidgets('la velocidad va del 1× al 2×', (tester) async {
    await montar(tester);
    // video_player la aplica mientras reproduce.
    await reproductor(tester).alternarReproduccion();
    await tester.pump();

    await tester.tap(find.bySemanticsLabel('Velocidad 1×'));
    await tester.pumpAndSettle();
    expect(find.text('1,25×'), findsOneWidget);
    expect(find.text('1,5×'), findsOneWidget);
    expect(find.text('2×'), findsOneWidget);

    await tester.tap(find.text('1,5×'));
    await tester.pumpAndSettle();
    expect(video.velocidades.last, 1.5);

    await cerrar(tester);
  });

  testWidgets('al salir de la clase manda lo último visto', (tester) async {
    await montar(tester);
    await reproductor(tester).alternarReproduccion();
    await reproducir(tester, 6);
    final antes = repo.progresos.length;

    await cerrar(tester);

    expect(repo.progresos.length, greaterThan(antes));
  });
}

class _Repo implements AulaRepository {
  int pedidasDeClase = 0;
  ProgresoDeClase inicial = const ProgresoDeClase();
  final progresos = <(int, int)>[];

  @override
  Future<Clase> clase(String id) async {
    pedidasDeClase++;
    return Clase(
      id: id,
      titulo: 'Anemia ferropénica I',
      duracionS: 100,
      estado: EstadoDeClase.disponible,
      progreso: inicial,
      cursoId: 'pediatria',
      cursoTitulo: 'Pediatría',
      videoUrl: 'https://cdn.example/clase.mp4?firma=$pedidasDeClase',
    );
  }

  @override
  Future<Curso> curso(String id) async =>
      Curso(id: id, titulo: 'Pediatría', areaId: 'pediatria');

  @override
  Future<ProgresoDeClase> progreso(
    String claseId, {
    required int segundosVistos,
    required int posicionS,
  }) async {
    progresos.add((segundosVistos, posicionS));
    return ProgresoDeClase(
      segundosVistos: segundosVistos,
      posicionS: posicionS,
      completada: segundosVistos >= 90,
    );
  }

  @override
  Future<List<CursoResumen>> cursos() async => const [];

  @override
  Future<StudySession> practica(String claseId) => throw UnimplementedError();

  @override
  Future<SeguirViendo?> seguirViendo() async => null;
}

/// Un video de 100 s que no reproduce nada: la posición la mueve la prueba.
class _VideoFalso extends VideoPlayerPlatform {
  final urls = <String>[];
  final saltos = <Duration>[];
  final velocidades = <double>[];
  final _eventos = <int, StreamController<VideoEvent>>{};
  Duration posicion = Duration.zero;
  int _siguiente = 0;

  /// El último video falla, como cuando CloudFront rechaza la firma.
  void fallar() => _eventos[_siguiente - 1]!.addError(
    PlatformException(code: 'VideoError', message: 'Response code: 403'),
  );

  @override
  Future<void> init() async {}

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    final id = _siguiente++;
    urls.add(options.dataSource.uri!);
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
          duration: const Duration(seconds: 100),
          size: const Size(1920, 1080),
        ),
      ),
    );
    return eventos.stream;
  }

  @override
  Future<void> dispose(int playerId) async {
    await _eventos[playerId]?.close();
  }

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> play(int playerId) async {}

  @override
  Future<void> pause(int playerId) async {}

  @override
  Future<void> setVolume(int playerId, double volume) async {}

  @override
  Future<void> seekTo(int playerId, Duration position) async {
    posicion = position;
    saltos.add(position);
  }

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {
    velocidades.add(speed);
  }

  @override
  Future<Duration> getPosition(int playerId) async => posicion;

  @override
  Widget buildViewWithOptions(VideoViewOptions options) => const SizedBox();

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}
}
