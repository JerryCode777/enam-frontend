import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Las clases son «clases», no «clases en video», y el temario es «el
/// temario», no «el temario oficial» (Jerry, 09/10/2026).
///
/// Mira los textos del código —también los que se parten en varias líneas—
/// y las notas para las tiendas. Los comentarios no cuentan.
void main() {
  const prohibidas = ['en video', 'temario oficial'];

  /// Un literal entre comillas simples, con los que le siguen pegados: así
  /// «'del temario ' 'oficial'» se lee como una sola frase.
  final literal = RegExp(r"'(?:[^'\\\n]|\\.)*'(?:\s*'(?:[^'\\\n]|\\.)*')*");

  List<String> textosDe(String codigo) {
    final sinComentarios = codigo
        .split('\n')
        .where((l) => !l.trimLeft().startsWith('//'))
        .join('\n');
    return [
      for (final m in literal.allMatches(sinComentarios))
        m
            .group(0)!
            .split(RegExp(r"'\s*'"))
            .join()
            .replaceAll("'", '')
            .toLowerCase(),
    ];
  }

  test('ningún texto de la app dice «en video» ni «temario oficial»', () {
    final hallazgos = <String>[];
    final archivos = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where(
          (f) =>
              f.path.endsWith('.dart') &&
              !f.path.endsWith('.g.dart') &&
              !f.path.endsWith('.freezed.dart'),
        );
    for (final f in archivos) {
      for (final texto in textosDe(f.readAsStringSync())) {
        for (final p in prohibidas) {
          if (texto.contains(p)) hallazgos.add('${f.path}: «$texto»');
        }
      }
    }
    expect(hallazgos, isEmpty);
  });

  test('las notas para las tiendas tampoco', () {
    for (final f in Directory(
      'notas-de-version',
    ).listSync().whereType<File>()) {
      final texto = f.readAsStringSync().toLowerCase();
      for (final p in prohibidas) {
        expect(texto, isNot(contains(p)), reason: '«$p» en ${f.path}');
      }
    }
  });

  test('la regla ve los textos partidos en varias líneas', () {
    final textos = textosDe("""
      Text(
        'Clases en video del temario '
            'oficial, con su práctica',
      )
    """);
    expect(textos.single, contains('temario oficial'));
    expect(textos.single, contains('en video'));
    // Un comentario no es un texto de la app.
    expect(textosDe("// 'clases en video'"), isEmpty);
  });
}
