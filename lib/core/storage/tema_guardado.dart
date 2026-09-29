import 'package:flutter/material.dart' show ThemeMode;
import 'package:shared_preferences/shared_preferences.dart';

/// El tema que eligió el usuario, guardado en el teléfono.
///
/// Va aparte de `AppPrefs` para no obligar a cada doble de pruebas de aquella
/// a implementar esto. No es dato sensible: `shared_preferences` basta.
class TemaGuardado {
  static const _clave = 'tema';

  Future<ThemeMode?> leer() async {
    final valor = (await SharedPreferences.getInstance()).getString(_clave);
    return ThemeMode.values.where((m) => m.name == valor).firstOrNull;
  }

  Future<void> guardar(ThemeMode modo) async =>
      (await SharedPreferences.getInstance()).setString(_clave, modo.name);
}
