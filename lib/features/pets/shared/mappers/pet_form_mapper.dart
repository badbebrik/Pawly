import '../../models/pet.dart';
import '../../models/pet_form.dart';

PetForm petFormFromPet(Pet pet) {
  final speciesId = pet.speciesId;
  final speciesMode = speciesId == null || speciesId.isEmpty
      ? CatalogPickMode.custom
      : CatalogPickMode.catalog;
  final breedMode =
      speciesMode == CatalogPickMode.custom || pet.breed.source == 'CUSTOM'
          ? CatalogPickMode.custom
          : CatalogPickMode.catalog;
  final patternMode = pet.coatPattern.source == 'CUSTOM'
      ? CatalogPickMode.custom
      : CatalogPickMode.catalog;

  return PetForm(
    name: pet.name,
    sex: pet.sex,
    birthDate: pet.birthDate,
    speciesMode: speciesMode,
    speciesId: speciesId,
    customSpeciesName: pet.customSpeciesName ?? '',
    breedMode: breedMode,
    breedId: pet.breed.systemBreedId,
    customBreedName: pet.breed.customBreedName ?? '',
    patternMode: patternMode,
    patternId: pet.coatPattern.systemCoatPatternId,
    customPatternName: pet.coatPattern.customCoatPatternName ?? '',
    colorIds: pet.colors
        .where((entry) => entry.presetId != null && entry.presetId!.isNotEmpty)
        .map((entry) => entry.presetId!)
        .toSet(),
    customColors: pet.colors
        .where(
          (entry) => entry.hexOverride != null && entry.hexOverride!.isNotEmpty,
        )
        .map(
          (entry) => PetFormColor(
            hex: entry.hexOverride!,
            name: entry.note ?? '',
          ),
        )
        .toList(growable: false),
    isNeutered: pet.isNeutered,
    isOutdoor: pet.isOutdoor,
    microchipId: pet.microchipId ?? '',
    microchipInstalledAt: pet.microchipInstalledAt,
  );
}
