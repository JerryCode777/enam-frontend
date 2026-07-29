import '../../../core/config/api_endpoints.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/network/api_client.dart';
import '../domain/catalog_models.dart';

/// Árbol del temario con el progreso del usuario (`GET /catalog/areas`).
///
/// Devuelve las 10 áreas como raíces; cada una trae su subárbol completo.
abstract interface class CatalogRepository {
  Future<List<CatalogNode>> tree();
}

class ApiCatalogRepository implements CatalogRepository {
  ApiCatalogRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<CatalogNode>> tree() async {
    final data = await _client.get<List<dynamic>>(ApiEndpoints.catalogAreas);
    return data
        .map((e) => CatalogNode.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }
}

class MockCatalogRepository implements CatalogRepository {
  List<CatalogNode>? _cache;

  @override
  Future<List<CatalogNode>> tree() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    // Se cachea para que el progreso no cambie entre pantallas.
    return _cache ??= MockData.catalog();
  }
}
