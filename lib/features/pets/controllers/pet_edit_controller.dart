import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/pet_catalog_provider.dart';
import '../models/pet_form.dart';
import '../shared/utils/pet_color_utils.dart';
import '../shared/validators/pet_form_validator.dart';
import '../states/pet_edit_state.dart';
import 'active_pet_details_controller.dart';
import 'pets_controller.dart';

final petEditControllerProvider = AsyncNotifierProvider.autoDispose
    .family<PetEditController, PetEditState, String>(
  PetEditController.new,
);

class PetEditController extends AsyncNotifier<PetEditState> {
  PetEditController(this._petId);

  final String _petId;

  @override
  Future<PetEditState> build() async {
    final pet = await ref.read(petsRepositoryProvider).getPet(_petId);
    final catalog = await ref.read(petCatalogProvider.future);
    return PetEditState.loaded(pet: pet, catalog: catalog);
  }

  void setStep(PetEditStep step) {
    _updateState((state) => state.copyWith(step: step, clearError: true));
  }

  void previousStep() {
    final current = state.asData?.value;
    if (current == null || current.step.index <= 0) return;
    setStep(PetEditStep.values[current.step.index - 1]);
  }

  void nextStep() {
    final current = state.asData?.value;
    if (current == null ||
        current.step.index >= PetEditStep.values.length - 1) {
      return;
    }
    setStep(PetEditStep.values[current.step.index + 1]);
  }

  void setName(String value) =>
      _updateDraft((draft) => draft.copyWith(name: value));

  void setSex(String value) =>
      _updateDraft((draft) => draft.copyWith(sex: value));

  void setBirthDate(DateTime? value) =>
      _updateDraft((draft) => draft.copyWith(birthDate: value));

  void setSpeciesMode(CatalogPickMode value) {
    _updateDraft(
      (draft) => draft.copyWith(
        speciesMode: value,
        clearSpeciesId: value == CatalogPickMode.custom,
        customSpeciesName:
            value == CatalogPickMode.catalog ? '' : draft.customSpeciesName,
        breedMode: value == CatalogPickMode.custom
            ? CatalogPickMode.custom
            : draft.breedMode,
        clearBreedId: value == CatalogPickMode.custom,
      ),
      resetBreedSearch: value == CatalogPickMode.custom,
    );
  }

  void setSpeciesId(String? value) {
    _updateDraft(
      (draft) => draft.copyWith(
        speciesMode: CatalogPickMode.catalog,
        speciesId: value,
        customSpeciesName: '',
        clearBreedId: value != draft.speciesId,
        breedMode: CatalogPickMode.catalog,
      ),
      resetBreedSearch: true,
    );
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
    final current = state.asData?.value;
    if (current == null) return;

    final next = <String>{...current.draft.colorIds};
    if (next.contains(id)) {
      next.remove(id);
    } else {
      if (current.draft.selectedColorsCount >= petFormMaxColors) {
        _setError('Можно выбрать до 10 цветов.');
        return;
      }
      next.add(id);
    }

    _updateDraft((draft) => draft.copyWith(colorIds: next));
  }

  void addCustomColor({
    required String hex,
    required String name,
  }) {
    final current = state.asData?.value;
    if (current == null) return;

    final normalized = normalizePetColorHex(hex);
    if (normalized == null) return;
    if (current.draft.selectedColorsCount >= petFormMaxColors) {
      _setError('Можно выбрать до 10 цветов.');
      return;
    }

    final next = <PetFormColor>[...current.draft.customColors];
    if (next.any((entry) => entry.hex == normalized)) return;
    next.add(PetFormColor(hex: normalized, name: name.trim()));
    _updateDraft((draft) => draft.copyWith(customColors: next));
  }

  void removeCustomColorAt(int index) {
    final current = state.asData?.value;
    if (current == null) return;
    if (index < 0 || index >= current.draft.customColors.length) return;
    final next = <PetFormColor>[...current.draft.customColors]..removeAt(index);
    _updateDraft((draft) => draft.copyWith(customColors: next));
  }

  void setIsNeutered(String value) =>
      _updateDraft((draft) => draft.copyWith(isNeutered: value));

  void setIsOutdoor(bool value) =>
      _updateDraft((draft) => draft.copyWith(isOutdoor: value));

  void setMicrochipId(String value) =>
      _updateDraft((draft) => draft.copyWith(microchipId: value));

  void setMicrochipInstalledAt(DateTime? value) =>
      _updateDraft((draft) => draft.copyWith(microchipInstalledAt: value));

  void setBreedSearchQuery(String value) {
    _updateState(
      (state) => state.copyWith(
        breedSearchQuery: value,
        clearError: true,
      ),
    );
  }

  Future<bool> submit() async {
    final current = state.asData?.value;
    if (current == null || current.isSubmitting) return false;

    final validationError = validatePetForm(current.draft, current.catalog);
    if (validationError != null) {
      state = AsyncData(
        current.copyWith(
          step: _stepForValidationSection(validationError.section),
          error: validationError.message,
        ),
      );
      return false;
    }

    state = AsyncData(current.copyWith(isSubmitting: true, clearError: true));

    try {
      await ref.read(petsRepositoryProvider).updatePet(
            pet: current.pet,
            draft: current.draft,
          );
      ref.invalidate(activePetDetailsControllerProvider);
      await ref.read(petsControllerProvider.notifier).refreshAfterPetMutation();
      return true;
    } catch (_) {
      final latest = state.asData?.value ?? current;
      state = AsyncData(
        latest.copyWith(
          isSubmitting: false,
          error: 'Не удалось сохранить питомца. Попробуйте снова.',
        ),
      );
      return false;
    }
  }

  void _updateDraft(
    PetForm Function(PetForm draft) update, {
    bool resetBreedSearch = false,
  }) {
    _updateState(
      (state) => state.copyWith(
        draft: update(state.draft),
        breedSearchQuery: resetBreedSearch ? '' : state.breedSearchQuery,
        clearError: true,
      ),
    );
  }

  void _updateState(PetEditState Function(PetEditState state) update) {
    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncData(update(current));
  }

  void _setError(String message) {
    final current = state.asData?.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(error: message));
  }
}

PetEditStep _stepForValidationSection(PetFormValidationSection section) {
  return switch (section) {
    PetFormValidationSection.basic => PetEditStep.basic,
    PetFormValidationSection.breed => PetEditStep.breed,
    PetFormValidationSection.appearance => PetEditStep.appearance,
    PetFormValidationSection.optional => PetEditStep.optional,
  };
}
