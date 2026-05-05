import '../../../core/network/clients/pet_dictionaries_api_client.dart';
import '../../../core/network/models/catalog_models.dart';
import 'pet_catalog_models.dart';

class PetCatalogRepository {
  PetCatalogRepository({
    required PetDictionariesApiClient api,
  }) : _api = api;

  final PetDictionariesApiClient _api;

  Future<PetCatalog> getCatalog() async {
    final dictionaries = await _api.getPetDictionaries();
    return _buildSnapshot(dictionaries, locale: 'ru');
  }

  PetCatalog _buildSnapshot(
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

    return PetCatalog(
      version: dictionaries.version,
      species: species
          .map(
            (item) => PetSpeciesOption(
              id: item.id,
              name: item.localizedName(locale: locale),
              iconName: item.iconKey,
            ),
          )
          .toList(growable: false),
      breeds: breeds
          .map(
            (item) => PetBreedOption(
              id: item.id,
              speciesId: item.speciesId,
              name: item.localizedName(locale: locale),
            ),
          )
          .toList(growable: false),
      colors: colors
          .map(
            (item) => PetColorOption(
              id: item.id,
              name: item.localizedName(locale: locale),
              hex: item.hex,
            ),
          )
          .toList(growable: false),
      patterns: patterns
          .map(
            (item) => PetCoatPatternOption(
              id: item.id,
              name: item.localizedName(locale: locale),
              iconKey: item.iconKey ?? 'pattern_default',
            ),
          )
          .toList(growable: false),
    );
  }
}
