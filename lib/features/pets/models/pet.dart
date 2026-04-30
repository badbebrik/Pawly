class PetBreed {
  const PetBreed({
    required this.source,
    required this.systemBreedId,
    required this.customBreedName,
  });

  final String source;
  final String? systemBreedId;
  final String? customBreedName;
}

class PetColor {
  const PetColor({
    required this.presetId,
    required this.hexOverride,
    required this.note,
    required this.sortOrder,
  });

  final String? presetId;
  final String? hexOverride;
  final String? note;
  final int sortOrder;
}

class PetCoatPattern {
  const PetCoatPattern({
    required this.source,
    required this.systemCoatPatternId,
    required this.customCoatPatternName,
  });

  final String source;
  final String? systemCoatPatternId;
  final String? customCoatPatternName;
}

class Pet {
  const Pet({
    required this.id,
    required this.ownerUserId,
    required this.rowVersion,
    required this.name,
    required this.speciesId,
    required this.customSpeciesName,
    required this.sex,
    required this.birthDate,
    required this.breed,
    required this.colors,
    required this.coatPattern,
    required this.isNeutered,
    required this.isOutdoor,
    required this.profilePhotoFileId,
    required this.profilePhotoDownloadUrl,
    required this.microchipId,
    required this.microchipInstalledAt,
    required this.status,
    required this.missingSince,
    required this.archivedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String ownerUserId;
  final int rowVersion;
  final String name;
  final String? speciesId;
  final String? customSpeciesName;
  final String sex;
  final DateTime? birthDate;
  final PetBreed breed;
  final List<PetColor> colors;
  final PetCoatPattern coatPattern;
  final String isNeutered;
  final bool isOutdoor;
  final String? profilePhotoFileId;
  final String? profilePhotoDownloadUrl;
  final String? microchipId;
  final DateTime? microchipInstalledAt;
  final String status;
  final DateTime? missingSince;
  final DateTime? archivedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}
