import '../../../../core/network/models/pet_models.dart' as network;
import '../../models/pet.dart';

Pet petFromNetwork(network.Pet source) {
  return Pet(
    id: source.id,
    ownerUserId: source.ownerUserId,
    rowVersion: source.rowVersion,
    name: source.name,
    speciesId: source.speciesId,
    customSpeciesName: source.customSpeciesName,
    sex: source.sex,
    birthDate: source.birthDate,
    breed: PetBreed(
      source: source.breed.source,
      systemBreedId: source.breed.systemBreedId,
      customBreedName: source.breed.customBreedName,
    ),
    colors: source.colors
        .map(
          (color) => PetColor(
            presetId: color.presetId,
            hexOverride: color.hexOverride,
            note: color.note,
            sortOrder: color.sortOrder,
          ),
        )
        .toList(growable: false),
    coatPattern: PetCoatPattern(
      source: source.coatPattern.source,
      systemCoatPatternId: source.coatPattern.systemCoatPatternId,
      customCoatPatternName: source.coatPattern.customCoatPatternName,
    ),
    isNeutered: source.isNeutered,
    isOutdoor: source.isOutdoor,
    profilePhotoFileId: source.profilePhotoFileId,
    profilePhotoDownloadUrl: source.profilePhotoDownloadUrl,
    microchipId: source.microchipId,
    microchipInstalledAt: source.microchipInstalledAt,
    status: source.status,
    missingSince: source.missingSince,
    archivedAt: source.archivedAt,
    createdAt: source.createdAt,
    updatedAt: source.updatedAt,
  );
}
