import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/providers.dart';
import '../data/universidades_repository.dart';
import '../domain/universidad.dart';

final universidadesRepositoryProvider = Provider<UniversidadesRepository>((
  ref,
) {
  if (AppConfig.useMocks) return MockUniversidadesRepository();
  return ApiUniversidadesRepository(ref.watch(apiClientProvider));
});

/// El catálogo, una vez por sesión de la app (y con su copia de un día en el
/// teléfono, ver el repositorio).
final universidadesProvider = FutureProvider<List<Universidad>>(
  (ref) => ref.watch(universidadesRepositoryProvider).catalogo(),
);

/// El nombre que se muestra: el del catálogo por [id] si está cargado; si no,
/// el texto guardado. Así una universidad elegida por id se ve con su nombre
/// oficial aunque el perfil guardara otro texto.
String? nombreDeUniversidad(
  List<Universidad>? catalogo, {
  String? id,
  String? texto,
}) {
  if (id != null && catalogo != null) {
    for (final u in catalogo) {
      if (u.id == id) return u.nombre;
    }
  }
  return texto;
}

/// Una etiqueta corta para donde no cabe un nombre de 76 caracteres (el
/// podio del ranking): las siglas del catálogo si la universidad las tiene; si
/// no, el texto tal cual. Reconoce el nombre oficial y las siglas, con o sin
/// tildes, y así sirve con los nombres largos que manda ahora el servidor y
/// con las siglas de antes.
String etiquetaCortaDeUniversidad(List<Universidad>? catalogo, String texto) {
  if (catalogo == null) return texto;
  final buscado = normalizar(texto);
  for (final u in catalogo) {
    if (normalizar(u.nombre) == buscado ||
        normalizar(u.siglas ?? '') == buscado) {
      return u.siglas ?? u.nombre;
    }
  }
  return texto;
}
