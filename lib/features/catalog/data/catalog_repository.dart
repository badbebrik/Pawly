import '../../../core/network/clients/catalog_api_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import 'catalog_cache_models.dart';

class CatalogRepository {
  CatalogRepository({
    required CatalogApiClient api,
    required SecureStorageService storage,
  })  : _api = api,
        _storage = storage;

  final CatalogApiClient _api;
  final SecureStorageService _storage;

  static const _cacheKey = 'catalog_snapshot_v1';

  Future<CatalogSnapshot?> readCached() async {
    final json = await _storage.readJson(_cacheKey);
    if (json == null) return null;
    return CatalogSnapshot.fromJson(json);
  }

  Future<CatalogSnapshot> syncCatalog() async {
    final cached = await readCached();

    try {
      final version = (await _api.getVersion()).version;

      if (cached != null && cached.version == version) {
        return cached;
      }

      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        _api.listSpecies(activeOnly: true),
        _api.listBreeds(activeOnly: true),
        _api.listColors(activeOnly: true),
        _api.listPatterns(activeOnly: true),
      ]);

      final species = results[0] as List;
      final breeds = results[1] as List;
      final colors = results[2] as List;
      final patterns = results[3] as List;

      final snapshot = CatalogSnapshot(
        version: version,
        species: species
            .map(
              (e) => CatalogOption(
                id: e.id,
                name: e.name,
                iconName: _iconForSpecies(e.name),
              ),
            )
            .toList(growable: false),
        breeds: breeds
            .map(
              (e) => CatalogBreedOption(
                id: e.id,
                speciesId: e.speciesId,
                name: e.name,
              ),
            )
            .toList(growable: false),
        colors: colors
            .map(
              (e) => CatalogColorOption(
                id: e.id,
                name: e.name,
                hex: e.hex,
              ),
            )
            .toList(growable: false),
        patterns: patterns
            .map(
              (e) => CatalogPatternOption(
                id: e.id,
                name: e.name,
                iconKey: e.iconKey,
              ),
            )
            .toList(growable: false),
      );

      await _storage.writeJson(_cacheKey, snapshot.toJson());
      return snapshot;
    } catch (_) {
      if (cached != null) return cached;
      rethrow;
    }
  }

  String _iconForSpecies(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('cat') || lower.contains('кош')) return 'cat';
    if (lower.contains('dog') || lower.contains('соб')) return 'dog';
    if (lower.contains('bird') || lower.contains('пти')) return 'bird';
    return 'paw';
  }
}
