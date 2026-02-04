import '../../../core/network/clients/acl_api_client.dart';
import '../../../core/network/clients/pets_api_client.dart';
import '../../../core/network/models/acl_models.dart';
import '../../../core/network/models/pet_models.dart';
import '../../catalog/data/catalog_cache_models.dart';

class PetsRepository {
  PetsRepository({
    required PetsApiClient petsApiClient,
    required AclApiClient aclApiClient,
  })  : _petsApiClient = petsApiClient,
        _aclApiClient = aclApiClient;

  final PetsApiClient _petsApiClient;
  final AclApiClient _aclApiClient;

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
      final speciesName =
          species.isEmpty ? 'Неизвестный вид' : species.first.name;
      final roleTitle = item.myAccess?.role.title ??
          (pet.ownerUserId == currentUserId ? 'Владелец' : 'Участник');

      return PetListEntry(
        id: pet.id,
        pet: pet,
        name: pet.name,
        speciesName: speciesName,
        photoUrl: pet.profilePhotoDownloadUrl,
        roleTitle: roleTitle,
        isOwnedByMe: pet.ownerUserId == currentUserId,
      );
    }).toList(growable: false);
  }

  Future<Pet> getPetById(String petId) async {
    final response = await _petsApiClient.getPet(petId);
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
  });

  final String id;
  final Pet pet;
  final String name;
  final String speciesName;
  final String? photoUrl;
  final String roleTitle;
  final bool isOwnedByMe;
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
