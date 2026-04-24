import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/models/pet_models.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../catalog/data/catalog_cache_models.dart';
import '../../data/pet_create_repository.dart';

enum CatalogPickMode { catalog, custom }

enum PetCreateStep { basic, breed, appearance, optional, review }

const int petCreateMaxColors = 10;

class CustomPetColorDraft {
  const CustomPetColorDraft({
    required this.hex,
    required this.name,
  });

  final String hex;
  final String name;
}

class PetCreateState {
  const PetCreateState({
    required this.step,
    required this.name,
    required this.sex,
    required this.birthDate,
    required this.speciesMode,
    required this.speciesId,
    required this.customSpeciesName,
    required this.breedMode,
    required this.breedId,
    required this.customBreedName,
    required this.patternMode,
    required this.patternId,
    required this.customPatternName,
    required this.colorIds,
    required this.customColorsHex,
    required this.isNeutered,
    required this.isOutdoor,
    required this.microchipId,
    required this.microchipInstalledAt,
    required this.isSubmitting,
    required this.error,
  });

  factory PetCreateState.initial() => const PetCreateState(
        step: PetCreateStep.basic,
        name: '',
        sex: 'UNKNOWN',
        birthDate: null,
        speciesMode: CatalogPickMode.catalog,
        speciesId: null,
        customSpeciesName: '',
        breedMode: CatalogPickMode.catalog,
        breedId: null,
        customBreedName: '',
        patternMode: CatalogPickMode.catalog,
        patternId: null,
        customPatternName: '',
        colorIds: <String>{},
        customColorsHex: <CustomPetColorDraft>[],
        isNeutered: 'UNKNOWN',
        isOutdoor: false,
        microchipId: '',
        microchipInstalledAt: null,
        isSubmitting: false,
        error: null,
      );

  final PetCreateStep step;
  final String name;
  final String sex;
  final DateTime? birthDate;

  final CatalogPickMode speciesMode;
  final String? speciesId;
  final String customSpeciesName;

  final CatalogPickMode breedMode;
  final String? breedId;
  final String customBreedName;

  final CatalogPickMode patternMode;
  final String? patternId;
  final String customPatternName;

  final Set<String> colorIds;
  final List<CustomPetColorDraft> customColorsHex;

  final String isNeutered;
  final bool isOutdoor;
  final String microchipId;
  final DateTime? microchipInstalledAt;

  final bool isSubmitting;
  final String? error;

  PetCreateState copyWith({
    PetCreateStep? step,
    String? name,
    String? sex,
    DateTime? birthDate,
    bool clearBirthDate = false,
    CatalogPickMode? speciesMode,
    String? speciesId,
    bool clearSpeciesId = false,
    String? customSpeciesName,
    CatalogPickMode? breedMode,
    String? breedId,
    bool clearBreedId = false,
    String? customBreedName,
    CatalogPickMode? patternMode,
    String? patternId,
    bool clearPatternId = false,
    String? customPatternName,
    Set<String>? colorIds,
    List<CustomPetColorDraft>? customColorsHex,
    String? isNeutered,
    bool? isOutdoor,
    String? microchipId,
    DateTime? microchipInstalledAt,
    bool clearMicrochipDate = false,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
  }) {
    return PetCreateState(
      step: step ?? this.step,
      name: name ?? this.name,
      sex: sex ?? this.sex,
      birthDate: clearBirthDate ? null : (birthDate ?? this.birthDate),
      speciesMode: speciesMode ?? this.speciesMode,
      speciesId: clearSpeciesId ? null : (speciesId ?? this.speciesId),
      customSpeciesName: customSpeciesName ?? this.customSpeciesName,
      breedMode: breedMode ?? this.breedMode,
      breedId: clearBreedId ? null : (breedId ?? this.breedId),
      customBreedName: customBreedName ?? this.customBreedName,
      patternMode: patternMode ?? this.patternMode,
      patternId: clearPatternId ? null : (patternId ?? this.patternId),
      customPatternName: customPatternName ?? this.customPatternName,
      colorIds: colorIds ?? this.colorIds,
      customColorsHex: customColorsHex ?? this.customColorsHex,
      isNeutered: isNeutered ?? this.isNeutered,
      isOutdoor: isOutdoor ?? this.isOutdoor,
      microchipId: microchipId ?? this.microchipId,
      microchipInstalledAt: clearMicrochipDate
          ? null
          : (microchipInstalledAt ?? this.microchipInstalledAt),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final petCreateRepositoryProvider = Provider<PetCreateRepository>((ref) {
  final petsApiClient = ref.watch(petsApiClientProvider);
  return PetCreateRepository(petsApiClient);
});

final petCreateControllerProvider =
    NotifierProvider.autoDispose<PetCreateController, PetCreateState>(
  PetCreateController.new,
);

class PetCreateController extends Notifier<PetCreateState> {
  @override
  PetCreateState build() => PetCreateState.initial();

  void setName(String value) =>
      state = state.copyWith(name: value, clearError: true);

  void setSex(String value) =>
      state = state.copyWith(sex: value, clearError: true);

  void setBirthDate(DateTime? value) =>
      state = state.copyWith(birthDate: value, clearError: true);

  void setSpeciesMode(CatalogPickMode value) {
    state = state.copyWith(
      speciesMode: value,
      clearError: true,
      clearSpeciesId: value == CatalogPickMode.custom,
      breedMode: value == CatalogPickMode.custom
          ? CatalogPickMode.custom
          : state.breedMode,
      clearBreedId: value == CatalogPickMode.custom,
      customSpeciesName:
          value == CatalogPickMode.catalog ? '' : state.customSpeciesName,
    );
  }

  void setSpeciesId(String? value) => state = state.copyWith(
        speciesMode: CatalogPickMode.catalog,
        speciesId: value,
        clearBreedId: value != state.speciesId,
        customSpeciesName: '',
        clearError: true,
      );

  void setCustomSpeciesName(String value) =>
      state = state.copyWith(customSpeciesName: value, clearError: true);

  void setBreedMode(CatalogPickMode value) {
    state = state.copyWith(
      breedMode: value,
      clearError: true,
      clearBreedId: value == CatalogPickMode.custom,
      customBreedName:
          value == CatalogPickMode.catalog ? '' : state.customBreedName,
    );
  }

  void setBreedId(String? value) =>
      state = state.copyWith(breedId: value, clearError: true);

  void setCustomBreedName(String value) =>
      state = state.copyWith(customBreedName: value, clearError: true);

  void setPatternMode(CatalogPickMode value) {
    state = state.copyWith(
      patternMode: value,
      clearError: true,
      clearPatternId: value == CatalogPickMode.custom,
      customPatternName:
          value == CatalogPickMode.catalog ? '' : state.customPatternName,
    );
  }

  void setPatternId(String? value) =>
      state = state.copyWith(patternId: value, clearError: true);

  void setCustomPatternName(String value) =>
      state = state.copyWith(customPatternName: value, clearError: true);

  void toggleColor(String id) {
    final next = <String>{...state.colorIds};
    if (next.contains(id)) {
      next.remove(id);
    } else {
      if (_selectedColorsCount() >= petCreateMaxColors) {
        state = state.copyWith(error: 'Можно выбрать до 10 цветов.');
        return;
      }
      next.add(id);
    }
    state = state.copyWith(colorIds: next, clearError: true);
  }

  void addCustomColor({
    required String hex,
    required String name,
  }) {
    final normalized = _normalizeHex(hex);
    if (normalized == null) return;
    if (_selectedColorsCount() >= petCreateMaxColors) {
      state = state.copyWith(error: 'Можно выбрать до 10 цветов.');
      return;
    }
    final trimmedName = name.trim();
    final next = <CustomPetColorDraft>[...state.customColorsHex];
    final alreadyExists = next.any((entry) => entry.hex == normalized);
    if (!alreadyExists) {
      next.add(
        CustomPetColorDraft(
          hex: normalized,
          name: trimmedName,
        ),
      );
    }
    state = state.copyWith(customColorsHex: next, clearError: true);
  }

  void removeCustomColorAt(int index) {
    if (index < 0 || index >= state.customColorsHex.length) return;
    final next = <CustomPetColorDraft>[...state.customColorsHex]
      ..removeAt(index);
    state = state.copyWith(customColorsHex: next, clearError: true);
  }

  void setIsNeutered(String value) =>
      state = state.copyWith(isNeutered: value, clearError: true);

  void setIsOutdoor(bool value) =>
      state = state.copyWith(isOutdoor: value, clearError: true);

  void setMicrochipId(String value) =>
      state = state.copyWith(microchipId: value, clearError: true);

  void setMicrochipInstalledAt(DateTime? value) =>
      state = state.copyWith(microchipInstalledAt: value, clearError: true);

  void nextStep(CatalogSnapshot catalog) {
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

  void goToStep(CatalogSnapshot catalog, PetCreateStep target) {
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

  Future<Pet?> submit(CatalogSnapshot catalog) async {
    if (state.isSubmitting) return null;

    final validationError = _validate(catalog);
    if (validationError != null) {
      state = state.copyWith(error: validationError);
      return null;
    }

    final payload = _buildRequest();
    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      final response = await ref.read(petCreateRepositoryProvider).createPet(
            payload,
          );
      state = state.copyWith(isSubmitting: false);
      return response.pet;
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        error: 'Не удалось создать питомца. Попробуйте снова.',
      );
      return null;
    }
  }

  int _selectedColorsCount() {
    return state.colorIds.length + state.customColorsHex.length;
  }

  String? _validateCurrentStep(CatalogSnapshot catalog) {
    return _validateStep(state.step, catalog);
  }

  String? _validateStep(PetCreateStep step, CatalogSnapshot catalog) {
    switch (step) {
      case PetCreateStep.basic:
        if (state.name.trim().isEmpty) return 'Введите кличку питомца';
        if (state.speciesMode == CatalogPickMode.catalog) {
          final id = state.speciesId;
          if (id == null || id.isEmpty) return 'Выберите вид питомца';
          final exists = catalog.species.any((item) => item.id == id);
          if (!exists) return 'Выбранный вид устарел. Обновите выбор.';
        } else if (state.customSpeciesName.trim().isEmpty) {
          return 'Введите свой вариант вида';
        }
        return null;
      case PetCreateStep.breed:
        if (state.breedMode == CatalogPickMode.catalog) {
          final id = state.breedId;
          if (id == null || id.isEmpty) return 'Выберите породу';
          final exists = catalog.breeds.any((item) => item.id == id);
          if (!exists) return 'Выбранная порода устарела. Обновите выбор.';
        } else if (state.customBreedName.trim().isEmpty) {
          return 'Введите свой вариант породы';
        }
        return null;
      case PetCreateStep.appearance:
        if (state.patternMode == CatalogPickMode.catalog) {
          final id = state.patternId;
          if (id == null || id.isEmpty) return 'Выберите окрас';
          final exists = catalog.patterns.any((item) => item.id == id);
          if (!exists) return 'Выбранный окрас устарел. Обновите выбор.';
        } else if (state.customPatternName.trim().isEmpty) {
          return 'Введите свой вариант окраса';
        }
        if (state.colorIds.isEmpty && state.customColorsHex.isEmpty) {
          return 'Выберите минимум один цвет';
        }
        if (_selectedColorsCount() > petCreateMaxColors) {
          return 'Можно выбрать до 10 цветов.';
        }
        return null;
      case PetCreateStep.optional:
      case PetCreateStep.review:
        return null;
    }
  }

  String? _validate(CatalogSnapshot catalog) {
    if (state.name.trim().isEmpty) return 'Введите кличку питомца';

    if (state.speciesMode == CatalogPickMode.catalog) {
      final id = state.speciesId;
      if (id == null || id.isEmpty) return 'Выберите вид питомца';
      final exists = catalog.species.any((item) => item.id == id);
      if (!exists) return 'Выбранный вид устарел. Обновите выбор.';
    } else if (state.customSpeciesName.trim().isEmpty) {
      return 'Введите свой вариант вида';
    }

    if (state.breedMode == CatalogPickMode.catalog) {
      final id = state.breedId;
      if (id == null || id.isEmpty) return 'Выберите породу';
      final exists = catalog.breeds.any((item) => item.id == id);
      if (!exists) return 'Выбранная порода устарела. Обновите выбор.';
    } else if (state.customBreedName.trim().isEmpty) {
      return 'Введите свой вариант породы';
    }

    if (state.patternMode == CatalogPickMode.catalog) {
      final id = state.patternId;
      if (id == null || id.isEmpty) return 'Выберите окрас';
      final exists = catalog.patterns.any((item) => item.id == id);
      if (!exists) return 'Выбранный окрас устарел. Обновите выбор.';
    } else if (state.customPatternName.trim().isEmpty) {
      return 'Введите свой вариант окраса';
    }

    if (state.colorIds.isEmpty && state.customColorsHex.isEmpty) {
      return 'Выберите минимум один цвет';
    }

    final invalidColorId = state.colorIds
        .any((id) => !catalog.colors.any((color) => color.id == id));
    if (invalidColorId) {
      return 'Один из выбранных цветов устарел. Обновите выбор.';
    }

    if (_selectedColorsCount() > petCreateMaxColors) {
      return 'Можно выбрать до 10 цветов.';
    }

    if (state.customColorsHex
        .any((entry) => _normalizeHex(entry.hex) == null)) {
      return 'Неверный формат пользовательского цвета';
    }

    return null;
  }

  CreatePetPayload _buildRequest() {
    final colors = <PetColor>[];
    var sortOrder = 0;

    for (final id in state.colorIds) {
      colors.add(PetColor(presetId: id, sortOrder: sortOrder++));
    }

    for (final customColor in state.customColorsHex) {
      final hex = _normalizeHex(customColor.hex)!;
      final name = customColor.name.trim();
      colors.add(
        PetColor(
          hexOverride: hex,
          note: name.isEmpty ? null : name,
          sortOrder: sortOrder++,
        ),
      );
    }

    return CreatePetPayload(
      name: state.name.trim(),
      speciesId:
          state.speciesMode == CatalogPickMode.catalog ? state.speciesId : null,
      customSpeciesName: state.speciesMode == CatalogPickMode.custom
          ? state.customSpeciesName.trim()
          : null,
      sex: state.sex,
      birthDate: state.birthDate,
      breedId: state.speciesMode == CatalogPickMode.catalog &&
              state.breedMode == CatalogPickMode.catalog
          ? state.breedId
          : null,
      customBreedName: state.breedMode == CatalogPickMode.custom
          ? state.customBreedName.trim()
          : null,
      colors: colors,
      patternId:
          state.patternMode == CatalogPickMode.catalog ? state.patternId : null,
      customPatternName: state.patternMode == CatalogPickMode.custom
          ? state.customPatternName.trim()
          : null,
      isNeutered: state.isNeutered,
      isOutdoor: state.isOutdoor,
      microchipId:
          state.microchipId.trim().isEmpty ? null : state.microchipId.trim(),
      microchipInstalledAt: state.microchipInstalledAt,
    );
  }

  String? _normalizeHex(String input) {
    final value = input.trim().toUpperCase();
    final prepared = value.startsWith('#') ? value : '#$value';
    if (prepared.length != 7) return null;
    if (int.tryParse(prepared.substring(1), radix: 16) == null) return null;
    return prepared;
  }
}
