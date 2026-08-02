import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/block/aes.dart';
import 'package:pointycastle/block/modes/gcm.dart';

/// Dónde vive la llave.
///
/// Es una interfaz mínima y no `FlutterSecureStorage` a secas para que el
/// cifrado se pueda probar sin dispositivo: el plugin cambia la firma de sus
/// métodos entre versiones mayores, y heredar de él para hacer un doble deja
/// las pruebas atadas a esa firma.
abstract interface class AlmacenDeLlaves {
  Future<String?> leer(String nombre);
  Future<void> guardar(String nombre, String valor);
  Future<void> borrar(String nombre);
}

/// El Keychain (iOS) / Keystore (Android), que es donde debe estar.
class AlmacenEnKeychain implements AlmacenDeLlaves {
  const AlmacenEnKeychain({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) : _storage = storage;

  final FlutterSecureStorage _storage;

  @override
  Future<String?> leer(String nombre) => _storage.read(key: nombre);

  @override
  Future<void> guardar(String nombre, String valor) =>
      _storage.write(key: nombre, value: valor);

  @override
  Future<void> borrar(String nombre) => _storage.delete(key: nombre);
}

/// Cifra lo que la app guarda en disco: los paquetes para estudiar sin
/// conexión (RF-30).
///
/// **Por qué existe.** Un paquete es el banco de preguntas de un área *con sus
/// claves y explicaciones* —sin ellas no se puede corregir sin conexión, así
/// que es un intercambio consciente del servidor (`offline.PaqueteDeArea`)—. En
/// texto plano dentro de la base de datos, cualquiera con acceso al archivo se
/// lleva el contenido entero de un área.
///
/// **Qué protege y qué no.** Esto frena la copia casual: sacar el respaldo del
/// teléfono, mirar el archivo con un explorador, un `adb pull` en un equipo sin
/// root. **No** frena a quien controla el dispositivo: si el sistema entrega la
/// llave a la app, se la puede entregar a un atacante con root o con la app
/// instrumentada. Ninguna protección del cliente hace lo contrario; el cliente
/// siempre acaba viendo lo que muestra. Por eso la barrera de verdad sigue
/// siendo el servidor: el paquete es solo para premium (`ErrSoloPremium`).
///
/// **Decisiones:**
/// - **AES-256-GCM**, que además de cifrar autentica: un byte cambiado en la
///   base de datos hace fallar el descifrado en vez de devolver basura.
/// - La llave se genera **en el dispositivo** con [Random.secure] y vive en el
///   Keychain / Keystore vía `flutter_secure_storage`. No está en el binario,
///   así que desarmar el APK no la da.
/// - Hay **una llave por usuario**: si en el mismo teléfono entra otra cuenta,
///   no puede leer los paquetes de la anterior aunque el archivo siga ahí.
/// - El nonce es **aleatorio y distinto en cada cifrado**, y viaja delante del
///   texto cifrado. Repetir un nonce con la misma llave es el único error que
///   rompe GCM del todo.
class CifradoLocal {
  CifradoLocal({AlmacenDeLlaves? almacen})
    : _almacen = almacen ?? const AlmacenEnKeychain();

  final AlmacenDeLlaves _almacen;

  /// AES-256.
  static const _bytesDeLlave = 32;

  /// 96 bits, el tamaño recomendado para GCM: es el que el estándar considera
  /// nativo y el que evita el paso extra de derivación del nonce.
  static const _bytesDeNonce = 12;

  /// 128 bits de etiqueta de autenticación, el máximo de GCM.
  static const _bitsDeEtiqueta = 128;

  static const _prefijoDeLlave = 'enam.clave_offline.';

  /// Llaves ya leídas, para no ir al Keychain en cada pregunta que se corrige.
  final Map<String, Uint8List> _cache = {};

  final Random _aleatorio = Random.secure();

  /// La llave de [usuarioId], creándola la primera vez.
  Future<Uint8List> _llaveDe(String usuarioId) async {
    final cacheada = _cache[usuarioId];
    if (cacheada != null) return cacheada;

    final nombre = '$_prefijoDeLlave$usuarioId';
    final guardada = await _almacen.leer(nombre);
    if (guardada != null) {
      final bytes = base64Decode(guardada);
      if (bytes.length == _bytesDeLlave) return _cache[usuarioId] = bytes;
      // Una llave con el tamaño mal es una llave que no sirve: se descarta y
      // se genera otra. Los paquetes cifrados con ella dejan de leerse, que es
      // justo lo que queremos —se vuelven a descargar—.
    }

    final nueva = _bytesAleatorios(_bytesDeLlave);
    await _almacen.guardar(nombre, base64Encode(nueva));
    return _cache[usuarioId] = nueva;
  }

  Uint8List _bytesAleatorios(int cuantos) {
    final bytes = Uint8List(cuantos);
    for (var i = 0; i < cuantos; i++) {
      bytes[i] = _aleatorio.nextInt(256);
    }
    return bytes;
  }

  /// Cifra [texto] para [usuarioId]. Devuelve `nonce || cifrado+etiqueta`.
  Future<Uint8List> cifrar(String usuarioId, String texto) async {
    final llave = await _llaveDe(usuarioId);
    final nonce = _bytesAleatorios(_bytesDeNonce);

    final cifrador = _motor(llave, nonce, cifrando: true);
    final cifrado = cifrador.process(Uint8List.fromList(utf8.encode(texto)));

    return Uint8List.fromList([...nonce, ...cifrado]);
  }

  /// Descifra lo que devolvió [cifrar].
  ///
  /// Lanza [DatoIlegible] si la llave no corresponde, si el contenido fue
  /// alterado o si el bloque está truncado. Quien llama debe tratar eso como
  /// «hay que volver a descargar», nunca como un error que se le enseña al
  /// usuario tal cual.
  Future<String> descifrar(String usuarioId, Uint8List bloque) async {
    if (bloque.length <= _bytesDeNonce) {
      throw const DatoIlegible('El dato guardado está incompleto.');
    }

    final llave = await _llaveDe(usuarioId);
    final nonce = Uint8List.sublistView(bloque, 0, _bytesDeNonce);
    final cifrado = Uint8List.sublistView(bloque, _bytesDeNonce);

    try {
      final descifrador = _motor(llave, nonce, cifrando: false);
      return utf8.decode(descifrador.process(cifrado));
    } on InvalidCipherTextException catch (e) {
      throw DatoIlegible('El dato guardado no se pudo verificar.', e);
    } on ArgumentError catch (e) {
      // utf8.decode con bytes que no son texto: pasa si el bloque venía de
      // otra llave y aun así pasó la verificación, que es prácticamente
      // imposible, pero no cuesta nada cubrirlo.
      throw DatoIlegible('El dato guardado no es legible.', e);
    }
  }

  GCMBlockCipher _motor(
    Uint8List llave,
    Uint8List nonce, {
    required bool cifrando,
  }) {
    return GCMBlockCipher(AESEngine())..init(
      cifrando,
      AEADParameters(KeyParameter(llave), _bitsDeEtiqueta, nonce, Uint8List(0)),
    );
  }

  /// Borra la llave de [usuarioId].
  ///
  /// Se llama al cerrar sesión. Sin la llave, lo que quede en la base de datos
  /// es ruido: aunque el borrado de las filas fallara a medias, el contenido no
  /// se puede recuperar.
  Future<void> olvidar(String usuarioId) async {
    _cache.remove(usuarioId);
    await _almacen.borrar('$_prefijoDeLlave$usuarioId');
  }
}

/// Lo guardado no se puede leer: llave distinta, dato alterado o truncado.
class DatoIlegible implements Exception {
  const DatoIlegible(this.mensaje, [this.causa]);

  final String mensaje;
  final Object? causa;

  @override
  String toString() => 'DatoIlegible: $mensaje';
}
