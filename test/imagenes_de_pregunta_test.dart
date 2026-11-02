import 'dart:convert';

import 'package:enam_app/features/session/domain/session_models.dart';
import 'package:enam_app/features/session/presentation/widgets/imagenes_de_pregunta.dart';
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Preguntas con imagen (aprobado por Jerry el 02/11; primero ECG de 12
/// derivaciones, apaisados, ~1600 px).
void main() {
  // Un PNG de 1×1: una imagen de verdad, sin red ni disco.
  final png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwAD'
    'hgGAWjR9awAAAABJRU5ErkJggg==',
  );
  const ecg = ImagenDetalle(
    url: 'https://enamprep.com/img/preguntas/ecg-1.webp',
    alt: 'ECG de 12 derivaciones en ritmo sinusal',
    credito: 'Fuente: PTB-XL (PhysioNet), CC BY 4.0',
    ancho: 1600,
    alto: 700,
  );

  late List<String> pedidas;
  setUp(() {
    pedidas = [];
    proveedorDeImagen = (url) {
      pedidas.add(url);
      return MemoryImage(png);
    };
  });

  Future<void> montar(
    WidgetTester tester,
    List<ImagenDetalle> imagenes, {
    Size tamano = const Size(390, 844),
  }) async {
    tester.view.physicalSize = tamano * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: ImagenesDePregunta(imagenes: imagenes),
          ),
        ),
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
  }

  group('el modelo', () {
    test('lee imagenesDetalle y cae a imagenes si no llega', () {
      final nueva = Question.fromJson({
        'id': 'q1',
        'enunciado': 'x',
        'opciones': <Object>[],
        'imagenes': ['https://a/1.webp'],
        'imagenesDetalle': [
          {
            'url': 'https://a/1.webp',
            'alt': 'ECG',
            'credito': null,
            'ancho': 1600,
            'alto': 700,
          },
        ],
      });
      expect(nueva.imagenesAMostrar.single.alt, 'ECG');
      expect(nueva.imagenesAMostrar.single.proporcion, closeTo(2.29, 0.01));

      final vieja = Question.fromJson({
        'id': 'q1',
        'enunciado': 'x',
        'opciones': <Object>[],
        'imagenes': ['https://a/1.webp'],
      });
      expect(vieja.imagenesAMostrar.single.url, 'https://a/1.webp');
      expect(vieja.imagenesAMostrar.single.proporcion, isNull);
    });
  });

  testWidgets('se ve con su crédito y su texto alternativo', (tester) async {
    await montar(tester, const [ecg]);

    expect(find.text('Fuente: PTB-XL (PhysioNet), CC BY 4.0'), findsOneWidget);
    expect(
      find.bySemanticsLabel('ECG de 12 derivaciones en ritmo sinusal'),
      findsOneWidget,
    );
    expect(find.text('Ampliar'), findsOneWidget);
  });

  testWidgets('apaisada: el alto sale de su proporción', (tester) async {
    await montar(tester, const [ecg]);
    final alto = tester.getSize(find.byType(InkWell)).height;
    // 358 de ancho / (1600/700) ≈ 157.
    expect(alto, closeTo(358 / (1600 / 700), 1));
  });

  testWidgets('nunca empuja las opciones: como mucho el 30 % del alto', (
    tester,
  ) async {
    // Una imagen alta y estrecha, que sin tope ocuparía toda la pantalla.
    await montar(tester, const [
      ImagenDetalle(url: 'https://a/alta.webp', ancho: 400, alto: 1600),
    ]);
    final alto = tester.getSize(find.byType(InkWell)).height;
    expect(alto, lessThanOrEqualTo(844 * 0.3));
  });

  testWidgets('si no carga: aviso y «Reintentar», que la vuelve a pedir', (
    tester,
  ) async {
    proveedorDeImagen = (url) {
      pedidas.add(url);
      return _Fallida();
    };
    await montar(tester, const [ecg]);
    await tester.pump();

    expect(find.text('No pudimos cargar la imagen.'), findsOneWidget);
    final antes = pedidas.length;
    await tester.tap(find.text('Reintentar'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    expect(pedidas.length, greaterThan(antes));
  });

  testWidgets(
    'el visor: deja girar el teléfono y al cerrar vuelve a vertical',
    (tester) async {
      final orientaciones = <List<dynamic>>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (llamada) async {
          if (llamada.method == 'SystemChrome.setPreferredOrientations') {
            orientaciones.add(llamada.arguments as List<dynamic>);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await montar(tester, const [ecg]);
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      expect(find.byType(VisorDeImagen), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(orientaciones.last, contains('DeviceOrientation.landscapeLeft'));

      await tester.tap(find.byTooltip('Cerrar'));
      await tester.pumpAndSettle();
      expect(find.byType(VisorDeImagen), findsNothing);
      expect(
        orientaciones.last,
        isNot(contains('DeviceOrientation.landscapeLeft')),
      );
    },
  );
}

/// Una imagen que siempre falla al cargar.
class _Fallida extends ImageProvider<_Fallida> {
  @override
  Future<_Fallida> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(_Fallida key, ImageDecoderCallback decode) =>
      OneFrameImageStreamCompleter(Future.error(Exception('sin red')));
}
