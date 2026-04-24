import '../../../core/network/clients/pet_dictionaries_api_client.dart';
import '../../../core/network/models/catalog_models.dart';
import '../../../core/storage/shared_preferences_service.dart';
import 'catalog_cache_models.dart';

class PetDictionariesRepository {
  PetDictionariesRepository({
    required PetDictionariesApiClient api,
    required SharedPreferencesService sharedPreferences,
  })  : _api = api,
        _sharedPreferences = sharedPreferences;

  final PetDictionariesApiClient _api;
  final SharedPreferencesService _sharedPreferences;

  static const _cacheKey = 'catalog_snapshot_v3';

  Future<CatalogSnapshot?> readCached() async {
    final json = await _sharedPreferences.readJson(_cacheKey);
    if (json == null) return null;
    return CatalogSnapshot.fromJson(json);
  }

  Future<CatalogSnapshot> syncCatalog() async {
    final cached = await readCached();

    try {
      final dictionaries = await _api.getPetDictionaries();
      final snapshot = _buildSnapshot(dictionaries, locale: 'ru');

      await _sharedPreferences.writeJson(_cacheKey, snapshot.toJson());
      return snapshot;
    } catch (_) {
      if (cached != null) return cached;
      rethrow;
    }
  }

  CatalogSnapshot _buildSnapshot(
    PetDictionariesResponse dictionaries, {
    required String locale,
  }) {
    final species = dictionaries.species
        .where((item) => item.isActive)
        .toList(growable: false)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final breeds = dictionaries.breeds
        .where((item) => item.isActive)
        .toList(growable: false)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final colors = dictionaries.colorPresets
        .where((item) => item.isActive)
        .toList(growable: false)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final patterns = dictionaries.patterns
        .where((item) => item.isActive)
        .toList(growable: false)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return CatalogSnapshot(
      version: dictionaries.version,
      species: species
          .map(
            (item) => CatalogOption(
              id: item.id,
              name: item.localizedName(locale: locale),
              iconName: item.iconKey,
            ),
          )
          .toList(growable: false),
      breeds: breeds
          .map(
            (item) => CatalogBreedOption(
              id: item.id,
              speciesId: item.speciesId,
              name: item.localizedName(locale: locale),
            ),
          )
          .toList(growable: false),
      colors: colors
          .map(
            (item) => CatalogColorOption(
              id: item.id,
              name: item.localizedName(locale: locale),
              hex: item.hex,
            ),
          )
          .toList(growable: false),
      patterns: patterns
          .map(
            (item) => CatalogPatternOption(
              id: item.id,
              name: item.localizedName(locale: locale),
              iconKey: item.iconKey ?? 'pattern_default',
            ),
          )
          .toList(growable: false),
    );
  }
}
