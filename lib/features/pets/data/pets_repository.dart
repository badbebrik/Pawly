import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/clients/acl_api_client.dart';
import '../../../core/network/clients/pets_api_client.dart';
import '../../../core/network/models/acl_models.dart';
import '../../../core/network/models/pet_models.dart';
import '../../catalog/data/catalog_cache_models.dart';

class PetsRepository {
  PetsRepository({
    required PetsApiClient petsApiClient,
    required AclApiClient aclApiClient,
    required Dio uploadDio,
  })  : _petsApiClient = petsApiClient,
        _aclApiClient = aclApiClient,
        _uploadDio = uploadDio;

  final PetsApiClient _petsApiClient;
  final AclApiClient _aclApiClient;
  final Dio _uploadDio;

  Future<List<PetListEntry>> listAvailablePets({
    required String currentUserId,
    required CatalogSnapshot catalog,
    bool includeArchived = false,
    int limit = 50,
  }) async {
    final response = await _petsApiClient.listPets(
      includeArchived: includeArchived,
      limit: limit,
    );

    return response.items.map((item) {
      final pet = item.pet;
      final species =
          catalog.species.where((entry) => entry.id == pet.speciesId);
      final speciesName = pet.customSpeciesName ??
          (species.isEmpty ? 'Неизвестный вид' : species.first.name);
      final roleTitle = item.myAccess?.role.title ??
          (pet.ownerUserId == currentUserId ? 'Владелец' : 'Участник');
      final isOwnedByMe = pet.ownerUserId == currentUserId;

      return PetListEntry(
        id: pet.id,
        pet: pet,
        name: pet.name,
        speciesName: speciesName,
        photoUrl: pet.profilePhotoDownloadUrl,
        roleTitle: roleTitle,
        isOwnedByMe: isOwnedByMe,
        accessPolicy: PetAccessPolicy.fromAclPolicy(
          item.myAccess?.policy,
          isOwner: isOwnedByMe,
        ),
      );
    }).toList(growable: false);
  }

  Future<Pet> getPetById(String petId) async {
    final response = await _petsApiClient.getPet(petId);
    return response.pet;
  }

  Future<Pet> updatePet({
    required String petId,
    required UpdatePetPayload payload,
  }) async {
    final response = await _petsApiClient.updatePet(petId, payload);
    return response.pet;
  }

  Future<Pet> changeStatus({
    required String petId,
    required int rowVersion,
    required String status,
    DateTime? missingSince,
  }) async {
    final response = await _petsApiClient.changeStatus(
      petId,
      ChangePetStatusPayload(
        rowVersion: rowVersion,
        status: status,
        missingSince: missingSince,
      ),
    );
    return response.pet;
  }

  Future<PetInviteAcceptResult> acceptInviteByCode(String code) async {
    final response = await _aclApiClient.acceptInviteByCode(
      AcceptInviteByCodePayload(code: code),
    );

    return PetInviteAcceptResult(
      petId: response.petId,
      roleTitle: response.member.role.title,
      isPrimaryOwner: response.member.isPrimaryOwner,
    );
  }

  Future<Pet> transferOwnership({
    required String petId,
    required int rowVersion,
    required String targetMemberId,
  }) async {
    final response = await _petsApiClient.transferOwnership(
      petId,
      TransferPetOwnershipPayload(
        rowVersion: rowVersion,
        targetMemberId: targetMemberId,
      ),
    );
    return response.pet;
  }

  Future<Pet> uploadPetPhoto({
    required Pet pet,
    required XFile file,
  }) async {
    final mimeType = _resolveImageMimeType(file.path);
    if (mimeType == null) {
      throw StateError('Поддерживаются только JPG и PNG изображения.');
    }

    final bytes = await file.readAsBytes();
    final initResponse = await _petsApiClient.initPhotoUpload(
      pet.id,
      InitPetPhotoUploadPayload(
        mimeType: mimeType,
        originalFilename: _fileNameFromPath(file.path),
        expectedSizeBytes: bytes.length,
      ),
    );

    await _uploadDio.request<Object?>(
      initResponse.upload.url,
      data: bytes,
      options: Options(
        method: initResponse.upload.method,
        contentType: mimeType,
        headers: <String, dynamic>{
          ...initResponse.upload.headers,
          Headers.contentLengthHeader: bytes.length,
          if (!initResponse.upload.headers.containsKey('Content-Type'))
            'Content-Type': mimeType,
        },
        responseType: ResponseType.plain,
        validateStatus: (status) =>
            status != null && status >= 200 && status < 300,
      ),
    );

    final confirmResponse = await _petsApiClient.confirmPhotoUpload(
      pet.id,
      ConfirmPetPhotoUploadPayload(
        rowVersion: pet.rowVersion,
        fileId: initResponse.fileId,
        sizeBytes: bytes.length,
      ),
    );

    return confirmResponse.pet;
  }

  Future<Pet> deletePetPhoto({required Pet pet}) async {
    final response = await _petsApiClient.deletePhoto(
      pet.id,
      DeletePetPhotoPayload(rowVersion: pet.rowVersion),
    );
    return response.pet;
  }

  String _fileNameFromPath(String path) {
    final segments = path.replaceAll('\\', '/').split('/');
    return segments.isEmpty ? 'pet_photo.jpg' : segments.last;
  }

  String? _resolveImageMimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    return null;
  }
}

class PetListEntry {
  const PetListEntry({
    required this.id,
    required this.pet,
    required this.name,
    required this.speciesName,
    required this.photoUrl,
    required this.roleTitle,
    required this.isOwnedByMe,
    required this.accessPolicy,
  });

  final String id;
  final Pet pet;
  final String name;
  final String speciesName;
  final String? photoUrl;
  final String roleTitle;
  final bool isOwnedByMe;
  final PetAccessPolicy accessPolicy;
}

class PetAccessPolicy {
  const PetAccessPolicy({required this.permissions});

  factory PetAccessPolicy.fromAclPolicy(
    AclPolicy? policy, {
    required bool isOwner,
  }) {
    if (policy != null) {
      return PetAccessPolicy(permissions: policy.permissions);
    }

    if (isOwner) {
      return const PetAccessPolicy(permissions: _ownerPermissions);
    }

    return const PetAccessPolicy(permissions: <String, bool>{});
  }

  static const Map<String, bool> _ownerPermissions = <String, bool>{
    'pet_read': true,
    'pet_write': true,
    'log_read': true,
    'log_write': true,
    'health_read': true,
    'health_write': true,
    'members_read': true,
    'members_write': true,
  };

  final Map<String, bool> permissions;

  bool can(String permission) => permissions[permission] == true;

  bool get petRead => can('pet_read');
  bool get petWrite => can('pet_write');
  bool get logRead => can('log_read');
  bool get logWrite => can('log_write');
  bool get healthRead => can('health_read');
  bool get healthWrite => can('health_write');
  bool get membersRead => can('members_read');
  bool get membersWrite => can('members_write');

  bool get remindersRead => petRead || logRead || healthRead;
  bool get remindersWrite => petWrite || logWrite || healthWrite;
  bool get documentsRead => healthRead;

  bool canWriteScheduledSource(String sourceType) {
    return switch (sourceType) {
      'MANUAL' || 'PET_EVENT' => petWrite,
      'LOG_TYPE' => logWrite,
      'VET_VISIT' || 'VACCINATION' || 'PROCEDURE' => healthWrite,
      _ => false,
    };
  }
}

class PetInviteAcceptResult {
  const PetInviteAcceptResult({
    required this.petId,
    required this.roleTitle,
    required this.isPrimaryOwner,
  });

  final String petId;
  final String roleTitle;
  final bool isPrimaryOwner;
}
