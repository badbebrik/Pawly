import '../../../core/network/clients/pets_api_client.dart';
import '../../../core/network/models/pet_models.dart';

class PetCreateRepository {
  PetCreateRepository(this._petsApiClient);

  final PetsApiClient _petsApiClient;

  Future<PetEnvelopeResponse> createPet(CreatePetPayload payload) {
    return _petsApiClient.createPet(payload);
  }
}
