import '../../../core/error/failure.dart';
import '../../offline/data/almacen_offline.dart';
import '../domain/catalog_models.dart';
import 'catalog_repository.dart';

/// El temario, con una copia en el teléfono.
///
/// Sin esto, el modo sin conexión se cae antes de empezar: para practicar hay
/// que elegir un área, y la lista de áreas venía siempre del servidor. Alguien
/// con Medicina descargada y sin señal veía la pantalla de error y no llegaba
/// nunca a sus preguntas.
///
/// Se guarda **en claro**: son nombres de áreas, temas y sus pesos, lo mismo
/// que enseña la app a cualquiera que la abra. Lo que sí se cifra son las
/// preguntas, que es el contenido por el que se paga.
///
/// La copia se refresca en cada consulta con éxito, así que estar al día no
/// cuesta una petición extra.
class CatalogRepositoryConRespaldo implements CatalogRepository {
  CatalogRepositoryConRespaldo({
    required CatalogRepository remoto,
    required AlmacenOffline almacen,
    required String usuarioId,
  }) : _remoto = remoto,
       _almacen = almacen,
       _usuario = usuarioId;

  final CatalogRepository _remoto;
  final AlmacenOffline _almacen;
  final String _usuario;

  @override
  Future<List<CatalogNode>> tree() async {
    try {
      final arbol = await _remoto.tree();
      await _almacen.guardarCatalogo(_usuario, [
        for (final nodo in arbol) nodo.toJson(),
      ]);
      return arbol;
    } on Failure catch (e) {
      if (e is! NetworkFailure && e is! TimeoutFailure) rethrow;

      final guardado = await _almacen.catalogo(_usuario);
      if (guardado == null) rethrow;

      return [
        for (final nodo in guardado)
          CatalogNode.fromJson(nodo as Map<String, dynamic>),
      ];
    }
  }
}
