import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// El build de release de Android borra los recursos que el código nativo no
/// nombra, y los iconos de los avisos solo se nombran desde Dart. Sin
/// `keep.xml` el plugin fallaba con «invalid_icon» y en Android no se
/// programó ningún recordatorio (1.1.10 a 1.1.12).
void main() {
  test('cada icono de aviso nombrado en Dart está en keep.xml', () {
    final codigo = File(
      'lib/features/recordatorios/data/notificador.dart',
    ).readAsStringSync();
    final keep = File(
      'android/app/src/main/res/raw/keep.xml',
    ).readAsStringSync();

    final iconos = {
      for (final m in RegExp(
        r"""(?:icon: |AndroidInitializationSettings\()'(\w+)'""",
      ).allMatches(codigo))
        m.group(1)!,
    };
    expect(iconos, contains('ic_notificacion'));
    for (final icono in iconos) {
      expect(
        File('android/app/src/main/res/drawable/$icono.xml').existsSync(),
        isTrue,
        reason: icono,
      );
      expect(keep, contains('@drawable/$icono'), reason: icono);
    }
  });
}
