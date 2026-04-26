import '../../data/pet_catalog_models.dart';
import '../../models/pet_form.dart';
import 'pet_value_formatters.dart';

String petSpeciesLabel(PetCatalog catalog, PetForm draft) {
  if (draft.speciesMode == CatalogPickMode.custom) {
    return petMissingValueLabel(draft.customSpeciesName);
  }
  return petCatalogSpeciesName(
    catalog.species,
    draft.speciesId,
    fallback: 'Не выбран',
  );
}

String petBreedLabel(PetCatalog catalog, PetForm draft) {
  if (draft.breedMode == CatalogPickMode.custom) {
    return petMissingValueLabel(draft.customBreedName);
  }
  return petCatalogBreedName(
    catalog.breeds,
    draft.breedId,
    fallback: 'Не выбрана',
  );
}

String petPatternLabel(PetCatalog catalog, PetForm draft) {
  if (draft.patternMode == CatalogPickMode.custom) {
    return petMissingValueLabel(draft.customPatternName);
  }
  return petCatalogPatternName(
    catalog.patterns,
    draft.patternId,
    fallback: 'Не выбран',
  );
}

String petSpeciesLabelFromValues(
  PetCatalog catalog, {
  required String? speciesId,
  required String? customSpeciesName,
  String fallback = 'Неизвестный вид',
}) {
  final customName = customSpeciesName?.trim();
  if (customName != null && customName.isNotEmpty) {
    return customName;
  }
  return petCatalogSpeciesName(
    catalog.species,
    speciesId,
    fallback: fallback,
  );
}

String petCatalogSpeciesName(
  List<PetSpeciesOption> options,
  String? id, {
  required String fallback,
}) {
  if (id == null || id.isEmpty) return fallback;
  for (final option in options) {
    if (option.id != id) continue;
    final name = option.name.trim();
    if (name.isNotEmpty) return name;
  }
  return fallback;
}

String petCatalogBreedName(
  List<PetBreedOption> options,
  String? id, {
  required String fallback,
}) {
  if (id == null || id.isEmpty) return fallback;
  for (final option in options) {
    if (option.id != id) continue;
    final name = option.name.trim();
    if (name.isNotEmpty) return name;
  }
  return fallback;
}

String petCatalogPatternName(
  List<PetCoatPatternOption> options,
  String? id, {
  required String fallback,
}) {
  if (id == null || id.isEmpty) return fallback;
  for (final option in options) {
    if (option.id != id) continue;
    final name = option.name.trim();
    if (name.isNotEmpty) return name;
  }
  return fallback;
}
