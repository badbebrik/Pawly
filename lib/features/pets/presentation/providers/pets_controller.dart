import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/models/pet_models.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../catalog/presentation/providers/pet_dictionaries_providers.dart';
import '../../data/pets_repository.dart';

enum PetsOwnershipFilter { all, owned, shared }

enum PetsStatusBucket { active, archive }

class PetsState {
  const PetsState({
    required this.items,
    required this.searchQuery,
    required this.ownershipFilter,
    required this.statusBucket,
  });

  factory PetsState.initial() => const PetsState(
        items: <PetListEntry>[],
        searchQuery: '',
        ownershipFilter: PetsOwnershipFilter.all,
        statusBucket: PetsStatusBucket.active,
      );

  final List<PetListEntry> items;
  final String searchQuery;
  final PetsOwnershipFilter ownershipFilter;
  final PetsStatusBucket statusBucket;

  List<PetListEntry> get filteredItems {
    final normalizedQuery = searchQuery.trim().toLowerCase();

    return items.where((item) {
      final matchesBucket = switch (statusBucket) {
        PetsStatusBucket.active => item.pet.status != 'ARCHIVED',
        PetsStatusBucket.archive => item.pet.status == 'ARCHIVED',
      };
      final matchesFilter = switch (ownershipFilter) {
        PetsOwnershipFilter.all => true,
        PetsOwnershipFilter.owned => item.isOwnedByMe,
        PetsOwnershipFilter.shared => !item.isOwnedByMe,
      };

      if (!matchesBucket || !matchesFilter) {
        return false;
      }

      if (normalizedQuery.isEmpty) {
        return true;
      }

      return item.name.toLowerCase().contains(normalizedQuery);
    }).toList(growable: false);
  }

  PetsState copyWith({
    List<PetListEntry>? items,
    String? searchQuery,
    PetsOwnershipFilter? ownershipFilter,
    PetsStatusBucket? statusBucket,
  }) {
    return PetsState(
      items: items ?? this.items,
      searchQuery: searchQuery ?? this.searchQuery,
      ownershipFilter: ownershipFilter ?? this.ownershipFilter,
      statusBucket: statusBucket ?? this.statusBucket,
    );
  }
}

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

    final catalog = await ref.read(petDictionariesSyncProvider.future);
    final items = await ref.read(petsRepositoryProvider).listAvailablePets(
          currentUserId: currentUserId,
          catalog: catalog,
          includeArchived: true,
        );

    return base.copyWith(items: items);
  }
}
