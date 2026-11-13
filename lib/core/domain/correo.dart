/// Correos mal escritos al registrarse: `gmail.con`, `hotmial.com`,
/// `outlok.es`. El código de verificación no llega, y la persona se registra
/// otra vez con otro correo (28 casos en 30 días, casi todos desde la app).
///
/// La misma regla que el servidor (`internal/auth/sugerencia_correo.go`): si
/// allí cambia, aquí también. Aquí se usa antes de crear la cuenta y sin red.
library;

/// Los dominios que de verdad usa el público. En empate gana el primero.
const _destinos = [
  'gmail.com',
  'hotmail.com',
  'outlook.com',
  'outlook.es',
  'hotmail.es',
  'yahoo.com',
  'yahoo.es',
  'icloud.com',
  'live.com',
];

/// Universidades: solo a una letra de distancia (`umsaac` → `unsaac`).
const _universidades = [
  'unsa.edu.pe',
  'unsaac.edu.pe',
  'unmsm.edu.pe',
  'unap.edu.pe',
  'unp.edu.pe',
  'unitru.edu.pe',
  'ucsm.edu.pe',
  'pucp.edu.pe',
  'upch.pe',
];

/// Dominios reales que están cerca de uno de los de arriba: no se corrigen.
const _reales = {
  'mail.com',
  'email.com',
  'gmx.com',
  'ymail.com',
  'googlemail.com',
  'msn.com',
  'me.com',
  'mac.com',
  'aol.com',
  'live.com.pe',
  'yahoo.com.pe',
  'hotmail.com.pe',
  'outlook.com.pe',
  'proton.me',
  'protonmail.com',
};

/// Terminaciones mal escritas, si el nombre no se parece a ninguno conocido.
/// `.co` no está: es Colombia, y es real.
const _terminaciones = {
  '.con': '.com',
  '.cmo': '.com',
  '.cm': '.com',
  '.comm': '.com',
  '.coom': '.com',
  '.vom': '.com',
  '.xom': '.com',
  '.cpm': '.com',
  '.ocm': '.com',
  '.con.pe': '.com.pe',
  '.edu.p': '.edu.pe',
  '.edu.per': '.edu.pe',
};

/// El correo corregido si el dominio parece un error de tipeo; `null` si se
/// ve bien o no se parece a nada conocido.
///
/// Es solo una sugerencia: la persona siempre puede decir que el suyo está
/// bien.
String? sugerenciaDeCorreo(String correo) {
  final texto = correo.trim();
  final arroba = texto.lastIndexOf('@');
  if (arroba <= 0 || arroba == texto.length - 1) return null;
  final usuario = texto.substring(0, arroba);
  final dominio = texto.substring(arroba + 1).toLowerCase();

  final sugerido = _dominioSugerido(dominio);
  return sugerido == null || sugerido == dominio ? null : '$usuario@$sugerido';
}

String? _dominioSugerido(String dominio) {
  if (_destinos.contains(dominio) ||
      _universidades.contains(dominio) ||
      _reales.contains(dominio)) {
    return null;
  }

  // El conocido más cercano. Los largos toleran dos letras (`gmail.comgr`).
  for (final (lista, tolerada) in [
    (_destinos, (String d) => d.length >= 9 ? 2 : 1),
    (_universidades, (String _) => 1),
  ]) {
    String? mejor;
    var menor = 99;
    for (final c in lista) {
      final d = _distancia(dominio, c);
      if (d <= tolerada(c) && d < menor) {
        menor = d;
        mejor = c;
      }
    }
    if (mejor != null) return mejor;
  }

  // Si no, solo la terminación.
  for (final MapEntry(key: mala, value: buena) in _terminaciones.entries) {
    if (dominio.endsWith(mala) && dominio.length > mala.length) {
      return dominio.substring(0, dominio.length - mala.length) + buena;
    }
  }
  return null;
}

/// Damerau-Levenshtein (con transposiciones de letras vecinas): `gmial` está
/// a uno de `gmail`, no a dos.
int _distancia(String a, String b) {
  final d = List.generate(a.length + 1, (_) => List.filled(b.length + 1, 0));
  for (var i = 0; i <= a.length; i++) {
    d[i][0] = i;
  }
  for (var j = 0; j <= b.length; j++) {
    d[0][j] = j;
  }
  for (var i = 1; i <= a.length; i++) {
    for (var j = 1; j <= b.length; j++) {
      final costo = a[i - 1] == b[j - 1] ? 0 : 1;
      var v = [
        d[i - 1][j] + 1,
        d[i][j - 1] + 1,
        d[i - 1][j - 1] + costo,
      ].reduce((x, y) => x < y ? x : y);
      if (i > 1 &&
          j > 1 &&
          a[i - 1] == b[j - 2] &&
          a[i - 2] == b[j - 1] &&
          d[i - 2][j - 2] + 1 < v) {
        v = d[i - 2][j - 2] + 1;
      }
      d[i][j] = v;
    }
  }
  return d[a.length][b.length];
}
