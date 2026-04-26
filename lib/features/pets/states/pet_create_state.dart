import '../data/pet_catalog_models.dart';
import '../models/pet_form.dart';

enum PetCreateStep { basic, breed, appearance, optional, review }

const int petCreateMaxColors = petFormMaxColors;

class PetCreateState {
  const PetCreateState({
    required this.step,
    required this.draft,
    required this.breedSearchQuery,
    required this.isSubmitting,
    required this.error,
  });

  factory PetCreateState.initial() => PetCreateState(
        step: PetCreateStep.basic,
        draft: PetForm.empty(),
        breedSearchQuery: '',
        isSubmitting: false,
        error: null,
      );

  final PetCreateStep step;
  final PetForm draft;
  final String breedSearchQuery;
  final bool isSubmitting;
  final String? error;

  List<PetBreedOption> breedsForSpecies(PetCatalog catalog) {
    if (draft.speciesId == null) {
      return catalog.breeds;
    }
    return catalog.breeds
        .where((entry) => entry.speciesId == draft.speciesId)
        .toList(growable: false);
  }

  List<PetBreedOption> filteredBreeds(PetCatalog catalog) {
    final breeds = breedsForSpecies(catalog);
    final query = breedSearchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return breeds.take(12).toList(growable: false);
    }

    return breeds
        .where((entry) => entry.name.toLowerCase().contains(query))
        .take(24)
        .toList(growable: false);
  }

  List<PetColorOption> selectedCatalogColors(PetCatalog catalog) {
    return catalog.colors
        .where((entry) => draft.colorIds.contains(entry.id))
        .toList(growable: false);
  }

  PetCreateState copyWith({
    PetCreateStep? step,
    PetForm? draft,
    String? breedSearchQuery,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
  }) {
    return PetCreateState(
      step: step ?? this.step,
      draft: draft ?? this.draft,
      breedSearchQuery: breedSearchQuery ?? this.breedSearchQuery,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
