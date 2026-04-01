import '../api_client.dart';
import '../api_context.dart';
import '../api_endpoints.dart';
import '../models/common_models.dart';
import '../models/pet_models.dart';

class PetsApiClient {
  PetsApiClient(this._apiClient);

  final ApiClient _apiClient;
  static const _withUserAndToken = ApiRequestOptions(
    requiresUserId: true,
    requiresAccessToken: true,
  );

  Future<PetEnvelopeResponse> createPet(CreatePetPayload payload) {
    return _apiClient.post<PetEnvelopeResponse>(
      ApiEndpoints.pets,
      data: payload.toJson(),
      requestOptions: _withUserAndToken,
      decoder: PetEnvelopeResponse.fromJson,
    );
  }

  Future<PetListResponse> listPets({
    bool? includeArchived,
    int offset = 0,
    int limit = 50,
  }) {
    return _apiClient.get<PetListResponse>(
      ApiEndpoints.pets,
      queryParameters: <String, dynamic>{
        'include_archived': includeArchived,
        'offset': offset,
        'limit': limit,
      }..removeWhere((_, dynamic value) => value == null),
      requestOptions: _withUserAndToken,
      decoder: PetListResponse.fromJson,
    );
  }

  Future<PetEnvelopeResponse> getPet(String petId) {
    return _apiClient.get<PetEnvelopeResponse>(
      ApiEndpoints.petById(petId),
      requestOptions: _withUserAndToken,
      decoder: PetEnvelopeResponse.fromJson,
    );
  }

  Future<PetEnvelopeResponse> updatePet(
      String petId, UpdatePetPayload payload) {
    return _apiClient.put<PetEnvelopeResponse>(
      ApiEndpoints.petById(petId),
      data: payload.toJson(),
      requestOptions: _withUserAndToken,
      decoder: PetEnvelopeResponse.fromJson,
    );
  }

  Future<PetEnvelopeResponse> changeStatus(
    String petId,
    ChangePetStatusPayload payload,
  ) {
    return _apiClient.post<PetEnvelopeResponse>(
      ApiEndpoints.petStatus(petId),
      data: payload.toJson(),
      requestOptions: _withUserAndToken,
      decoder: PetEnvelopeResponse.fromJson,
    );
  }

  Future<PetEnvelopeResponse> transferOwnership(
    String petId,
    TransferPetOwnershipPayload payload,
  ) {
    return _apiClient.post<PetEnvelopeResponse>(
      ApiEndpoints.petTransferOwnership(petId),
      data: payload.toJson(),
      requestOptions: _withUserAndToken,
      decoder: PetEnvelopeResponse.fromJson,
    );
  }

  Future<InitUploadResponse> initPhotoUpload(
    String petId,
    InitPetPhotoUploadPayload payload,
  ) {
    return _apiClient.post<InitUploadResponse>(
      ApiEndpoints.petPhotoInitUpload(petId),
      data: payload.toJson(),
      requestOptions: _withUserAndToken,
      decoder: InitUploadResponse.fromJson,
    );
  }

  Future<PetEnvelopeResponse> confirmPhotoUpload(
    String petId,
    ConfirmPetPhotoUploadPayload payload,
  ) {
    return _apiClient.post<PetEnvelopeResponse>(
      ApiEndpoints.petPhotoConfirmUpload(petId),
      data: payload.toJson(),
      requestOptions: _withUserAndToken,
      decoder: PetEnvelopeResponse.fromJson,
    );
  }
}
