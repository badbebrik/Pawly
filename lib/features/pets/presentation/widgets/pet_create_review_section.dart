import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../data/pet_catalog_models.dart';
import '../../models/pet_form.dart';
import '../../shared/formatters/pet_date_formatters.dart';
import '../../shared/formatters/pet_value_formatters.dart';
import '../../shared/widgets/form/pet_form.dart';

class PetCreateReviewSection extends StatelessWidget {
  const PetCreateReviewSection({
    required this.draft,
    required this.speciesName,
    required this.breedName,
    required this.patternName,
    required this.selectedCatalogColors,
    required this.isSubmitting,
    required this.onSubmit,
    super.key,
  });

  final PetForm draft;
  final String speciesName;
  final String breedName;
  final String patternName;
  final List<PetColorOption> selectedCatalogColors;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _ReviewIntroCard(
          title: 'Проверьте данные',
          subtitle: 'После создания питомца можно будет дополнить карточку.',
        ),
        const SizedBox(height: PawlySpacing.sm),
        SizedBox(
          width: double.infinity,
          child: _ReviewCard(
            title: Text(
              'Основное',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            child: Column(
              children: <Widget>[
                _ReviewRow(
                  label: 'Кличка',
                  value: draft.name.trim(),
                ),
                _ReviewRow(
                  label: 'Пол',
                  value: petSexLabel(draft.sex),
                ),
                _ReviewRow(label: 'Вид', value: speciesName),
                _ReviewRow(label: 'Порода', value: breedName),
                _ReviewRow(
                  label: 'Окрас',
                  value: patternName,
                  isLast: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: PawlySpacing.sm),
        SizedBox(
          width: double.infinity,
          child: _ReviewCard(
            title: Text(
              'Внешность',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Цвета',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: PawlySpacing.sm),
                if (selectedCatalogColors.isNotEmpty ||
                    draft.customColors.isNotEmpty)
                  Wrap(
                    spacing: PawlySpacing.xs,
                    runSpacing: PawlySpacing.xs,
                    children: <Widget>[
                      ...selectedCatalogColors.map(
                        (color) => PetFormCatalogColorChip(
                          label: color.name,
                          hex: color.hex,
                          selected: true,
                        ),
                      ),
                      ...draft.customColors.map(
                        (color) => PetFormCustomColorChip(
                          color: PetFormCustomColor(
                            hex: color.hex,
                            name: color.name,
                          ),
                          onDeleted: null,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    'Не выбраны',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: PawlySpacing.sm),
        SizedBox(
          width: double.infinity,
          child: _ReviewCard(
            title: Text(
              'Дополнительно',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            child: Column(
              children: <Widget>[
                _ReviewRow(
                  label: 'Дата рождения',
                  value: petFormDateLabel(draft.birthDate),
                ),
                _ReviewRow(
                  label: 'Стерилизация',
                  value: petYesNoUnknownLabel(draft.isNeutered),
                ),
                _ReviewRow(
                  label: 'Свободный выгул',
                  value: petBooleanLabel(draft.isOutdoor),
                ),
                _ReviewRow(
                  label: 'Микрочип',
                  value: petMissingValueLabel(draft.microchipId),
                ),
                _ReviewRow(
                  label: 'Дата установки чипа',
                  value: petFormDateLabel(draft.microchipInstalledAt),
                  isLast: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: PawlySpacing.lg),
        PawlyButton(
          label: isSubmitting ? 'Создаем...' : 'Создать питомца',
          onPressed: isSubmitting ? null : onSubmit,
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.title,
    required this.child,
  });

  final Widget title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(PawlySpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(PawlyRadius.xl),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          title,
          const SizedBox(height: PawlySpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _ReviewIntroCard extends StatelessWidget {
  const _ReviewIntroCard({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(PawlySpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(PawlyRadius.xl),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: PawlySpacing.xxs),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : PawlySpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(width: PawlySpacing.md),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}
