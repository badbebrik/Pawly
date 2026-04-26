import '../../data/pet_catalog_models.dart';
import '../../models/pet_form.dart';
import '../utils/pet_color_utils.dart';

enum PetFormValidationSection { basic, breed, appearance, optional }

class PetFormValidationError {
  const PetFormValidationError({
    required this.section,
    required this.message,
  });

  final PetFormValidationSection section;
  final String message;
}

PetFormValidationError? validatePetForm(
  PetForm draft,
  PetCatalog catalog,
) {
  for (final section in const <PetFormValidationSection>[
    PetFormValidationSection.basic,
    PetFormValidationSection.breed,
    PetFormValidationSection.appearance,
  ]) {
    final error = validatePetFormSection(
      draft,
      catalog,
      section: section,
    );
    if (error != null) return error;
  }

  return null;
}

PetFormValidationError? validatePetFormSection(
  PetForm draft,
  PetCatalog catalog, {
  required PetFormValidationSection section,
}) {
  switch (section) {
    case PetFormValidationSection.basic:
      return _validateBasic(draft, catalog);
    case PetFormValidationSection.breed:
      return _validateBreed(draft, catalog);
    case PetFormValidationSection.appearance:
      return _validateAppearance(draft, catalog);
    case PetFormValidationSection.optional:
      return null;
  }
}

PetFormValidationError? _validateBasic(
  PetForm draft,
  PetCatalog catalog,
) {
  if (draft.name.trim().isEmpty) {
    return const PetFormValidationError(
      section: PetFormValidationSection.basic,
      message: 'Введите кличку питомца',
    );
  }

  if (draft.speciesMode == CatalogPickMode.catalog) {
    final id = draft.speciesId;
    if (id == null || id.isEmpty) {
      return const PetFormValidationError(
        section: PetFormValidationSection.basic,
        message: 'Выберите вид питомца',
      );
    }
    final exists = catalog.species.any((item) => item.id == id);
    if (!exists) {
      return const PetFormValidationError(
        section: PetFormValidationSection.basic,
        message: 'Выбранный вид устарел. Обновите выбор.',
      );
    }
  } else if (draft.customSpeciesName.trim().isEmpty) {
    return const PetFormValidationError(
      section: PetFormValidationSection.basic,
      message: 'Введите свой вариант вида',
    );
  }

  return null;
}

PetFormValidationError? _validateBreed(
  PetForm draft,
  PetCatalog catalog,
) {
  if (draft.breedMode == CatalogPickMode.catalog) {
    final id = draft.breedId;
    if (id == null || id.isEmpty) {
      return const PetFormValidationError(
        section: PetFormValidationSection.breed,
        message: 'Выберите породу',
      );
    }
    final exists = catalog.breeds.any((item) => item.id == id);
    if (!exists) {
      return const PetFormValidationError(
        section: PetFormValidationSection.breed,
        message: 'Выбранная порода устарела. Обновите выбор.',
      );
    }
  } else if (draft.customBreedName.trim().isEmpty) {
    return const PetFormValidationError(
      section: PetFormValidationSection.breed,
      message: 'Введите свой вариант породы',
    );
  }

  return null;
}

PetFormValidationError? _validateAppearance(
  PetForm draft,
  PetCatalog catalog,
) {
  if (draft.patternMode == CatalogPickMode.catalog) {
    final id = draft.patternId;
    if (id == null || id.isEmpty) {
      return const PetFormValidationError(
        section: PetFormValidationSection.appearance,
        message: 'Выберите окрас',
      );
    }
    final exists = catalog.patterns.any((item) => item.id == id);
    if (!exists) {
      return const PetFormValidationError(
        section: PetFormValidationSection.appearance,
        message: 'Выбранный окрас устарел. Обновите выбор.',
      );
    }
  } else if (draft.customPatternName.trim().isEmpty) {
    return const PetFormValidationError(
      section: PetFormValidationSection.appearance,
      message: 'Введите свой вариант окраса',
    );
  }

  if (draft.colorIds.isEmpty && draft.customColors.isEmpty) {
    return const PetFormValidationError(
      section: PetFormValidationSection.appearance,
      message: 'Выберите минимум один цвет',
    );
  }

  final invalidColorId = draft.colorIds.any(
    (id) => !catalog.colors.any((color) => color.id == id),
  );
  if (invalidColorId) {
    return const PetFormValidationError(
      section: PetFormValidationSection.appearance,
      message: 'Один из выбранных цветов устарел. Обновите выбор.',
    );
  }

  if (draft.selectedColorsCount > petFormMaxColors) {
    return const PetFormValidationError(
      section: PetFormValidationSection.appearance,
      message: 'Можно выбрать до 10 цветов.',
    );
  }

  final invalidCustomColor = draft.customColors.any(
    (entry) => normalizePetColorHex(entry.hex) == null,
  );
  if (invalidCustomColor) {
    return const PetFormValidationError(
      section: PetFormValidationSection.appearance,
      message: 'Неверный формат пользовательского цвета',
    );
  }

  return null;
}
