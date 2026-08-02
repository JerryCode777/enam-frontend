import 'dart:convert';
import 'dart:typed_data';

import 'package:enam_app/core/security/cifrado_local.dart';
import 'package:flutter_test/flutter_test.dart';

/// Un Keychain de mentira, para poder probar el cifrado sin dispositivo.
class _AlmacenEnMemoria implements AlmacenDeLlaves {
  _AlmacenEnMemoria(this._datos);

  final Map<String, String> _datos;

  @override
  Future<String?> leer(String nombre) async => _datos[nombre];

  @override
  Future<void> guardar(String nombre, String valor) async =>
      _datos[nombre] = valor;

  @override
  Future<void> borrar(String nombre) async => _datos.remove(nombre);
}

void main() {
  late Map<String, String> keychain;
  late CifradoLocal cifrado;

  setUp(() {
    keychain = {};
    cifrado = CifradoLocal(almacen: _AlmacenEnMemoria(keychain));
  });

  const paquete =
      '{"areaId":"medicina","preguntas":[{"id":"q1","enunciado":"Varón de 60 '
      'años con dolor torácico opresivo…","claveCorrecta":"b"}]}';

  test('lo cifrado se recupera igual', () async {
    final bloque = await cifrado.cifrar('usuario-1', paquete);

    expect(await cifrado.descifrar('usuario-1', bloque), paquete);
  });

  test('lo guardado no contiene el texto original', () async {
    final bloque = await cifrado.cifrar('usuario-1', paquete);

    // La comprobación que importa: que el enunciado no se lea en el archivo.
    expect(utf8.decode(bloque, allowMalformed: true), isNot(contains('dolor')));
    expect(utf8.decode(bloque, allowMalformed: true), isNot(contains('q1')));
  });

  test('dos cifrados del mismo texto son distintos', () async {
    final uno = await cifrado.cifrar('usuario-1', paquete);
    final otro = await cifrado.cifrar('usuario-1', paquete);

    // Nonce nuevo en cada cifrado. Repetirlo con la misma llave es el único
    // error que rompe GCM del todo.
    expect(uno, isNot(equals(otro)));
  });

  test('otro usuario del mismo teléfono no puede leerlo', () async {
    final bloque = await cifrado.cifrar('usuario-1', paquete);

    expect(
      () => cifrado.descifrar('usuario-2', bloque),
      throwsA(isA<DatoIlegible>()),
    );
  });

  test('un byte alterado se detecta', () async {
    final bloque = await cifrado.cifrar('usuario-1', paquete);
    final alterado = Uint8List.fromList(bloque)
      ..[bloque.length - 1] ^= 0x01;

    expect(
      () => cifrado.descifrar('usuario-1', alterado),
      throwsA(isA<DatoIlegible>()),
    );
  });

  test('un bloque truncado no revienta con otra excepción', () async {
    expect(
      () => cifrado.descifrar('usuario-1', Uint8List.fromList([1, 2, 3])),
      throwsA(isA<DatoIlegible>()),
    );
  });

  test('la llave sobrevive a reiniciar la app', () async {
    final bloque = await cifrado.cifrar('usuario-1', paquete);

    // Instancia nueva, mismo Keychain: es lo que pasa al abrir la app otra vez.
    final despues = CifradoLocal(almacen: _AlmacenEnMemoria(keychain));
    expect(await despues.descifrar('usuario-1', bloque), paquete);
  });

  test('cerrar sesión deja los paquetes ilegibles', () async {
    final bloque = await cifrado.cifrar('usuario-1', paquete);
    await cifrado.olvidar('usuario-1');

    // Sin la llave, lo que quede en la base de datos es ruido: se genera una
    // llave nueva y el bloque anterior ya no verifica.
    expect(
      () => cifrado.descifrar('usuario-1', bloque),
      throwsA(isA<DatoIlegible>()),
    );
  });

  test('cada instalación tiene su llave: no viaja en el binario', () async {
    await cifrado.cifrar('usuario-1', paquete);

    final otroKeychain = <String, String>{};
    final otroTelefono = CifradoLocal(almacen: _AlmacenEnMemoria(otroKeychain));
    final bloqueDelOtro = await otroTelefono.cifrar('usuario-1', paquete);

    expect(otroKeychain.values.single, isNot(keychain.values.single));
    // Y por lo tanto un paquete no se puede mover de un teléfono a otro.
    expect(
      () => cifrado.descifrar('usuario-1', bloqueDelOtro),
      throwsA(isA<DatoIlegible>()),
    );
  });
}
