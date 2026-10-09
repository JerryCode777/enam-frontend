import 'package:flutter_test/flutter_test.dart';
import 'package:enam_app/core/config/contacto.dart';

/// El número de atención.
///
/// Lo sirve el servidor para que cambiar de línea no obligue a publicar en dos
/// tiendas. Lo que se prueba aquí es sobre todo lo contrario de eso: que un
/// servidor mudo, viejo o mal configurado **no** pueda dejar el botón de ayuda
/// llevando a ninguna parte. Un botón de soporte roto es peor que uno con un
/// número desactualizado.
void main() {
  setUp(Contacto.restablecer);
  tearDown(Contacto.restablecer);

  test('sin decir nada, el número es el compilado y es real', () {
    expect(Contacto.soporteNumero, '51936415245');
    expect(Contacto.soporteVisible, '+51 936 415 245');
  });

  test('toma el número que sirve el servidor', () {
    Contacto.aplicar(numero: '51999888777', visible: '+51 999 888 777');

    expect(Contacto.soporteNumero, '51999888777');
    expect(Contacto.soporteVisible, '+51 999 888 777');
  });

  test('limpia lo que no sea dígito: wa.me no acepta espacios ni +', () {
    // El enlace se arma pegando el número a `wa.me/`. Un `+51 999...` ahí abre
    // WhatsApp con un chat vacío hacia nadie.
    Contacto.aplicar(numero: '+51 999-888-777', visible: '+51 999 888 777');

    expect(Contacto.soporteNumero, '51999888777');
  });

  group('no se deja romper por el servidor', () {
    // Cada uno de estos es una forma real de que la respuesta llegue a medias:
    // la variable de entorno sin poner, un despliegue viejo que no conoce el
    // campo, alguien que la escribe mal.
    for (final malo in ['', '   ', 'null', '+51', '12345']) {
      test('ignora ${malo.isEmpty ? '(vacío)' : malo}', () {
        Contacto.aplicar(numero: malo, visible: malo);

        expect(Contacto.soporteNumero, '51936415245');
        expect(Contacto.soporteVisible, '+51 936 415 245');
      });
    }

    test('con número bueno pero sin texto visible, se lo inventa', () {
      // Preferible a enseñar la cadena vacía en el mensaje de «escríbenos al…».
      Contacto.aplicar(numero: '51999888777', visible: '');

      expect(Contacto.soporteNumero, '51999888777');
      expect(Contacto.soporteVisible, '+51999888777');
    });
  });

  test('el enlace de soporte apunta al número aplicado', () {
    Contacto.aplicar(numero: '51999888777', visible: '+51 999 888 777');

    expect(Contacto.soporte(mensaje: 'Hola').toString(), contains('51999888777'));
  });
}
