import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Nadie apila una ruta a mano: se navega con `context.irA(...)`.
///
/// ## Qué evita
///
/// Las pestañas viven en un `StatefulShellRoute` y cada una tiene su Navigator
/// con una `GlobalKey`. Un `push` de una ruta que vive ahí dentro monta un
/// segundo Navigator con la misma llave y la app muere con pantalla roja. Pasó
/// en el temario, en «Seguir» del inicio, en el simulacro nacional y al empezar
/// un examen pasado.
///
/// ## Por qué esta regla y no la anterior
///
/// Antes esta prueba llevaba **dos listas escritas a mano**: qué rutas estaban
/// dentro del contenedor y qué pantallas podían saltarse la comprobación. Eso
/// convierte cada pantalla nueva en una oportunidad de que la lista se quede
/// vieja, y la prueba en algo que hay que recordar actualizar —el mismo
/// problema que pretendía resolver—.
///
/// Ahora la decisión la toma `irA` preguntándole al router en tiempo de
/// ejecución (ver `lib/core/router/navegar.dart`, probado en
/// `navegar_test.dart`). Aquí solo queda comprobar que se usa: sin listas que
/// mantener y sin excepciones que recordar.
///
/// `go` y `pushReplacement` siguen permitidos: reemplazan la pantalla actual y
/// ninguno de los dos puede duplicar el Navigator. Para las pantallas que
/// devuelven algo —el selector de áreas— está `irAPorUnResultado`, que apila
/// porque no hay otra forma de esperar un resultado, y comprueba con un
/// `assert` que el destino no viva en las pestañas.
void main() {
  test('ninguna pantalla apila una ruta a mano', () {
    final infracciones = <String>[];

    for (final archivo in Directory('lib').listSync(recursive: true)) {
      if (archivo is! File || !archivo.path.endsWith('.dart')) continue;

      final texto = archivo.readAsStringSync();

      // Se busca la sentencia entera y no la línea: el formateador parte
      // `context.push(\n  Routes.x(id),\n)` en tres, y línea a línea el caso
      // más largo —que es justo el que se escapó— no se ve.
      for (final coincidencia in RegExp(
        r'(?<!irAPorUnResultado)\.push(?:<[^>]*>)?\(',
      ).allMatches(texto)) {
        final hasta = (coincidencia.end + 120).clamp(0, texto.length);
        if (!texto.substring(coincidencia.end, hasta).contains('Routes.')) {
          continue;
        }

        final linea =
            '\n'.allMatches(texto.substring(0, coincidencia.start)).length + 1;
        infracciones.add('${archivo.path}:$linea');
      }
    }

    expect(
      infracciones,
      isEmpty,
      reason:
          'Estas líneas apilan una ruta a mano. Si la ruta vive en el '
          'contenedor de pestañas, tumban la app. Usa `context.irA(...)`, que '
          'lo decide sola:\n  ${infracciones.join('\n  ')}',
    );
  });

  test('el ayudante existe y es el único que apila rutas', () {
    final navegar = File(
      'lib/core/router/navegar.dart',
    ).readAsStringSync();

    // Si alguien lo reescribe con una lista de rutas, la regla vuelve a
    // depender de que esa lista esté al día, que es lo que se quería quitar.
    expect(
      navegar,
      contains('findMatch'),
      reason: 'irA tiene que preguntarle al router, no a una lista escrita a '
          'mano',
    );
  });
}
