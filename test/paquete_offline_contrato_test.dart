import 'dart:convert';
import 'dart:io';

import 'package:enam_app/features/offline/domain/offline_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// El paquete que descarga el modo sin conexión, contra la respuesta REAL.
///
/// El JSON de `test/fixtures/paquete_offline_real.json` está copiado de
/// `GET /offline/packages/medicina` tal cual lo devuelve el servidor, recortado
/// a dos preguntas. Es la misma técnica que destapó que los exámenes pasados
/// modelaban campos que no existían: `fromJson` ignora las claves que no conoce
/// y rellena las que faltan con su valor por defecto, así que un contrato que
/// se separa no falla — se queda en blanco y nadie se entera.
void main() {
  late PaqueteOffline paquete;

  setUpAll(() {
    final crudo = File('test/fixtures/paquete_offline_real.json').readAsStringSync();
    paquete = PaqueteOffline.fromJson(jsonDecode(crudo) as Map<String, dynamic>);
  });

  test('se leen los campos del paquete', () {
    expect(paquete.areaId, 'medicina');
    expect(paquete.total, 2);
    expect(paquete.preguntas, hasLength(2));
    expect(paquete.generadoEn.year, greaterThan(2020));
  });

  test('las preguntas llegan con su enunciado y sus alternativas', () {
    final p = paquete.preguntas.first;

    expect(p.id, isNotEmpty);
    expect(p.enunciado, isNotEmpty);
    expect(p.opciones, isNotEmpty);
  });

  test('vienen REVELADAS: sin la clave no se puede corregir sin señal', () {
    // Es la razón de que el paquete sea solo premium. Si llegaran sin clave, la
    // práctica offline no podría dar feedback y el modo entero no serviría.
    final p = paquete.preguntas.first;

    expect(
      p.opciones.any((o) => o.esCorrecta == true),
      isTrue,
      reason: 'ninguna alternativa viene marcada como correcta',
    );
    expect(p.explicacion, isNotNull, reason: 'sin explicación no hay repaso');
  });

  test('traen su área, para poder filtrar sin servidor', () {
    // Durante un simulacro el servidor la manda en null (RN-09), pero aquí no:
    // sin ella no se podría armar una práctica por área estando sin señal.
    expect(paquete.preguntas.first.areaId, isNotNull);
  });
}
