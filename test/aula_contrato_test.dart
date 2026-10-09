import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:enam_app/core/error/failure.dart';
import 'package:enam_app/core/network/api_client.dart';
import 'package:enam_app/core/storage/token_storage.dart';
import 'package:enam_app/features/aula/data/aula_repository.dart';
import 'package:enam_app/features/aula/domain/aula_models.dart';
import 'package:enam_app/features/aula/domain/segundos_vistos.dart';
import 'package:enam_app/features/aula/presentation/muro_de_cursos.dart';
import 'package:enam_app/features/aula/presentation/reproductor/controles.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// El contrato del aula con el backend (`internal/aula/handler.go`) y las
/// cuentas que la app hace sobre él.
///
/// Los JSON son los que arma el handler, con sus nulos y sus campos que se
/// omiten (`omitempty`): si el servidor cambia un nombre, falla aquí y no en
/// el teléfono de alguien.
void main() {
  group('Lo que manda el servidor', () {
    test('el catálogo, con el repaso final sin área', () {
      final c = CursoResumen.fromJson({
        'id': 'repaso-final',
        'tipo': 'repaso',
        'areaId': null,
        'titulo': 'Repaso final ENAM',
        'descripcion': '',
        'lema': 'Esto cae seguro',
        'profe': {'id': 'profe-andrea', 'nombre': 'Profe Andrea'},
        'orden': 11,
        'publicado': true,
        'clases': 67,
        'disponibles': 12,
        'gratis': 3,
        'duracionS': 5400,
        'completadas': 2,
      });

      expect(c.esRepaso, isTrue);
      expect(c.areaId, isNull);
      expect(c.profe?.retratoUrl, isNull);
      expect(c.proximamente, isFalse);
    });

    test('un curso sin clases es «Próximamente»', () {
      final c = CursoResumen.fromJson({
        'id': 'gestion',
        'tipo': 'area',
        'areaId': 'gestion',
        'titulo': 'Gestión en Salud',
        'descripcion': '',
        'lema': '',
        'profe': null,
        'orden': 9,
        'publicado': false,
        'clases': 0,
        'disponibles': 0,
        'gratis': 0,
        'duracionS': 0,
        'completadas': 0,
      });

      expect(c.proximamente, isTrue);
      expect(c.profe, isNull);
    });

    test('un tipo o un estado nuevo no rompe la lectura', () {
      final c = CursoResumen.fromJson({
        'id': 'x',
        'tipo': 'taller',
        'titulo': 'X',
      });
      expect(c.tipo, TipoDeCurso.desconocido);

      final k = ClaseResumen.fromJson({
        'id': 'x.01-01',
        'titulo': 'X',
        'estado': 'retirada',
        'progreso': {'segundosVistos': 0, 'posicionS': 0, 'completada': false},
      });
      expect(k.disponible, isFalse);
    });

    test('el curso, con su temario y la clase para seguir', () {
      final curso = Curso.fromJson({
        'id': 'pediatria',
        'tipo': 'area',
        'areaId': 'pediatria',
        'titulo': 'Pediatría',
        'descripcion': 'El temario oficial.',
        'lema': 'Primero, la norma',
        'profe': null,
        'orden': 3,
        'publicado': true,
        'clases': 2,
        'disponibles': 2,
        'gratis': 1,
        'duracionS': 1000,
        'completadas': 0,
        'premium': false,
        'modulos': [
          {
            'id': 'pediatria.02',
            'codigo': '02',
            'orden': 1,
            'titulo': 'El niño y el adolescente',
            'descripcion': '',
            'nodoId': 'pediatria-nino-adolescente',
            'clases': [
              _clase('pediatria.02-01', gratis: true),
              _clase('pediatria.02-02', bloqueada: true, miniatura: true),
            ],
          },
        ],
        'continuar': _clase('pediatria.02-01', gratis: true),
      });

      expect(curso.premium, isFalse);
      final clases = curso.modulos.single.clases;
      expect(clases.first.gratis, isTrue);
      expect(clases.last.bloqueada, isTrue);
      // La miniatura sale firmada también en las bloqueadas: se ve qué hay
      // detrás del candado.
      expect(clases.last.miniaturaUrl, isNotNull);
      expect(curso.continuar?.id, 'pediatria.02-01');
    });

    test('la clase, con sus URL firmadas, referencias y vecinas', () {
      final clase = Clase.fromJson({
        ..._clase('pediatria.02-01', gratis: true),
        'cursoId': 'pediatria',
        'cursoTitulo': 'Pediatría',
        'profe': {
          'id': 'profe-ximena',
          'nombre': 'Profe Ximena',
          'articulo': 'la',
          'retratoMiniUrl': 'https://cdn.example/p.webp?Signature=a',
        },
        'moduloId': 'pediatria.02',
        'objetivos': ['Tamizar según la norma'],
        'temas': ['Anemia ferropénica'],
        'referencias': [
          {
            'id': 'R1',
            'tipo': 'norma',
            'cita': 'NTS N.° 213-MINSA/DGIESP-2024',
            'anio': 2024,
            'url': 'https://www.gob.pe/x',
          },
          {
            'id': 'R2',
            'tipo': 'libro',
            'cita': 'Nelson Tratado de Pediatría',
            'edicion': '21.ª',
            'capitulo': '482',
            'anio': 2020,
          },
          {
            'id': 'R3',
            'tipo': 'articulo',
            'cita': 'Un ensayo',
            'doi': '10.1000/xyz',
          },
        ],
        'videoUrl': 'https://cdn.example/clase.mp4?Signature=a',
        'subtitulosUrl': 'https://cdn.example/clase.vtt?Signature=a',
        'practicaDisponible': true,
        'anterior': null,
        'siguiente': {
          'id': 'pediatria.02-02',
          'titulo': 'Anemia II',
          'bloqueada': true,
        },
      });

      expect(clase.conVideo, isTrue);
      expect(clase.anterior, isNull);
      expect(clase.siguiente?.bloqueada, isTrue);

      final [norma, libro, articulo] = clase.referencias;
      expect(norma.tipo.etiqueta, 'Norma');
      expect(norma.enlace, 'https://www.gob.pe/x');
      expect(libro.detalle, '21.ª ed. · cap. 482 · 2020');
      expect(libro.enlace, isNull);
      expect(articulo.enlace, 'https://doi.org/10.1000/xyz');
    });

    test('una clase sin video no se puede reproducir', () {
      final clase = Clase.fromJson({
        ..._clase('x.01-01', estado: 'proximamente'),
        'cursoId': 'x',
        'practicaDisponible': false,
      });
      expect(clase.conVideo, isFalse);
    });
  });

  group('Segundos vistos', () {
    test('se cuentan los segundos reproducidos, una vez cada uno', () {
      final s = SegundosVistos();
      for (var t = 0; t <= 20; t++) {
        s.registrar(Duration(seconds: t), reproduciendo: true);
      }
      expect(s.total, 21);

      // Volver a ver lo mismo no suma.
      s.cortar();
      for (var t = 0; t <= 20; t++) {
        s.registrar(Duration(seconds: t), reproduciendo: true);
      }
      expect(s.total, 21);
    });

    test('adelantar hasta el final no cuenta como visto', () {
      final s = SegundosVistos()
        ..registrar(Duration.zero, reproduciendo: true)
        ..registrar(const Duration(seconds: 1), reproduciendo: true)
        // Un salto de 98 s: es un adelanto.
        ..registrar(const Duration(seconds: 99), reproduciendo: true)
        ..registrar(const Duration(seconds: 100), reproduciendo: true);

      expect(s.total, 4);
      expect(completa(s.total, 100), isFalse);
    });

    test('en pausa no se suma', () {
      final s = SegundosVistos()
        ..registrar(Duration.zero, reproduciendo: false)
        ..registrar(const Duration(seconds: 1), reproduciendo: false);
      expect(s.total, 0);
    });

    test('lo visto antes se da por los primeros segundos', () {
      final s = SegundosVistos(previos: 30)
        ..registrar(const Duration(seconds: 10), reproduciendo: true)
        ..registrar(const Duration(seconds: 12), reproduciendo: true);
      expect(s.total, 30);
    });

    test('completada al 90 %', () {
      expect(completa(89, 100), isFalse);
      expect(completa(90, 100), isTrue);
      expect(completa(10, 0), isFalse);
    });
  });

  group('Textos', () {
    test('duración corta, como la web', () {
      expect(duracionCorta(45), '45 s');
      expect(duracionCorta(512), '9 min');
      expect(duracionCorta(4800), '1 h 20 min');
      expect(duracionCorta(7200), '2 h');
    });

    test('posición para «sigues donde lo dejaste»', () {
      expect(posicionEnTexto(const Duration(seconds: 245)), '4:05');
      expect(posicionEnTexto(const Duration(seconds: 3729)), '1:02:09');
    });

    test('velocidades con coma decimal', () {
      expect([1.0, 1.25, 1.5, 2.0].map(velocidadEnTexto), [
        '1×',
        '1,25×',
        '1,5×',
        '2×',
      ]);
    });

    test('clases en texto', () {
      expect(clasesEnTexto(1), '1 clase');
      expect(clasesEnTexto(3), '3 clases');
    });
  });

  group('El repositorio', () {
    late _Servidor servidor;
    late AulaRepository repo;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      final client = ApiClient(
        tokenStorage: TokenStorage(),
        onSessionExpired: () {},
      );
      // Sin el interceptor de sesión: aquí se prueba el contrato, no el token.
      client.raw.interceptors.clear();
      servidor = _Servidor();
      client.raw.httpClientAdapter = servidor;
      repo = ApiAulaRepository(client);
    });

    test('«Seguir viendo» sin nada a medias es un 204, no un error', () async {
      servidor.responder(204, null);
      expect(await repo.seguirViendo(), isNull);
      expect(servidor.ultima?.path, endsWith('/aula/continuar'));
    });

    test('el progreso va por PUT con los segundos y la posición', () async {
      servidor.responder(200, {
        'segundosVistos': 470,
        'posicionS': 480,
        'completada': true,
      });

      final p = await repo.progreso(
        'pediatria.02-01',
        segundosVistos: 470,
        posicionS: 480,
      );

      expect(servidor.ultima?.method, 'PUT');
      expect(
        servidor.ultima?.path,
        endsWith('/aula/clases/pediatria.02-01/progreso'),
      );
      expect(servidor.cuerpo, {'segundosVistos': 470, 'posicionS': 480});
      expect(p.completada, isTrue);
    });

    test(
      'la clase de pago llega como FUNCION_PREMIUM y abre el muro',
      () async {
        servidor.responder(403, {
          'error': {
            'code': 'FUNCION_PREMIUM',
            'message': 'Los cursos completos son de Premium.',
            'details': {'funcion': 'cursos', 'clase': 'pediatria.02-02'},
          },
        });

        Object? error;
        try {
          await repo.clase('pediatria.02-02');
        } catch (e) {
          error = e;
        }

        expect(error, isA<ForbiddenFailure>());
        expect(esClaseDePago(error), isTrue);
      },
    );

    test('la práctica de la clase es una sesión normal', () async {
      servidor.responder(201, {
        'id': 'sesion-1',
        'tipo': 'practica',
        'estado': 'en_curso',
        'iniciadaEn': '2026-10-09T15:00:00Z',
        'finalizadaEn': null,
        'expiraEn': null,
        'nota': null,
        'preguntas': <Object>[],
        'respuestas': <String, Object>{},
      });

      final sesion = await repo.practica('pediatria.02-01');

      expect(servidor.ultima?.method, 'POST');
      expect(sesion.id, 'sesion-1');
    });
  });
}

Map<String, Object?> _clase(
  String id, {
  bool gratis = false,
  bool bloqueada = false,
  bool miniatura = false,
  String estado = 'disponible',
}) => {
  'id': id,
  'codigo': id.split('.').last,
  'orden': 1,
  'titulo': 'Anemia ferropénica I',
  'duracionS': 512,
  'estado': estado,
  'gratis': gratis,
  'bloqueada': bloqueada,
  if (miniatura) 'miniaturaUrl': 'https://cdn.example/m.jpg?Signature=a',
  'progreso': {'segundosVistos': 0, 'posicionS': 0, 'completada': false},
};

/// Responde lo que se le diga y guarda la última petición.
class _Servidor implements HttpClientAdapter {
  int _estado = 200;
  Object? _cuerpo;
  RequestOptions? ultima;
  Object? cuerpo;

  void responder(int estado, Object? cuerpo) {
    _estado = estado;
    _cuerpo = cuerpo;
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    ultima = options;
    cuerpo = options.data;
    final texto = _cuerpo == null ? '' : jsonEncode(_cuerpo);
    return ResponseBody.fromString(
      texto,
      _estado,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
