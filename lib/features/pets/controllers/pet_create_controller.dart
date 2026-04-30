import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/pet_catalog_models.dart';
import '../models/pet.dart';
import '../models/pet_form.dart';
import '../shared/utils/pet_color_utils.dart';
import '../shared/validators/pet_form_validator.dart';
import '../states/pet_create_state.dart';
import 'pets_controller.dart';

final petCreateControllerProvider =
    NotifierProvider.autoDispose<PetCreateController, PetCreateState>(
  PetCreateController.new,
);

class PetCreateController extends Notifier<PetCreateState> {
  @override
  PetCreateState build() => PetCreateState.initial();

  void setName(String value) =>
      _updateDraft((draft) => draft.copyWith(name: value));

  void setSex(String value) =>
      _updateDraft((draft) => draft.copyWith(sex: value));

  void setBirthDate(DateTime? value) =>
      _updateDraft((draft) => draft.copyWith(birthDate: value));

  void setBreedSearchQuery(String value) {
    state = state.copyWith(breedSearchQuery: value, clearError: true);
  }

  void setSpeciesMode(CatalogPickMode value) {
    final clearBreedSearch = value == CatalogPickMode.custom;
    _updateDraft(
      (draft) => draft.copyWith(
        speciesMode: value,
        clearSpeciesId: value == CatalogPickMode.custom,
        breedMode: value == CatalogPickMode.custom
            ? CatalogPickMode.custom
            : draft.breedMode,
        clearBreedId: value == CatalogPickMode.custom,
        customSpeciesName:
            value == CatalogPickMode.catalog ? '' : draft.customSpeciesName,
      ),
    );
    if (clearBreedSearch) {
      state = state.copyWith(breedSearchQuery: '');
    }
  }

  void setSpeciesId(String? value) {
    final clearBreedSearch = value != state.draft.speciesId;
    _updateDraft(
      (draft) => draft.copyWith(
        speciesMode: CatalogPickMode.catalog,
        speciesId: value,
        clearBreedId: value != draft.speciesId,
        customSpeciesName: '',
      ),
    );
    if (clearBreedSearch) {
      state = state.copyWith(breedSearchQuery: '');
    }
  }

  void setCustomSpeciesName(String value) =>
      _updateDraft((draft) => draft.copyWith(customSpeciesName: value));

  void setBreedMode(CatalogPickMode value) {
    _updateDraft(
      (draft) => draft.copyWith(
        breedMode: value,
        clearBreedId: value == CatalogPickMode.custom,
        customBreedName:
            value == CatalogPickMode.catalog ? '' : draft.customBreedName,
      ),
    );
  }

  void setBreedId(String? value) =>
      _updateDraft((draft) => draft.copyWith(breedId: value));

  void setCustomBreedName(String value) =>
      _updateDraft((draft) => draft.copyWith(customBreedName: value));

  void setPatternMode(CatalogPickMode value) {
    _updateDraft(
      (draft) => draft.copyWith(
        patternMode: value,
        clearPatternId: value == CatalogPickMode.custom,
        customPatternName:
            value == CatalogPickMode.catalog ? '' : draft.customPatternName,
      ),
    );
  }

  void setPatternId(String? value) =>
      _updateDraft((draft) => draft.copyWith(patternId: value));

  void setCustomPatternName(String value) =>
      _updateDraft((draft) => draft.copyWith(customPatternName: value));

  void toggleColor(String id) {
    final draft = state.draft;
    final next = <String>{...draft.colorIds};
    if (next.contains(id)) {
      next.remove(id);
    } else {
      if (_selectedColorsCount() >= petCreateMaxColors) {
        state = state.copyWith(error: 'Можно выбрать до 10 цветов.');
        return;
      }
      next.add(id);
    }
    state = state.copyWith(
      draft: draft.copyWith(colorIds: next),
      clearError: true,
    );
  }

  void addCustomColor({
    required String hex,
    required String name,
  }) {
    final normalized = normalizePetColorHex(hex);
    if (normalized == null) return;
    if (_selectedColorsCount() >= petCreateMaxColors) {
      state = state.copyWith(error: 'Можно выбрать до 10 цветов.');
      return;
    }
    final trimmedName = name.trim();
    final draft = state.draft;
    final next = <PetFormColor>[...draft.customColors];
    final alreadyExists = next.any((entry) => entry.hex == normalized);
    if (!alreadyExists) {
      next.add(
        PetFormColor(
          hex: normalized,
          name: trimmedName,
        ),
      );
    }
    state = state.copyWith(
      draft: draft.copyWith(customColors: next),
      clearError: true,
    );
  }

  void removeCustomColorAt(int index) {
    final draft = state.draft;
    if (index < 0 || index >= draft.customColors.length) return;
    final next = <PetFormColor>[...draft.customColors]..removeAt(index);
    state = state.copyWith(
      draft: draft.copyWith(customColors: next),
      clearError: true,
    );
  }

  void setIsNeutered(String value) =>
      _updateDraft((draft) => draft.copyWith(isNeutered: value));

  void setIsOutdoor(bool value) =>
      _updateDraft((draft) => draft.copyWith(isOutdoor: value));

  void setMicrochipId(String value) =>
      _updateDraft((draft) => draft.copyWith(microchipId: value));

  void setMicrochipInstalledAt(DateTime? value) =>
      _updateDraft((draft) => draft.copyWith(microchipInstalledAt: value));

  void nextStep(PetCatalog catalog) {
    if (state.step.index >= PetCreateStep.values.length - 1) return;
    final validationError = _validateCurrentStep(catalog);
    if (validationError != null) {
      state = state.copyWith(error: validationError);
      return;
    }
    state = state.copyWith(
      step: PetCreateStep.values[state.step.index + 1],
      clearError: true,
    );
  }

  void previousStep() {
    if (state.step.index <= 0) return;
    state = state.copyWith(
      step: PetCreateStep.values[state.step.index - 1],
      clearError: true,
    );
  }

  void goToStep(PetCatalog catalog, PetCreateStep target) {
    if (target == state.step) return;
    if (target.index < state.step.index) {
      state = state.copyWith(step: target, clearError: true);
      return;
    }

    for (var i = 0; i < target.index; i++) {
      final step = PetCreateStep.values[i];
      final validationError = _validateStep(step, catalog);
      if (validationError != null) {
        state = state.copyWith(step: step, error: validationError);
        return;
      }
    }

    state = state.copyWith(step: target, clearError: true);
  }

  Future<Pet?> submit(PetCatalog catalog) async {
    if (state.isSubmitting) return null;

    final validationError = _validate(catalog);
    if (validationError != null) {
      state = state.copyWith(error: validationError);
      return null;
    }

    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final pet = await ref.read(petsRepositoryProvider).createPet(state.draft);
      state = state.copyWith(isSubmitting: false);
      return pet;
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        error: 'Не удалось создать питомца. Попробуйте снова.',
      );
      return null;
    }
  }

  void _updateDraft(PetForm Function(PetForm draft) update) {
    state = state.copyWith(
      draft: update(state.draft),
      clearError: true,
    );
  }

  int _selectedColorsCount() {
    return state.draft.selectedColorsCount;
  }

  String? _validateCurrentStep(PetCatalog catalog) {
    return _validateStep(state.step, catalog);
  }

  String? _validateStep(PetCreateStep step, PetCatalog catalog) {
    final section = _validationSectionForStep(step);
    if (section == null) return null;
    return validatePetFormSection(
      state.draft,
      catalog,
      section: section,
    )?.message;
  }

  PetFormValidationSection? _validationSectionForStep(PetCreateStep step) {
    switch (step) {
      case PetCreateStep.basic:
        return PetFormValidationSection.basic;
      case PetCreateStep.breed:
        return PetFormValidationSection.breed;
      case PetCreateStep.appearance:
        return PetFormValidationSection.appearance;
      case PetCreateStep.optional:
      case PetCreateStep.review:
        return null;
    }
  }

  String? _validate(PetCatalog catalog) {
    return validatePetForm(state.draft, catalog)?.message;
  }
}
