import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/models/pet_models.dart';
import '../../../core/providers/core_providers.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../data/pet_catalog_provider.dart';
import '../data/pets_repository.dart';
import '../models/pet_access_policy.dart';
import '../models/pet_list_entry.dart';
import '../states/pets_state.dart';

final petsRepositoryProvider = Provider<PetsRepository>((ref) {
  final petsApiClient = ref.watch(petsApiClientProvider);
  final aclApiClient = ref.watch(aclApiClientProvider);
  final uploadDio = ref.watch(uploadDioProvider);

  return PetsRepository(
    petsApiClient: petsApiClient,
    aclApiClient: aclApiClient,
    uploadDio: uploadDio,
  );
});

final petsControllerProvider =
    AsyncNotifierProvider<PetsController, PetsState>(PetsController.new);

final petAccessPolicyProvider =
    FutureProvider.autoDispose.family<PetAccessPolicy, String>((ref, petId) {
  final petsState = ref.watch(petsControllerProvider).asData?.value;
  if (petsState != null) {
    for (final item in petsState.items) {
      if (item.id == petId) {
        return item.accessPolicy;
      }
    }
  }

  return ref
      .read(aclApiClientProvider)
      .getMyAccess(petId)
      .then((response) => PetAccessPolicy.fromAclPolicy(
            response.member.policy,
            isOwner: response.member.isPrimaryOwner,
          ));
});

class PetsController extends AsyncNotifier<PetsState> {
  @override
  Future<PetsState> build() async {
    return _loadState(base: PetsState.initial());
  }

  Future<void> reload() async {
    final previous = state.asData?.value ?? PetsState.initial();
    state = const AsyncLoading();
    state = AsyncData(await _loadState(base: previous));
  }

  Future<void> setSearchQuery(String value) async {
    final current = state.asData?.value ?? PetsState.initial();
    state = AsyncData(current.copyWith(searchQuery: value));
  }

  Future<void> setOwnershipFilter(PetsOwnershipFilter value) async {
    final current = state.asData?.value ?? PetsState.initial();
    state = AsyncData(current.copyWith(ownershipFilter: value));
  }

  Future<void> setStatusBucket(PetsStatusBucket value) async {
    final current = state.asData?.value ?? PetsState.initial();
    state = AsyncData(current.copyWith(statusBucket: value));
  }

  Future<void> refreshAfterPetMutation() async {
    await reload();
  }

  Future<Pet> changePetStatus({
    required Pet pet,
    required String status,
  }) async {
    final updatedPet = await ref.read(petsRepositoryProvider).changeStatus(
          petId: pet.id,
          rowVersion: pet.rowVersion,
          status: status,
        );
    await reload();
    return updatedPet;
  }

  Future<String> acceptInviteByCode(String code) async {
    final result = await ref.read(petsRepositoryProvider).acceptInviteByCode(
          code.trim().toUpperCase(),
        );
    return result.petId;
  }

  Future<PetsState> _loadState({required PetsState base}) async {
    final currentUserId = await ref.read(currentUserIdProvider.future);
    if (currentUserId == null || currentUserId.isEmpty) {
      return base.copyWith(items: const <PetListEntry>[]);
    }

    final catalog = await ref.read(petCatalogProvider.future);
    final items = await ref.read(petsRepositoryProvider).listAvailablePets(
          currentUserId: currentUserId,
          catalog: catalog,
          includeArchived: true,
        );

    return base.copyWith(items: items);
  }
}
