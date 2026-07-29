import '../../../core/config/api_endpoints.dart';
import '../../../core/mock/mock_data.dart';
import '../../../core/network/api_client.dart';
import '../domain/catalog_models.dart';

/// Taxonomía de áreas y subtemas con el progreso del usuario (`GET /catalog/areas`).
abstract interface class CatalogRepository {
  Future<List<Area>> areas();
}

class ApiCatalogRepository implements CatalogRepository {
  ApiCatalogRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<Area>> areas() async {
    final data = await _client.get<List<dynamic>>(ApiEndpoints.catalogAreas);
    return data
        .map((e) => Area.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }
}

class MockCatalogRepository implements CatalogRepository {
  List<Area>? _cache;

  @override
  Future<List<Area>> areas() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    // Se cachea para que el progreso no cambie en cada pantalla.
    return _cache ??= MockData.areas();
  }
}
