import 'package:flutter/material.dart';

import '../../../../../design_system/design_system.dart';
import '../../../data/pet_catalog_models.dart';
import '../../../models/pet_form.dart';
import 'pet_form_colors.dart';
import 'pet_form_layout.dart';
import 'pet_form_models.dart';
import 'pet_form_pickers.dart';

class PetAppearanceFormSection extends StatelessWidget {
  const PetAppearanceFormSection({
    required this.draft,
    required this.patterns,
    required this.colors,
    required this.customPatternController,
    required this.maxColors,
    required this.onPatternModeChanged,
    required this.onPatternChanged,
    required this.onCustomPatternChanged,
    required this.onColorToggled,
    required this.onCustomColorDeleted,
    required this.onCustomColorPressed,
    this.subtitle = 'Окрас и основные цвета питомца.',
    super.key,
  });

  final PetForm draft;
  final List<PetCoatPatternOption> patterns;
  final List<PetColorOption> colors;
  final TextEditingController customPatternController;
  final int maxColors;
  final ValueChanged<CatalogPickMode> onPatternModeChanged;
  final ValueChanged<String?> onPatternChanged;
  final ValueChanged<String> onCustomPatternChanged;
  final ValueChanged<String> onColorToggled;
  final ValueChanged<int> onCustomColorDeleted;
  final VoidCallback onCustomColorPressed;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return PetFormSectionCard(
      title: 'Внешность',
      subtitle: subtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          PetFormModeToggle<CatalogPickMode>(
            title: 'Окрас',
            value: draft.patternMode,
            catalogValue: CatalogPickMode.catalog,
            customValue: CatalogPickMode.custom,
            onChanged: onPatternModeChanged,
          ),
          const SizedBox(height: PawlySpacing.sm),
          if (draft.patternMode == CatalogPickMode.catalog)
            DropdownButtonFormField<String>(
              initialValue: draft.patternId,
              decoration: const InputDecoration(labelText: 'Выберите окрас'),
              items: patterns
                  .map(
                    (entry) => DropdownMenuItem<String>(
                      value: entry.id,
                      child: Text(entry.name),
                    ),
                  )
                  .toList(growable: false),
              onChanged: onPatternChanged,
            )
          else
            PawlyTextField(
              controller: customPatternController,
              label: 'Свой окрас',
              onChanged: onCustomPatternChanged,
            ),
          const SizedBox(height: PawlySpacing.md),
          Text(
            'Цвета · ${draft.selectedColorsCount}/$maxColors',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: PawlySpacing.xs),
          Wrap(
            spacing: PawlySpacing.xs,
            runSpacing: PawlySpacing.xs,
            children: colors.map((entry) {
              final selected = draft.colorIds.contains(entry.id);
              return PetFormCatalogColorChip(
                label: entry.name,
                hex: entry.hex,
                selected: selected,
                onTap: () => onColorToggled(entry.id),
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: PawlySpacing.sm),
          Wrap(
            spacing: PawlySpacing.xs,
            runSpacing: PawlySpacing.xs,
            children: <Widget>[
              ...draft.customColors.asMap().entries.map(
                    (entry) => PetFormCustomColorChip(
                      color: PetFormCustomColor(
                        hex: entry.value.hex,
                        name: entry.value.name,
                      ),
                      onDeleted: () => onCustomColorDeleted(entry.key),
                    ),
                  ),
              ActionChip(
                label: const Text('Свой цвет'),
                avatar: const Icon(Icons.add_rounded, size: 18),
                onPressed: draft.selectedColorsCount >= maxColors
                    ? null
                    : onCustomColorPressed,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
