import 'acl_models.dart';
import 'common_models.dart';
import 'json_map.dart';
import 'json_parsers.dart';

class PetBreed {
  const PetBreed({
    required this.source,
    this.systemBreedId,
    this.customBreedName,
  });

  final String source;
  final String? systemBreedId;
  final String? customBreedName;

  factory PetBreed.fromJson(Object? data) {
    final json = asJsonMap(data);
    return PetBreed(
      source: asString(json['source']),
      systemBreedId: asNullableString(json['system_breed_id']),
      customBreedName: asNullableString(json['custom_breed_name']),
    );
  }

  JsonMap toJson() => <String, dynamic>{
        'source': source,
        'system_breed_id': systemBreedId,
        'custom_breed_name': customBreedName,
      }..removeWhere((_, dynamic value) => value == null);
}

class PetColor {
  const PetColor({
    this.presetId,
    this.hexOverride,
    this.note,
    required this.sortOrder,
  });

  final String? presetId;
  final String? hexOverride;
  final String? note;
  final int sortOrder;

  factory PetColor.fromJson(Object? data) {
    final json = asJsonMap(data);

    return PetColor(
      presetId: asNullableString(json['preset_id']),
      hexOverride: asNullableString(json['custom_hex']) ??
          asNullableString(json['hex_override']),
      note: asNullableString(json['custom_name']) ??
          asNullableString(json['note']),
      sortOrder: asInt(json['sort_order']),
    );
  }

  JsonMap toJson() => <String, dynamic>{
        'preset_id': presetId,
        'custom_name': note,
        'custom_hex': hexOverride,
        'sort_order': sortOrder,
      }..removeWhere((_, dynamic value) => value == null);
}

class PetCoatPattern {
  const PetCoatPattern({
    required this.source,
    this.systemCoatPatternId,
    this.customCoatPatternName,
  });

  final String source;
  final String? systemCoatPatternId;
  final String? customCoatPatternName;

  factory PetCoatPattern.fromJson(Object? data) {
    final json = asJsonMap(data);
    return PetCoatPattern(
      source: asString(json['source']),
      systemCoatPatternId: asNullableString(json['system_coat_pattern_id']),
      customCoatPatternName: asNullableString(json['custom_coat_pattern_name']),
    );
  }

  JsonMap toJson() => <String, dynamic>{
        'source': source,
        'system_coat_pattern_id': systemCoatPatternId,
        'custom_coat_pattern_name': customCoatPatternName,
      }..removeWhere((_, dynamic value) => value == null);
}

class Pet {
  const Pet({
    required this.id,
    required this.ownerUserId,
    required this.rowVersion,
    required this.name,
    required this.speciesId,
    required this.sex,
    this.birthDate,
    required this.breed,
    required this.colors,
    required this.coatPattern,
    required this.isNeutered,
    required this.isOutdoor,
    this.profilePhotoFileId,
    this.profilePhotoDownloadUrl,
    this.microchipId,
    this.microchipInstalledAt,
    required this.status,
    this.missingSince,
    this.archivedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String ownerUserId;
  final int rowVersion;
  final String name;
  final String speciesId;
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

  factory Pet.fromJson(Object? data) {
    final json = asJsonMap(data);
    final rawColors = json['colors'];
    final colors = rawColors is List
        ? rawColors.map(PetColor.fromJson).toList(growable: false)
        : const <PetColor>[];
    final rawBreed = json['breed'];
    final breed = rawBreed == null
        ? PetBreed(
            source: asNullableString(json['custom_breed_name']) != null
                ? 'CUSTOM'
                : 'SYSTEM',
            systemBreedId: asNullableString(json['breed_id']),
            customBreedName: asNullableString(json['custom_breed_name']),
          )
        : PetBreed.fromJson(rawBreed);
    final rawCoatPattern = json['coat_pattern'];
    final coatPattern = rawCoatPattern == null
        ? PetCoatPattern(
            source: asNullableString(json['custom_pattern_name']) != null
                ? 'CUSTOM'
                : 'SYSTEM',
            systemCoatPatternId: asNullableString(json['pattern_id']),
            customCoatPatternName:
                asNullableString(json['custom_pattern_name']),
          )
        : PetCoatPattern.fromJson(rawCoatPattern);

    return Pet(
      id: asString(json['id']),
      ownerUserId: asString(json['owner_user_id']),
      rowVersion: asInt(json['row_version']),
      name: asString(json['name']),
      speciesId: asString(json['species_id']),
      sex: asString(json['sex']),
      birthDate: asDateTime(json['birth_date']),
      breed: breed,
      colors: colors,
      coatPattern: coatPattern,
      isNeutered: asString(json['is_neutered']),
      isOutdoor: asBool(json['is_outdoor']),
      profilePhotoFileId: asNullableString(json['profile_photo_file_id']),
      profilePhotoDownloadUrl: asNullableString(
        json['profile_photo_download_url'],
      ),
      microchipId: asNullableString(json['microchip_id']),
      microchipInstalledAt: asDateTime(json['microchip_installed_at']),
      status: asString(json['status']),
      missingSince: asDateTime(json['missing_since']),
      archivedAt: asDateTime(json['archived_at']),
      createdAt: asDateTime(json['created_at']),
      updatedAt: asDateTime(json['updated_at']),
    );
  }
}

class CreatePetPayload {
  const CreatePetPayload({
    required this.name,
    required this.speciesId,
    required this.sex,
    this.birthDate,
    this.breedId,
    this.customBreedName,
    required this.colors,
    this.patternId,
    this.customPatternName,
    required this.isNeutered,
    required this.isOutdoor,
    this.profilePhotoFileId,
    this.microchipId,
    this.microchipInstalledAt,
  });

  final String name;
  final String speciesId;
  final String sex;
  final DateTime? birthDate;
  final String? breedId;
  final String? customBreedName;
  final List<PetColor> colors;
  final String? patternId;
  final String? customPatternName;
  final String isNeutered;
  final bool isOutdoor;
  final String? profilePhotoFileId;
  final String? microchipId;
  final DateTime? microchipInstalledAt;

  JsonMap toJson() {
    return <String, dynamic>{
      'name': name,
      'species_id': speciesId,
      'sex': sex,
      'birth_date': birthDate == null ? null : formatDate(birthDate!),
      'breed_id': breedId,
      'custom_breed_name': customBreedName,
      'colors': colors.map((item) => item.toJson()).toList(growable: false),
      'pattern_id': patternId,
      'custom_pattern_name': customPatternName,
      'is_neutered': isNeutered,
      'is_outdoor': isOutdoor,
      'profile_photo_file_id': profilePhotoFileId,
      'microchip_id': microchipId,
      'microchip_installed_at': microchipInstalledAt == null
          ? null
          : formatDate(microchipInstalledAt!),
    }..removeWhere((_, dynamic value) => value == null);
  }
}

class UpdatePetPayload {
  const UpdatePetPayload({required this.rowVersion, required this.payload});

  final int rowVersion;
  final CreatePetPayload payload;

  JsonMap toJson() {
    return <String, dynamic>{
      ...payload.toJson(),
      'row_version': rowVersion,
    };
  }
}

class ChangePetStatusPayload {
  const ChangePetStatusPayload({
    required this.rowVersion,
    required this.status,
    this.missingSince,
  });

  final int rowVersion;
  final String status;
  final DateTime? missingSince;

  JsonMap toJson() {
    return <String, dynamic>{
      'row_version': rowVersion,
      'status': status,
      'missing_since': missingSince?.toIso8601String(),
    }..removeWhere((_, dynamic value) => value == null);
  }
}

class TransferPetOwnershipPayload {
  const TransferPetOwnershipPayload({
    required this.rowVersion,
    required this.targetMemberId,
  });

  final int rowVersion;
  final String targetMemberId;

  JsonMap toJson() {
    return <String, dynamic>{
      'row_version': rowVersion,
      'target_member_id': targetMemberId,
    };
  }
}

class InitPetPhotoUploadPayload {
  const InitPetPhotoUploadPayload({
    required this.mimeType,
    required this.originalFilename,
    required this.expectedSizeBytes,
  });

  final String mimeType;
  final String originalFilename;
  final int expectedSizeBytes;

  JsonMap toJson() {
    return <String, dynamic>{
      'mime_type': mimeType,
      'original_filename': originalFilename,
      'expected_size_bytes': expectedSizeBytes,
    };
  }
}

class ConfirmPetPhotoUploadPayload {
  const ConfirmPetPhotoUploadPayload({
    required this.rowVersion,
    required this.fileId,
    required this.sizeBytes,
  });

  final int rowVersion;
  final String fileId;
  final int sizeBytes;

  JsonMap toJson() {
    return <String, dynamic>{
      'row_version': rowVersion,
      'file_id': fileId,
      'size_bytes': sizeBytes,
    };
  }
}

class PetEnvelopeResponse {
  const PetEnvelopeResponse({required this.pet});

  final Pet pet;

  factory PetEnvelopeResponse.fromJson(Object? data) {
    final json = asJsonMap(data);
    return PetEnvelopeResponse(pet: Pet.fromJson(json['pet']));
  }
}

class PetListItem {
  const PetListItem({
    required this.pet,
    required this.myAccess,
  });

  final Pet pet;
  final AclMyAccess? myAccess;

  factory PetListItem.fromJson(Object? data) {
    final json = asJsonMap(data);
    return PetListItem(
      pet: Pet.fromJson(json['pet']),
      myAccess: json['my_access'] == null
          ? null
          : AclMyAccess.fromJson(json['my_access']),
    );
  }
}

class PetListResponse extends PagedItemsResponse<PetListItem> {
  const PetListResponse({
    required super.items,
    required super.total,
    required super.offset,
    required super.limit,
  });

  factory PetListResponse.fromJson(Object? data) {
    final paged = PagedItemsResponse<PetListItem>.fromJson(
      data,
      PetListItem.fromJson,
    );

    return PetListResponse(
      items: paged.items,
      total: paged.total,
      offset: paged.offset,
      limit: paged.limit,
    );
  }
}
