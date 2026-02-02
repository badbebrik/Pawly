import '../../../core/network/api_client.dart';
import '../../../core/network/api_context.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/models/pet_models.dart';

class PetCreateRepository {
  PetCreateRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<PetEnvelopeResponse> createPet(Map<String, dynamic> body) {
    return _apiClient.post<PetEnvelopeResponse>(
      ApiEndpoints.pets,
      data: body,
      requestOptions: const ApiRequestOptions(
        requiresUserId: true,
        requiresAccessToken: true,
      ),
      decoder: PetEnvelopeResponse.fromJson,
    );
  }
}
