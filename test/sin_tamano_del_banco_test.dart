import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Ninguna pantalla dice cuántas preguntas tiene el banco, ni el total ni por
/// área o tema.
///
/// Pedido del usuario (06/10/2026), igual en la web: «tenemos muy poco, no se
/// debe mostrar explícitamente en ninguna sección; apenas ven eso se
/// desaniman». Lo que sí se muestra es lo que pesa cada área en el ENAM y lo
/// que la persona ya vio.
///
/// La regla mira el código de las pantallas: un texto que interpole el total
/// del banco o lo disponible en un nodo o un paquete falla aquí, antes de que
/// alguien lo vea. Usarlos para decidir (filtrar áreas sin preguntas, saber si
/// un paquete se puede actualizar) sigue permitido.
void main() {
  final enTexto = RegExp(
    r'\$\{?[^}\n]*\b(preguntasTotalesBanco|preguntasDisponibles|disponibles)\b',
  );

  final pantallas = [
    for (final dir in ['lib/features', 'lib/shared'])
      ...Directory(dir)
          .listSync(recursive: true)
          .whereType<File>()
          .where(
            (f) =>
                f.path.endsWith('.dart') &&
                (f.path.contains('/presentation/') ||
                    f.path.startsWith('lib/shared')),
          ),
  ];

  test('hay pantallas que revisar', () => expect(pantallas, isNotEmpty));

  test('ningún texto lleva el tamaño del banco', () {
    final hallazgos = <String>[];
    for (final f in pantallas) {
      final lineas = f.readAsLinesSync();
      for (final (i, linea) in lineas.indexed) {
        final codigo = linea.trimLeft();
        if (codigo.startsWith('//')) continue;
        if (enTexto.hasMatch(codigo)) hallazgos.add('${f.path}:${i + 1}');
      }
    }
    expect(hallazgos, isEmpty);
  });

  test('la regla detecta lo que tiene que detectar', () {
    expect(
      enTexto.hasMatch(r"'${area.preguntasDisponibles} preguntas'"),
      isTrue,
    );
    expect(enTexto.hasMatch(r"'de ${s.preguntasTotalesBanco}'"), isTrue);
    expect(
      enTexto.hasMatch(r"'En este nodo hay $disponibles preguntas'"),
      isTrue,
    );
    // Decidir con el dato no es mostrarlo.
    expect(enTexto.hasMatch('if (area.preguntasDisponibles == 0)'), isFalse);
  });
}
