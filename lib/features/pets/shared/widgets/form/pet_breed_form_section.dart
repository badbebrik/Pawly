import 'package:flutter/material.dart';

import '../../../../../design_system/design_system.dart';
import '../../../data/pet_catalog_models.dart';
import '../../../models/pet_form.dart';
import 'pet_form_layout.dart';
import 'pet_form_pickers.dart';

class PetBreedFormSection extends StatelessWidget {
  const PetBreedFormSection({
    required this.draft,
    required this.searchController,
    required this.customBreedController,
    required this.searchQuery,
    required this.breeds,
    required this.totalBreedCount,
    required this.onBreedModeChanged,
    required this.onSearchQueryChanged,
    required this.onBreedChanged,
    required this.onCustomBreedChanged,
    this.subtitle,
    super.key,
  });

  final PetForm draft;
  final TextEditingController searchController;
  final TextEditingController customBreedController;
  final String searchQuery;
  final List<PetBreedOption> breeds;
  final int totalBreedCount;
  final ValueChanged<CatalogPickMode> onBreedModeChanged;
  final ValueChanged<String> onSearchQueryChanged;
  final ValueChanged<String?> onBreedChanged;
  final ValueChanged<String> onCustomBreedChanged;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return PetFormSectionCard(
      title: 'Порода',
      subtitle: subtitle ??
          (draft.speciesMode == CatalogPickMode.custom
              ? 'Для своего вида укажите породу вручную.'
              : 'Выберите породу из каталога или укажите свою.'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (draft.speciesMode == CatalogPickMode.catalog) ...[
            PetFormModeToggle<CatalogPickMode>(
              title: 'Порода',
              value: draft.breedMode,
              catalogValue: CatalogPickMode.catalog,
              customValue: CatalogPickMode.custom,
              onChanged: onBreedModeChanged,
            ),
            const SizedBox(height: PawlySpacing.sm),
          ],
          if (draft.speciesMode == CatalogPickMode.catalog &&
              draft.breedMode == CatalogPickMode.catalog)
            PetFormBreedSearchPicker(
              controller: searchController,
              query: searchQuery,
              breeds: breeds,
              totalCount: totalBreedCount,
              selectedId: draft.breedId,
              onQueryChanged: onSearchQueryChanged,
              onChanged: onBreedChanged,
            )
          else
            PawlyTextField(
              controller: customBreedController,
              label: 'Своя порода',
              onChanged: onCustomBreedChanged,
            ),
        ],
      ),
    );
  }
}
