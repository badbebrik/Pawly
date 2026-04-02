import '../api_client.dart';
import '../api_context.dart';
import '../api_endpoints.dart';
import '../models/catalog_models.dart';
import '../models/json_map.dart';
import '../models/json_parsers.dart';

class CatalogApiClient {
  CatalogApiClient(this._apiClient);

  final ApiClient _apiClient;

  static const _options = ApiRequestOptions(
    includeLocale: true,
    requiresAccessToken: true,
  );

  Future<CatalogVersionResponse> getVersion() async {
    final dictionaries = await _fetchDictionaries();
    return CatalogVersionResponse(version: dictionaries.version);
  }

  Future<List<SpeciesItem>> listSpecies({bool activeOnly = true}) async {
    final dictionaries = await _fetchDictionaries();
    return activeOnly
        ? dictionaries.species.where((item) => item.isActive).toList(
              growable: false,
            )
        : dictionaries.species;
  }

  Future<List<BreedItem>> listBreeds({
    bool activeOnly = true,
    String? speciesId,
  }) async {
    final dictionaries = await _fetchDictionaries();
    return dictionaries.breeds.where((item) {
      if (activeOnly && !item.isActive) return false;
      if (speciesId != null &&
          speciesId.isNotEmpty &&
          item.speciesId != speciesId) {
        return false;
      }
      return true;
    }).toList(
      growable: false,
    );
  }

  Future<List<ColorItem>> listColors({bool activeOnly = true}) async {
    final dictionaries = await _fetchDictionaries();
    return activeOnly
        ? dictionaries.colors.where((item) => item.isActive).toList(
              growable: false,
            )
        : dictionaries.colors;
  }

  Future<List<PatternItem>> listPatterns({bool activeOnly = true}) async {
    final dictionaries = await _fetchDictionaries();
    return activeOnly
        ? dictionaries.patterns.where((item) => item.isActive).toList(
              growable: false,
            )
        : dictionaries.patterns;
  }

  Future<_PetDictionariesCompatResponse> _fetchDictionaries() {
    return _apiClient.get<_PetDictionariesCompatResponse>(
      ApiEndpoints.petDictionaries,
      requestOptions: _options,
      decoder: _PetDictionariesCompatResponse.fromJson,
    );
  }
}

class _PetDictionariesCompatResponse {
  const _PetDictionariesCompatResponse({
    required this.version,
    required this.species,
    required this.breeds,
    required this.colors,
    required this.patterns,
  });

  final int version;
  final List<SpeciesItem> species;
  final List<BreedItem> breeds;
  final List<ColorItem> colors;
  final List<PatternItem> patterns;

  factory _PetDictionariesCompatResponse.fromJson(Object? data) {
    final json = asJsonMap(data);
    final species = asJsonMapList(json['species']);
    final breeds = asJsonMapList(json['breeds']);
    final patterns = asJsonMapList(json['patterns']);
    final colorPresets = asJsonMapList(json['color_presets']);
    final version = _computeVersion(
      <List<JsonMap>>[species, breeds, patterns, colorPresets],
    );

    return _PetDictionariesCompatResponse(
      version: version,
      species: species
          .map(
            (item) => SpeciesItem(
              id: asString(item['id']),
              name: _pickName(item),
              isActive: asBool(item['is_active']),
              version: version,
            ),
          )
          .toList(growable: false),
      breeds: breeds
          .map(
            (item) => BreedItem(
              id: asString(item['id']),
              speciesId: asString(item['species_id']),
              name: _pickName(item),
              isActive: asBool(item['is_active']),
              version: version,
            ),
          )
          .toList(growable: false),
      colors: colorPresets
          .map(
            (item) => ColorItem(
              id: asString(item['id']),
              name: _pickName(item),
              hex: asString(item['hex']),
              isActive: asBool(item['is_active']),
              version: version,
            ),
          )
          .toList(growable: false),
      patterns: patterns
          .map(
            (item) => PatternItem(
              id: asString(item['id']),
              name: _pickName(item),
              iconKey: asString(
                item['icon_key'],
                fallback: 'pattern_default',
              ),
              isActive: asBool(item['is_active']),
              version: version,
            ),
          )
          .toList(growable: false),
    );
  }

  static String _pickName(JsonMap item) {
    return asNullableString(item['name_ru']) ??
        asNullableString(item['name_en']) ??
        asString(item['name']);
  }

  static int _computeVersion(List<List<JsonMap>> groups) {
    var hash = 0x811C9DC5;

    void add(String value) {
      for (final codeUnit in value.codeUnits) {
        hash ^= codeUnit;
        hash = (hash * 0x01000193) & 0x7fffffff;
      }
    }

    for (final group in groups) {
      for (final item in group) {
        add(asString(item['id']));
        add(asString(item['species_id']));
        add(asString(item['name_ru']));
        add(asString(item['name_en']));
        add(asString(item['icon_key']));
        add(asString(item['hex']));
        add(asString(item['sort_order']));
        add(asString(item['is_active']));
      }
    }

    return hash == 0 ? 1 : hash;
  }
}
