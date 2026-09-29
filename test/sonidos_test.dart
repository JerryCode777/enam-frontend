import 'dart:io';

import 'package:enam_app/core/providers.dart';
import 'package:enam_app/core/sonido/proveedor_sonidos.dart';
import 'package:enam_app/core/sonido/sonidos.dart';
import 'package:enam_app/features/session/data/session_repository.dart';
import 'package:enam_app/features/session/domain/session_models.dart';
import 'package:enam_app/features/session/presentation/session_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Los sonidos (los de Rumbo) y sus reglas.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Resultado', () {
    test('con 11 o más, el bueno; por debajo, el malo', () {
      expect(sonidoDeResultado(nota: 11), Sonido.buenResultado);
      expect(sonidoDeResultado(nota: 20), Sonido.buenResultado);
      expect(sonidoDeResultado(nota: 10.99), Sonido.malResultado);
      expect(sonidoDeResultado(nota: 0), Sonido.malResultado);
    });
  });

  group('Preferencia', () {
    test('por defecto, activos a 0,6, como en Rumbo', () {
      const p = PreferenciasSonido();
      expect(p.activo, isTrue);
      expect(p.volumen, 0.6);
    });

    test('apagados, no suena nada', () async {
      final oido = _Oido();
      final c = ProviderContainer(
        overrides: [
          reproductoresDeSonido.overrideWithValue([oido]),
        ],
      );
      addTearDown(c.dispose);

      await c.read(preferenciasSonidoProvider.notifier).cambiarActivo(false);
      for (final s in Sonido.values) {
        await c.read(sonidosProvider).sonar(s);
      }
      expect(oido.oidos, isEmpty);
    });

    test('el volumen elegido es el que suena, y se guarda', () async {
      final oido = _Oido();
      final c = ProviderContainer(
        overrides: [
          reproductoresDeSonido.overrideWithValue([oido]),
        ],
      );
      addTearDown(c.dispose);

      await c.read(preferenciasSonidoProvider.notifier).cambiarVolumen(0.3);
      await c.read(sonidosProvider).sonar(Sonido.toque);

      expect(oido.volumenes.single, 0.3);
      expect(
        (await SharedPreferences.getInstance()).getDouble('sonido_volumen'),
        0.3,
      );
    });
  });

  group('Acierto y fallo solo cuando se revela', () {
    late MockSessionRepository repo;
    late _Oido oido;
    late ProviderContainer c;

    setUp(() {
      repo = MockSessionRepository();
      oido = _Oido();
      c = ProviderContainer(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(repo),
          sonidosProvider.overrideWithValue(Sonidos(reproductores: [oido])),
        ],
      );
      addTearDown(c.dispose);
    });

    Future<void> responderLaPrimera(String id) async {
      final estado = await c.read(sessionControllerProvider(id).future);
      final control = c.read(sessionControllerProvider(id).notifier)
        ..seleccionar(estado.pregunta.opciones.first.id);
      await control.responder();
    }

    test('en la práctica suena el acierto o el fallo', () async {
      final sesion = await repo.startPractice(
        const PracticeConfig(cantidadPreguntas: 3),
      );
      await responderLaPrimera(sesion.id);

      expect(oido.oidos.single, anyOf(Sonido.acierto, Sonido.fallo));
    });

    test('en el simulacro, nunca: delataría la clave (RF-16)', () async {
      final sesion = await repo.startSimulacro(esMuestra: true);
      await responderLaPrimera(sesion.id);

      expect(oido.oidos, isNot(contains(Sonido.acierto)));
      expect(oido.oidos, isNot(contains(Sonido.fallo)));
    });
  });

  test('los siete archivos existen y pesan menos de 200 KB juntos', () {
    // Si alguien añade un sonido o cambia un archivo, que sea a propósito.
    expect(Sonido.values, hasLength(7));
    var total = 0;
    for (final s in Sonido.values) {
      final archivo = File('assets/${s.archivo}');
      expect(archivo.existsSync(), isTrue, reason: s.archivo);
      total += archivo.lengthSync();
    }
    expect(total, lessThan(200 * 1024));
  });
}

class _Oido implements Reproductor {
  final oidos = <Sonido>[];
  final volumenes = <double>[];

  @override
  Future<void> reproducir(String archivo, double volumen) async {
    oidos.add(Sonido.values.firstWhere((s) => s.archivo == archivo));
    volumenes.add(volumen);
  }

  @override
  Future<void> cerrar() async {}
}
