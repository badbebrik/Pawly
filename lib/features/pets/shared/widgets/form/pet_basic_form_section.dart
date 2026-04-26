import 'package:flutter/material.dart';

import '../../../../../design_system/design_system.dart';
import '../../../data/pet_catalog_models.dart';
import '../../../models/pet_form.dart';
import '../../formatters/pet_value_formatters.dart';
import 'pet_form_layout.dart';
import 'pet_form_pickers.dart';

class PetBasicFormSection extends StatelessWidget {
  const PetBasicFormSection({
    required this.draft,
    required this.species,
    required this.nameController,
    required this.customSpeciesController,
    required this.birthDateLabel,
    required this.onNameChanged,
    required this.onSexChanged,
    required this.onSpeciesModeChanged,
    required this.onSpeciesChanged,
    required this.onCustomSpeciesChanged,
    required this.onBirthDatePressed,
    this.onClearSex,
    super.key,
  });

  final PetForm draft;
  final List<PetSpeciesOption> species;
  final TextEditingController nameController;
  final TextEditingController customSpeciesController;
  final String birthDateLabel;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onSexChanged;
  final ValueChanged<CatalogPickMode> onSpeciesModeChanged;
  final ValueChanged<String?> onSpeciesChanged;
  final ValueChanged<String> onCustomSpeciesChanged;
  final VoidCallback onBirthDatePressed;
  final VoidCallback? onClearSex;

  @override
  Widget build(BuildContext context) {
    return PetFormSectionCard(
      title: 'Основное',
      subtitle: 'Кличка, пол, вид и дата рождения.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          PawlyTextField(
            controller: nameController,
            label: 'Кличка',
            onChanged: onNameChanged,
          ),
          const SizedBox(height: PawlySpacing.md),
          PetFormTwoOptionCardPicker<String>(
            title: 'Пол',
            value: draft.sex,
            options: <PetFormCardPickerOption<String>>[
              PetFormCardPickerOption<String>(
                value: 'MALE',
                label: petSexLabel('MALE'),
                icon: Icons.male_rounded,
                accent: const Color(0xFF3D87D8),
              ),
              PetFormCardPickerOption<String>(
                value: 'FEMALE',
                label: petSexLabel('FEMALE'),
                icon: Icons.female_rounded,
                accent: const Color(0xFFE86A9A),
              ),
            ],
            onChanged: onSexChanged,
          ),
          if (onClearSex != null && draft.sex != 'UNKNOWN')
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onClearSex,
                child: const Text('Не указывать'),
              ),
            ),
          const SizedBox(height: PawlySpacing.md),
          PetFormModeToggle<CatalogPickMode>(
            title: 'Вид',
            value: draft.speciesMode,
            catalogValue: CatalogPickMode.catalog,
            customValue: CatalogPickMode.custom,
            onChanged: onSpeciesModeChanged,
          ),
          const SizedBox(height: PawlySpacing.sm),
          if (draft.speciesMode == CatalogPickMode.catalog)
            PetFormSpeciesGridPicker(
              species: species,
              selectedId: draft.speciesId,
              onChanged: onSpeciesChanged,
            )
          else
            PawlyTextField(
              controller: customSpeciesController,
              label: 'Свой вид',
              onChanged: onCustomSpeciesChanged,
            ),
          const SizedBox(height: PawlySpacing.md),
          PetFormDateButton(
            label: 'Дата рождения',
            value: birthDateLabel,
            onPressed: onBirthDatePressed,
          ),
        ],
      ),
    );
  }
}
