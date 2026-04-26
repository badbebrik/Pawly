import 'package:flutter/material.dart';

import '../../../../../design_system/design_system.dart';
import '../../../models/pet_form.dart';
import 'pet_form_layout.dart';
import 'pet_form_pickers.dart';

class PetOptionalFormSection extends StatelessWidget {
  const PetOptionalFormSection({
    required this.draft,
    required this.microchipController,
    required this.microchipInstalledAtLabel,
    required this.onIsNeuteredChanged,
    required this.onIsOutdoorChanged,
    required this.onMicrochipIdChanged,
    required this.onMicrochipInstalledAtPressed,
    this.subtitle = 'Стерилизация, выгул и микрочип.',
    super.key,
  });

  final PetForm draft;
  final TextEditingController microchipController;
  final String microchipInstalledAtLabel;
  final ValueChanged<String> onIsNeuteredChanged;
  final ValueChanged<bool> onIsOutdoorChanged;
  final ValueChanged<String> onMicrochipIdChanged;
  final VoidCallback onMicrochipInstalledAtPressed;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return PetFormSectionCard(
      title: 'Дополнительно',
      subtitle: subtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _ThreeOptionSegment(
            title: 'Стерилизация',
            value: draft.isNeutered,
            options: const <_SegmentOption>[
              _SegmentOption(value: 'UNKNOWN', label: 'Неизв.'),
              _SegmentOption(value: 'YES', label: 'Да'),
              _SegmentOption(value: 'NO', label: 'Нет'),
            ],
            onChanged: onIsNeuteredChanged,
          ),
          const SizedBox(height: PawlySpacing.md),
          PetFormTwoOptionCardPicker<bool>(
            title: 'Уличный/свободный выгул',
            value: draft.isOutdoor,
            options: const <PetFormCardPickerOption<bool>>[
              PetFormCardPickerOption<bool>(
                value: false,
                label: 'Домашний',
                icon: Icons.home_rounded,
              ),
              PetFormCardPickerOption<bool>(
                value: true,
                label: 'Свободный выгул',
                icon: Icons.park_rounded,
                accent: Color(0xFF57A3D9),
              ),
            ],
            onChanged: onIsOutdoorChanged,
          ),
          const SizedBox(height: PawlySpacing.md),
          PawlyTextField(
            controller: microchipController,
            label: 'ID микрочипа',
            onChanged: onMicrochipIdChanged,
          ),
          const SizedBox(height: PawlySpacing.sm),
          PetFormDateButton(
            label: 'Дата установки чипа',
            value: microchipInstalledAtLabel,
            onPressed: onMicrochipInstalledAtPressed,
          ),
        ],
      ),
    );
  }
}

class _SegmentOption {
  const _SegmentOption({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;
}

class _ThreeOptionSegment extends StatelessWidget {
  const _ThreeOptionSegment({
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
  }) : assert(options.length == 3);

  final String title;
  final String value;
  final List<_SegmentOption> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: PawlySpacing.xs),
        Container(
          padding: const EdgeInsets.all(PawlySpacing.xxs),
          decoration: BoxDecoration(
            color: colorScheme.onSurface.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(PawlyRadius.lg),
          ),
          child: Row(
            children: options.map((entry) {
              return PetFormSegmentButton(
                label: entry.label,
                selected: value == entry.value,
                onTap: () => onChanged(entry.value),
              );
            }).toList(growable: false),
          ),
        ),
      ],
    );
  }
}
