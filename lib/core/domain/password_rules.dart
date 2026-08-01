/// Las reglas de la contraseña, en un solo sitio.
///
/// Estaban repetidas en tres pantallas —registro, nueva contraseña y cambiar
/// contraseña— cada una con su propia constante. Tres copias de un número que
/// el servidor también tiene es un desajuste esperando a ocurrir: si una sube
/// y las otras no, el usuario escribe algo que el formulario acepta y el
/// servidor rechaza con un 422 que no explica nada.
///
/// **Tiene que coincidir con `LargoMinimoContrasena` del backend**
/// (`internal/auth/fortaleza.go`). Si allí cambia, aquí también.
///
/// No se exige mayúscula ni símbolo a propósito: el NIST retiró esa
/// recomendación en la SP 800-63B porque la complejidad obligatoria produce
/// patrones predecibles —"Password1!" cumple cualquier regla de tipos y está en
/// todos los diccionarios—. Lo que filtra de verdad es la longitud, y de eso se
/// encarga el servidor además con su lista de contraseñas conocidas.
abstract final class PasswordRules {
  /// Caracteres mínimos. El servidor exige lo mismo.
  static const int minimo = 8;

  /// Si cumple el largo exigido.
  static bool largoOk(String password) => password.length >= minimo;

  /// El motivo por el que no vale, o `null` si está bien.
  ///
  /// Devuelve texto listo para pintar bajo el campo: el usuario necesita saber
  /// qué le falta, no que "no cumple".
  static String? motivo(String password) {
    if (password.isEmpty) return 'Crea una contraseña.';
    if (!largoOk(password)) return 'Debe tener al menos $minimo caracteres.';
    return null;
  }

  /// Lo que se muestra bajo el campo antes de escribir nada.
  static String get ayuda => 'Mínimo $minimo caracteres';
}
