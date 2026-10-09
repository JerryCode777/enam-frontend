/// Una universidad del catálogo (`GET /api/v1/catalog/universidades`).
///
/// Las 143 del Perú, con las 42 que tienen Medicina primero. El `id` es lo
/// que se guarda en el perfil; el `nombre` es lo que se muestra.
class Universidad {
  const Universidad({
    required this.id,
    required this.nombre,
    this.siglas,
    this.region = '',
    this.gestion = '',
    this.medicina = false,
    this.licenciada = false,
  });

  factory Universidad.fromJson(Map<String, dynamic> json) => Universidad(
    id: json['id'] as String,
    nombre: json['nombre'] as String,
    siglas: json['siglas'] as String?,
    region: json['region'] as String? ?? '',
    gestion: json['gestion'] as String? ?? '',
    medicina: json['medicina'] as bool? ?? false,
    licenciada: json['licenciada'] as bool? ?? false,
  );

  final String id;
  final String nombre;

  /// `null` en las que SUNEDU no publica con siglas: a esas se llega por
  /// nombre.
  final String? siglas;

  /// Departamento de la sede principal.
  final String region;

  /// `publica` o `privada`.
  final String gestion;
  final bool medicina;
  final bool licenciada;

  Map<String, Object?> toJson() => {
    'id': id,
    'nombre': nombre,
    'siglas': siglas,
    'region': region,
    'gestion': gestion,
    'medicina': medicina,
    'licenciada': licenciada,
  };
}

/// El id que el servidor entiende como «no está en la lista»: va con el
/// nombre escrito por la persona.
const idOtraUniversidad = 'otra';

/// Lo que se elige en el buscador: una del catálogo, u «Otra» con su nombre.
typedef EleccionDeUniversidad = ({String id, String nombre});

/// Minúsculas y sin tildes: «San Agustín», «SAN AGUSTIN» y «san agustin» son
/// la misma búsqueda.
String normalizar(String texto) {
  const con = 'áàäâéèëêíìïîóòöôúùüûñç';
  const sin = 'aaaaeeeeiiiioooouuuunc';
  final b = StringBuffer();
  for (final c in texto.toLowerCase().split('')) {
    final i = con.indexOf(c);
    b.write(i >= 0 ? sin[i] : c);
  }
  return b.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Filtra por nombre o siglas. Cada palabra de la búsqueda tiene que aparecer
/// (en cualquier orden): «san marcos» encuentra la Mayor de San Marcos.
/// Conserva el orden del catálogo, con Medicina primero.
List<Universidad> buscarUniversidades(
  List<Universidad> catalogo,
  String busqueda,
) {
  final palabras = normalizar(busqueda).split(' ').where((p) => p.isNotEmpty);
  if (palabras.isEmpty) return catalogo;
  return [
    for (final u in catalogo)
      if (palabras.every(
        (p) =>
            normalizar(u.nombre).contains(p) ||
            normalizar(u.siglas ?? '').contains(p),
      ))
        u,
  ];
}
