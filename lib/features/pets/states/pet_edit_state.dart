import '../data/pet_catalog_models.dart';
import '../models/pet.dart';
import '../models/pet_form.dart';
import '../shared/mappers/pet_form_mapper.dart';

enum PetEditStep { basic, breed, appearance, optional }

class PetEditState {
  const PetEditState({
    required this.pet,
    required this.catalog,
    required this.draft,
    required this.step,
    required this.breedSearchQuery,
    required this.isSubmitting,
    required this.error,
  });

  factory PetEditState.loaded({
    required Pet pet,
    required PetCatalog catalog,
  }) {
    return PetEditState(
      pet: pet,
      catalog: catalog,
      draft: petFormFromPet(pet),
      step: PetEditStep.basic,
      breedSearchQuery: '',
      isSubmitting: false,
      error: null,
    );
  }

  final Pet pet;
  final PetCatalog catalog;
  final PetForm draft;
  final PetEditStep step;
  final String breedSearchQuery;
  final bool isSubmitting;
  final String? error;

  List<PetBreedOption> get breedsForSpecies {
    return catalog.breeds
        .where((entry) => entry.speciesId == draft.speciesId)
        .toList(growable: false);
  }

  List<PetBreedOption> get filteredBreeds {
    final query = breedSearchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return _defaultBreedResults(
        breedsForSpecies,
        selectedId: draft.breedId,
      );
    }

    return breedsForSpecies
        .where((entry) => entry.name.toLowerCase().contains(query))
        .take(24)
        .toList(growable: false);
  }

  PetEditState copyWith({
    Pet? pet,
    PetCatalog? catalog,
    PetForm? draft,
    PetEditStep? step,
    String? breedSearchQuery,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
  }) {
    return PetEditState(
      pet: pet ?? this.pet,
      catalog: catalog ?? this.catalog,
      draft: draft ?? this.draft,
      step: step ?? this.step,
      breedSearchQuery: breedSearchQuery ?? this.breedSearchQuery,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

List<PetBreedOption> _defaultBreedResults(
  List<PetBreedOption> breeds, {
  required String? selectedId,
}) {
  final results = breeds.take(12).toList(growable: true);
  if (selectedId == null || selectedId.isEmpty) {
    return results;
  }
  final selectedAlreadyVisible = results.any((entry) => entry.id == selectedId);
  if (selectedAlreadyVisible) {
    return results;
  }
  for (final breed in breeds) {
    if (breed.id != selectedId) continue;
    results.insert(0, breed);
    break;
  }
  return results;
}
