@Tags(['backend-local'])
library;

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:enam_app/core/network/api_client.dart';
import 'package:enam_app/core/storage/token_storage.dart';
import 'package:enam_app/features/aula/data/aula_repository.dart';
import 'package:enam_app/features/aula/presentation/muro_de_cursos.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';

/// El repositorio del aula contra un backend de verdad, el local.
///
/// No corre en la suite normal: hace falta el backend levantado con un curso
/// cargado (`cmd/cargar-aula`) y medios locales (`AULA_MEDIOS_DIR`), y un
/// token de una cuenta.
///
/// ```sh
/// AULA_API=http://localhost:8080/api/v1 AULA_TOKEN=<accessToken> \
///   flutter test --tags backend-local test/aula_backend_local_test.dart
/// ```
void main() {
  final api = Platform.environment['AULA_API'];
  final token = Platform.environment['AULA_TOKEN'];
  final sinBackend = api == null || token == null
      ? 'sin AULA_API ni AULA_TOKEN'
      : null;

  late AulaRepository repo;
  late Dio medios;

  setUpAll(() {
    if (sinBackend != null) return;
    FlutterSecureStorage.setMockInitialValues({});
    final client = ApiClient(
      tokenStorage: TokenStorage(),
      onSessionExpired: () {},
    );
    client.raw
      ..interceptors.clear()
      ..options.baseUrl = api!
      ..options.headers['Authorization'] = 'Bearer $token';
    repo = ApiAulaRepository(client);
    medios = Dio();
  });

  test('catálogo, curso, clase, progreso y «seguir viendo»', () async {
    final cursos = await repo.cursos();
    final publicado = cursos.firstWhere((c) => !c.proximamente);
    // ignore: avoid_print
    print(
      'cursos: ${cursos.length}, con clases: ${publicado.titulo} '
      '(${publicado.disponibles} disponibles, ${publicado.gratis} gratis)',
    );

    final curso = await repo.curso(publicado.id);
    final clases = curso.modulos.expand((m) => m.clases).toList();
    final abierta = clases.firstWhere((c) => c.disponible && !c.bloqueada);
    // ignore: avoid_print
    print(
      'curso ${curso.id}: premium=${curso.premium}, '
      '${curso.modulos.length} módulos, continuar=${curso.continuar?.id}',
    );

    final clase = await repo.clase(abierta.id);
    expect(clase.conVideo, isTrue);
    // ignore: avoid_print
    print('clase ${clase.id}: video ${clase.videoUrl}');

    // El MP4 se sirve por rango: es lo que pide ExoPlayer.
    final rango = await medios.get<List<int>>(
      clase.videoUrl!,
      options: Options(
        headers: {'Range': 'bytes=0-1023'},
        responseType: ResponseType.bytes,
      ),
    );
    expect(rango.statusCode, 206);
    expect(rango.data, hasLength(1024));

    if (clase.subtitulosUrl case final vtt?) {
      final r = await medios.get<String>(
        vtt,
        options: Options(responseType: ResponseType.plain),
      );
      expect(r.data, startsWith('WEBVTT'));
      // Y lo lee el mismo lector que usa el reproductor.
      final subtitulos = WebVTTCaptionFile(r.data!).captions;
      expect(subtitulos, isNotEmpty);
      // ignore: avoid_print
      print(
        'subtítulos: ${subtitulos.length}, el primero: '
        '«${subtitulos.first.text}»',
      );
    }

    final p = await repo.progreso(clase.id, segundosVistos: 30, posicionS: 31);
    expect(p.segundosVistos, greaterThanOrEqualTo(30));
    expect(p.posicionS, 31);

    final seguir = await repo.seguirViendo();
    expect(seguir?.clase.id, clase.id);

    final bloqueada = clases.where((c) => c.disponible && c.bloqueada);
    if (bloqueada.isNotEmpty) {
      Object? error;
      try {
        await repo.clase(bloqueada.first.id);
      } catch (e) {
        error = e;
      }
      expect(esClaseDePago(error), isTrue);
    }
  }, skip: sinBackend);
}
