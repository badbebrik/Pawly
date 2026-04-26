import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/clients/acl_api_client.dart';
import '../../../core/network/clients/pets_api_client.dart';
import '../../../core/network/models/acl_models.dart';
import '../../../core/network/models/pet_models.dart';
import '../models/pet_access_policy.dart';
import '../models/pet_invite_result.dart';
import '../models/pet_list_entry.dart';
import '../shared/formatters/pet_access_formatters.dart';
import '../shared/formatters/pet_catalog_label_formatters.dart';
import 'pet_catalog_models.dart';

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
    required PetCatalog catalog,
    bool includeArchived = false,
    int limit = 50,
  }) async {
    final response = await _petsApiClient.listPets(
      includeArchived: includeArchived,
      limit: limit,
    );

    return response.items.map((item) {
      final pet = item.pet;
      final isOwnedByMe = pet.ownerUserId == currentUserId;
      final speciesName = petSpeciesLabelFromValues(
        catalog,
        speciesId: pet.speciesId,
        customSpeciesName: pet.customSpeciesName,
      );
      final roleTitle = item.myAccess?.role.title ??
          petFallbackRoleTitle(isOwner: isOwnedByMe);

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

  Future<PetEnvelopeResponse> createPet(CreatePetPayload payload) {
    return _petsApiClient.createPet(payload);
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

  Future<PetInviteResult> acceptInviteByCode(String code) async {
    final response = await _aclApiClient.acceptInviteByCode(
      AcceptInviteByCodePayload(code: code),
    );

    return PetInviteResult(
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
