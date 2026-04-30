import '../../../../core/network/models/pet_models.dart' as network;
import '../../models/pet_form.dart';
import '../utils/pet_color_utils.dart';

network.CreatePetPayload buildCreatePetPayloadFromDraft(
  PetForm draft, {
  String? profilePhotoFileId,
}) {
  return network.CreatePetPayload(
    name: draft.name.trim(),
    speciesId:
        draft.speciesMode == CatalogPickMode.catalog ? draft.speciesId : null,
    customSpeciesName: draft.speciesMode == CatalogPickMode.custom
        ? draft.customSpeciesName.trim()
        : null,
    sex: draft.sex,
    birthDate: draft.birthDate,
    breedId: draft.speciesMode == CatalogPickMode.catalog &&
            draft.breedMode == CatalogPickMode.catalog
        ? draft.breedId
        : null,
    customBreedName: draft.breedMode == CatalogPickMode.custom
        ? draft.customBreedName.trim()
        : null,
    colors: buildPetColorsPayload(draft),
    patternId:
        draft.patternMode == CatalogPickMode.catalog ? draft.patternId : null,
    customPatternName: draft.patternMode == CatalogPickMode.custom
        ? draft.customPatternName.trim()
        : null,
    isNeutered: draft.isNeutered,
    isOutdoor: draft.isOutdoor,
    profilePhotoFileId: profilePhotoFileId,
    microchipId:
        draft.microchipId.trim().isEmpty ? null : draft.microchipId.trim(),
    microchipInstalledAt: draft.microchipInstalledAt,
  );
}

List<network.PetColor> buildPetColorsPayload(PetForm draft) {
  final colors = <network.PetColor>[];
  var sortOrder = 0;

  for (final id in draft.colorIds) {
    colors.add(network.PetColor(presetId: id, sortOrder: sortOrder++));
  }

  for (final color in draft.customColors) {
    final hex = normalizePetColorHex(color.hex);
    if (hex == null) continue;
    final name = color.name.trim();
    colors.add(
      network.PetColor(
        hexOverride: hex,
        note: name.isEmpty ? null : name,
        sortOrder: sortOrder++,
      ),
    );
  }

  return colors;
}
