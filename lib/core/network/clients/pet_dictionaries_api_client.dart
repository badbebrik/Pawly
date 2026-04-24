import '../api_client.dart';
import '../api_context.dart';
import '../api_endpoints.dart';
import '../models/catalog_models.dart';

class PetDictionariesApiClient {
  PetDictionariesApiClient(this._apiClient);

  final ApiClient _apiClient;

  static const _options = ApiRequestOptions(
    includeLocale: true,
  );

  Future<PetDictionariesResponse> getPetDictionaries() {
    return _apiClient.get<PetDictionariesResponse>(
      ApiEndpoints.petDictionaries,
      requestOptions: _options,
      decoder: PetDictionariesResponse.fromJson,
    );
  }
}
