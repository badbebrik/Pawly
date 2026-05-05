import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/clients/acl_api_client.dart';
import '../../../core/network/clients/pets_api_client.dart';
import '../../../core/network/models/acl_models.dart' as acl_network;
import '../../../core/network/models/pet_models.dart' as network;
import '../models/pet.dart';
import '../models/pet_form.dart';
import '../models/pet_invite_result.dart';
import '../models/pet_list_entry.dart';
import '../shared/formatters/pet_access_formatters.dart';
import '../shared/mappers/pet_access_policy_mapper.dart';
import '../shared/mappers/pet_form_payload_mapper.dart';
import '../shared/mappers/pet_mapper.dart';

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
      final speciesName = _speciesNameWithoutCatalog(pet);
      final roleTitle = item.myAccess?.role.title ??
          petFallbackRoleTitle(isOwner: isOwnedByMe);

      return PetListEntry(
        id: pet.id,
        pet: petFromNetwork(pet),
        name: pet.name,
        speciesName: speciesName,
        photoUrl: pet.profilePhotoDownloadUrl,
        roleTitle: roleTitle,
        isOwnedByMe: isOwnedByMe,
        accessPolicy: petAccessPolicyFromAclPolicy(
          item.myAccess?.policy,
          isOwner: isOwnedByMe,
        ),
      );
    }).toList(growable: false);
  }

  Future<Pet> getPet(String petId) async {
    final response = await _petsApiClient.getPet(petId);
    return petFromNetwork(response.pet);
  }

  Future<network.Pet> getPetById(String petId) async {
    final response = await _petsApiClient.getPet(petId);
    return response.pet;
  }

  Future<Pet> updatePet({
    required Pet pet,
    required PetForm draft,
  }) async {
    final response = await _petsApiClient.updatePet(
      pet.id,
      network.UpdatePetPayload(
        rowVersion: pet.rowVersion,
        payload: buildCreatePetPayloadFromDraft(
          draft,
          profilePhotoFileId: pet.profilePhotoFileId,
        ),
      ),
    );
    return petFromNetwork(response.pet);
  }

  Future<Pet> createPet(PetForm draft) async {
    final response = await _petsApiClient.createPet(
      buildCreatePetPayloadFromDraft(draft),
    );
    return petFromNetwork(response.pet);
  }

  Future<Pet> changeStatus({
    required String petId,
    required int rowVersion,
    required String status,
    DateTime? missingSince,
  }) async {
    final response = await _petsApiClient.changeStatus(
      petId,
      network.ChangePetStatusPayload(
        rowVersion: rowVersion,
        status: status,
        missingSince: missingSince,
      ),
    );
    return petFromNetwork(response.pet);
  }

  Future<PetInviteResult> acceptInviteByCode(String code) async {
    final response = await _aclApiClient.acceptInviteByCode(
      acl_network.AcceptInviteByCodePayload(code: code),
    );

    return PetInviteResult(
      petId: response.petId,
      roleTitle: response.member.role.title,
      isPrimaryOwner: response.member.isPrimaryOwner,
    );
  }

  Future<network.Pet> transferOwnership({
    required String petId,
    required int rowVersion,
    required String targetMemberId,
  }) async {
    final response = await _petsApiClient.transferOwnership(
      petId,
      network.TransferPetOwnershipPayload(
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

    final sizeBytes = await file.length();
    final initResponse = await _petsApiClient.initPhotoUpload(
      pet.id,
      network.InitPetPhotoUploadPayload(
        mimeType: mimeType,
        originalFilename: _fileNameFromPath(file.path),
        expectedSizeBytes: sizeBytes,
      ),
    );

    await _uploadDio.request<Object?>(
      initResponse.upload.url,
      data: file.openRead(),
      options: Options(
        method: initResponse.upload.method,
        contentType: mimeType,
        headers: <String, dynamic>{
          ...initResponse.upload.headers,
          Headers.contentLengthHeader: sizeBytes,
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
      network.ConfirmPetPhotoUploadPayload(
        rowVersion: pet.rowVersion,
        fileId: initResponse.fileId,
        sizeBytes: sizeBytes,
      ),
    );

    return petFromNetwork(confirmResponse.pet);
  }

  Future<Pet> deletePetPhoto({required Pet pet}) async {
    final response = await _petsApiClient.deletePhoto(
      pet.id,
      network.DeletePetPhotoPayload(rowVersion: pet.rowVersion),
    );
    return petFromNetwork(response.pet);
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

  String _speciesNameWithoutCatalog(network.Pet pet) {
    final customSpeciesName = pet.customSpeciesName?.trim();
    if (customSpeciesName != null && customSpeciesName.isNotEmpty) {
      return customSpeciesName;
    }

    final speciesName = pet.speciesName?.trim();
    if (speciesName != null && speciesName.isNotEmpty) {
      return speciesName;
    }

    return 'Неизвестный вид';
  }
}
