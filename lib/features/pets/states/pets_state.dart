import '../models/pet_list_entry.dart';

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
