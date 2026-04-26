import 'package:flutter/material.dart';

import '../../../../../design_system/design_system.dart';
import '../../../data/pet_catalog_models.dart';
import '../../formatters/pet_species_icon_formatter.dart';

class PetFormCardPickerOption<T> {
  const PetFormCardPickerOption({
    required this.value,
    required this.label,
    required this.icon,
    this.accent,
  });

  final T value;
  final String label;
  final IconData icon;
  final Color? accent;
}

class PetFormTwoOptionCardPicker<T> extends StatelessWidget {
  const PetFormTwoOptionCardPicker({
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
    super.key,
  }) : assert(options.length == 2);

  final String title;
  final T value;
  final List<PetFormCardPickerOption<T>> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: PawlySpacing.xs),
        Row(
          children: <Widget>[
            Expanded(
              child: _PetFormOptionCard<T>(
                option: options[0],
                selected: value == options[0].value,
                onTap: () => onChanged(options[0].value),
              ),
            ),
            const SizedBox(width: PawlySpacing.sm),
            Expanded(
              child: _PetFormOptionCard<T>(
                option: options[1],
                selected: value == options[1].value,
                onTap: () => onChanged(options[1].value),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PetFormOptionCard<T> extends StatelessWidget {
  const _PetFormOptionCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final PetFormCardPickerOption<T> option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = option.accent ?? colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PawlyRadius.lg),
        child: Ink(
          height: 92,
          padding: const EdgeInsets.all(PawlySpacing.md),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.12)
                : colorScheme.onSurface.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(PawlyRadius.lg),
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: 0.40)
                  : colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                option.icon,
                color: selected ? accent : colorScheme.onSurfaceVariant,
                size: 28,
              ),
              const Spacer(),
              Text(
                option.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: selected ? accent : colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PetFormModeToggle<T> extends StatelessWidget {
  const PetFormModeToggle({
    required this.title,
    required this.value,
    required this.catalogValue,
    required this.customValue,
    required this.onChanged,
    super.key,
  });

  final String title;
  final T value;
  final T catalogValue;
  final T customValue;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: PawlySpacing.xs),
        Container(
          padding: const EdgeInsets.all(PawlySpacing.xxs),
          decoration: BoxDecoration(
            color: colorScheme.onSurface.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(PawlyRadius.lg),
          ),
          child: Row(
            children: <Widget>[
              PetFormSegmentButton(
                label: 'Из каталога',
                selected: value == catalogValue,
                onTap: () => onChanged(catalogValue),
              ),
              PetFormSegmentButton(
                label: 'Свой вариант',
                selected: value == customValue,
                onTap: () => onChanged(customValue),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class PetFormSegmentButton extends StatelessWidget {
  const PetFormSegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(PawlySpacing.xxxs),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(PawlyRadius.md),
            child: AnimatedContainer(
              duration: PawlyMotion.quick,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? colorScheme.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(PawlyRadius.md),
                boxShadow: selected
                    ? <BoxShadow>[
                        BoxShadow(
                          color: colorScheme.shadow.withValues(alpha: 0.07),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: selected
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PetFormSpeciesGridPicker extends StatelessWidget {
  const PetFormSpeciesGridPicker({
    required this.species,
    required this.selectedId,
    required this.onChanged,
    super.key,
  });

  final List<PetSpeciesOption> species;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 520 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: species.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: PawlySpacing.sm,
            crossAxisSpacing: PawlySpacing.sm,
            childAspectRatio: 1.38,
          ),
          itemBuilder: (context, index) {
            final item = species[index];
            return _PetFormSpeciesCard(
              option: item,
              selected: selectedId == item.id,
              onTap: () => onChanged(item.id),
            );
          },
        );
      },
    );
  }
}

class _PetFormSpeciesCard extends StatelessWidget {
  const _PetFormSpeciesCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final PetSpeciesOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PawlyRadius.lg),
        child: Ink(
          padding: const EdgeInsets.all(PawlySpacing.md),
          decoration: BoxDecoration(
            color: selected
                ? colorScheme.primary.withValues(alpha: 0.10)
                : colorScheme.onSurface.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(PawlyRadius.lg),
            border: Border.all(
              color: selected
                  ? colorScheme.primary.withValues(alpha: 0.36)
                  : colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                petSpeciesEmoji(option),
                style: const TextStyle(fontSize: 30, height: 1),
              ),
              const Spacer(),
              Text(
                option.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: selected ? colorScheme.primary : colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PetFormBreedSearchPicker extends StatelessWidget {
  const PetFormBreedSearchPicker({
    required this.controller,
    required this.query,
    required this.breeds,
    required this.totalCount,
    required this.selectedId,
    required this.onQueryChanged,
    required this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final String query;
  final List<PetBreedOption> breeds;
  final int totalCount;
  final String? selectedId;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final trimmedQuery = query.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TextField(
          controller: controller,
          onChanged: onQueryChanged,
          decoration: InputDecoration(
            hintText: 'Поиск породы',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: trimmedQuery.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      controller.clear();
                      onQueryChanged('');
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
        ),
        const SizedBox(height: PawlySpacing.sm),
        if (breeds.isEmpty)
          Text(
            totalCount == 0
                ? 'Для выбранного вида пород нет.'
                : 'Ничего не найдено.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: breeds.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: PawlySpacing.xs),
            itemBuilder: (context, index) {
              final breed = breeds[index];
              return _PetFormBreedSearchResultTile(
                breed: breed,
                selected: selectedId == breed.id,
                onTap: () => onChanged(breed.id),
              );
            },
          ),
      ],
    );
  }
}

class _PetFormBreedSearchResultTile extends StatelessWidget {
  const _PetFormBreedSearchResultTile({
    required this.breed,
    required this.selected,
    required this.onTap,
  });

  final PetBreedOption breed;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PawlyRadius.md),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: PawlySpacing.md,
            vertical: PawlySpacing.sm,
          ),
          decoration: BoxDecoration(
            color: selected
                ? colorScheme.primary.withValues(alpha: 0.10)
                : colorScheme.onSurface.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(PawlyRadius.md),
            border: Border.all(
              color: selected
                  ? colorScheme.primary.withValues(alpha: 0.28)
                  : colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  breed.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (selected)
                Icon(
                  Icons.check_circle_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
