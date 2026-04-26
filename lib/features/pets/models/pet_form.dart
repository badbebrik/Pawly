import '../../../core/network/models/pet_models.dart';

enum CatalogPickMode { catalog, custom }

const int petFormMaxColors = 10;

class PetFormColor {
  const PetFormColor({
    required this.hex,
    required this.name,
  });

  final String hex;
  final String name;
}

class PetForm {
  const PetForm({
    required this.name,
    required this.sex,
    required this.birthDate,
    required this.speciesMode,
    required this.speciesId,
    required this.customSpeciesName,
    required this.breedMode,
    required this.breedId,
    required this.customBreedName,
    required this.patternMode,
    required this.patternId,
    required this.customPatternName,
    required this.colorIds,
    required this.customColors,
    required this.isNeutered,
    required this.isOutdoor,
    required this.microchipId,
    required this.microchipInstalledAt,
  });

  factory PetForm.empty() => const PetForm(
        name: '',
        sex: 'UNKNOWN',
        birthDate: null,
        speciesMode: CatalogPickMode.catalog,
        speciesId: null,
        customSpeciesName: '',
        breedMode: CatalogPickMode.catalog,
        breedId: null,
        customBreedName: '',
        patternMode: CatalogPickMode.catalog,
        patternId: null,
        customPatternName: '',
        colorIds: <String>{},
        customColors: <PetFormColor>[],
        isNeutered: 'UNKNOWN',
        isOutdoor: false,
        microchipId: '',
        microchipInstalledAt: null,
      );

  factory PetForm.fromPet(Pet pet) {
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
          .where(
              (entry) => entry.presetId != null && entry.presetId!.isNotEmpty)
          .map((entry) => entry.presetId!)
          .toSet(),
      customColors: pet.colors
          .where(
            (entry) =>
                entry.hexOverride != null && entry.hexOverride!.isNotEmpty,
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

  final String name;
  final String sex;
  final DateTime? birthDate;

  final CatalogPickMode speciesMode;
  final String? speciesId;
  final String customSpeciesName;

  final CatalogPickMode breedMode;
  final String? breedId;
  final String customBreedName;

  final CatalogPickMode patternMode;
  final String? patternId;
  final String customPatternName;

  final Set<String> colorIds;
  final List<PetFormColor> customColors;

  final String isNeutered;
  final bool isOutdoor;
  final String microchipId;
  final DateTime? microchipInstalledAt;

  int get selectedColorsCount => colorIds.length + customColors.length;

  PetForm copyWith({
    String? name,
    String? sex,
    DateTime? birthDate,
    bool clearBirthDate = false,
    CatalogPickMode? speciesMode,
    String? speciesId,
    bool clearSpeciesId = false,
    String? customSpeciesName,
    CatalogPickMode? breedMode,
    String? breedId,
    bool clearBreedId = false,
    String? customBreedName,
    CatalogPickMode? patternMode,
    String? patternId,
    bool clearPatternId = false,
    String? customPatternName,
    Set<String>? colorIds,
    List<PetFormColor>? customColors,
    String? isNeutered,
    bool? isOutdoor,
    String? microchipId,
    DateTime? microchipInstalledAt,
    bool clearMicrochipDate = false,
  }) {
    return PetForm(
      name: name ?? this.name,
      sex: sex ?? this.sex,
      birthDate: clearBirthDate ? null : (birthDate ?? this.birthDate),
      speciesMode: speciesMode ?? this.speciesMode,
      speciesId: clearSpeciesId ? null : (speciesId ?? this.speciesId),
      customSpeciesName: customSpeciesName ?? this.customSpeciesName,
      breedMode: breedMode ?? this.breedMode,
      breedId: clearBreedId ? null : (breedId ?? this.breedId),
      customBreedName: customBreedName ?? this.customBreedName,
      patternMode: patternMode ?? this.patternMode,
      patternId: clearPatternId ? null : (patternId ?? this.patternId),
      customPatternName: customPatternName ?? this.customPatternName,
      colorIds: colorIds ?? this.colorIds,
      customColors: customColors ?? this.customColors,
      isNeutered: isNeutered ?? this.isNeutered,
      isOutdoor: isOutdoor ?? this.isOutdoor,
      microchipId: microchipId ?? this.microchipId,
      microchipInstalledAt: clearMicrochipDate
          ? null
          : (microchipInstalledAt ?? this.microchipInstalledAt),
    );
  }
}
