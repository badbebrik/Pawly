import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../models/pet_list_entry.dart';
import '../../shared/formatters/pet_value_formatters.dart';
import '../../states/pets_state.dart';
import 'pet_list_card.dart';

class PetsListView extends StatelessWidget {
  const PetsListView({
    required this.state,
    required this.onSearchChanged,
    required this.onStatusBucketChanged,
    required this.onOwnershipFilterChanged,
    required this.onPetSelected,
    required this.onRestorePet,
    super.key,
  });

  final PetsState state;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<PetsStatusBucket> onStatusBucketChanged;
  final ValueChanged<PetsOwnershipFilter> onOwnershipFilterChanged;
  final ValueChanged<PetListEntry> onPetSelected;
  final ValueChanged<PetListEntry> onRestorePet;

  @override
  Widget build(BuildContext context) {
    final items = state.filteredItems;
    final bucketCount = state.items.where((item) {
      return switch (state.statusBucket) {
        PetsStatusBucket.active => item.pet.status != 'ARCHIVED',
        PetsStatusBucket.archive => item.pet.status == 'ARCHIVED',
      };
    }).length;

    return ColoredBox(
      color: pawlyGroupedBackground(context),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          PawlySpacing.md,
          PawlySpacing.md,
          PawlySpacing.md,
          112,
        ),
        children: <Widget>[
          _PetsSearchField(
            initialValue: state.searchQuery,
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: PawlySpacing.md),
          _PetsSegmentedControl<PetsStatusBucket>(
            value: state.statusBucket,
            options: const <_PetsSegmentOption<PetsStatusBucket>>[
              _PetsSegmentOption<PetsStatusBucket>(
                value: PetsStatusBucket.active,
                label: 'Активные',
              ),
              _PetsSegmentOption<PetsStatusBucket>(
                value: PetsStatusBucket.archive,
                label: 'Архив',
              ),
            ],
            onChanged: onStatusBucketChanged,
          ),
          const SizedBox(height: PawlySpacing.sm),
          _PetsSegmentedControl<PetsOwnershipFilter>(
            value: state.ownershipFilter,
            compact: true,
            options: const <_PetsSegmentOption<PetsOwnershipFilter>>[
              _PetsSegmentOption<PetsOwnershipFilter>(
                value: PetsOwnershipFilter.all,
                label: 'Все',
              ),
              _PetsSegmentOption<PetsOwnershipFilter>(
                value: PetsOwnershipFilter.owned,
                label: 'Мои',
              ),
              _PetsSegmentOption<PetsOwnershipFilter>(
                value: PetsOwnershipFilter.shared,
                label: 'Не мои',
              ),
            ],
            onChanged: onOwnershipFilterChanged,
          ),
          const SizedBox(height: PawlySpacing.md),
          _PetsSectionHeader(
            title: state.statusBucket == PetsStatusBucket.archive
                ? 'Архив'
                : 'Питомцы',
            count: bucketCount == items.length
                ? petCardCountLabel(items.length)
                : '${petCardCountLabel(items.length)} из $bucketCount',
          ),
          const SizedBox(height: PawlySpacing.xs),
          if (items.isEmpty)
            _PetsEmptyState(statusBucket: state.statusBucket)
          else
            _PetsCardsLayout(
              items: items,
              itemBuilder: (item) => PetListCard(
                entry: item,
                onTap: state.statusBucket == PetsStatusBucket.archive
                    ? null
                    : () => onPetSelected(item),
                onRestore: state.statusBucket == PetsStatusBucket.archive
                    ? () => onRestorePet(item)
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}

class _PetsSectionHeader extends StatelessWidget {
  const _PetsSectionHeader({
    required this.title,
    required this.count,
  });

  final String title;
  final String count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: PawlySpacing.xs),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            count,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _PetsSearchField extends StatelessWidget {
  const _PetsSearchField({
    required this.initialValue,
    required this.onChanged,
  });

  final String initialValue;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(PawlyRadius.lg),
      ),
      child: TextFormField(
        initialValue: initialValue,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Поиск по имени',
          prefixIcon: Icon(
            Icons.search_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: PawlySpacing.md,
            vertical: PawlySpacing.md,
          ),
        ),
      ),
    );
  }
}

class _PetsSegmentOption<T> {
  const _PetsSegmentOption({
    required this.value,
    required this.label,
  });

  final T value;
  final String label;
}

class _PetsSegmentedControl<T> extends StatelessWidget {
  const _PetsSegmentedControl({
    required this.options,
    required this.value,
    required this.onChanged,
    this.compact = false,
  });

  final List<_PetsSegmentOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(PawlySpacing.xxs),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(PawlyRadius.lg),
      ),
      child: Row(
        children: options.map((option) {
          final selected = option.value == value;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.all(PawlySpacing.xxxs),
              child: _PetsSegmentButton(
                label: option.label,
                selected: selected,
                compact: compact,
                onTap: () => onChanged(option.value),
              ),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }
}

class _PetsSegmentButton extends StatelessWidget {
  const _PetsSegmentButton({
    required this.label,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final foreground =
        selected ? colorScheme.onSurface : colorScheme.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PawlyRadius.md),
        child: AnimatedContainer(
          duration: PawlyMotion.quick,
          height: compact ? 34 : 38,
          padding: const EdgeInsets.symmetric(horizontal: PawlySpacing.xs),
          decoration: BoxDecoration(
            color: selected ? colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(PawlyRadius.md),
            boxShadow: selected
                ? <BoxShadow>[
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: foreground,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PetsEmptyState extends StatelessWidget {
  const _PetsEmptyState({required this.statusBucket});

  final PetsStatusBucket statusBucket;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isArchive = statusBucket == PetsStatusBucket.archive;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        PawlySpacing.lg,
        PawlySpacing.xl,
        PawlySpacing.lg,
        PawlySpacing.xl,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(PawlyRadius.lg),
      ),
      child: Column(
        children: <Widget>[
          Icon(
            isArchive ? Icons.archive_outlined : Icons.pets_rounded,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            size: 34,
          ),
          const SizedBox(height: PawlySpacing.sm),
          Text(
            isArchive ? 'Архив пуст' : 'Питомцев пока нет',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: PawlySpacing.xs),
          Text(
            isArchive
                ? 'Заархивированные карточки появятся здесь. Их можно вернуть в активные.'
                : 'Добавьте питомца или примите приглашение по коду, чтобы увидеть карточки.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _PetsCardsLayout extends StatelessWidget {
  const _PetsCardsLayout({
    required this.items,
    required this.itemBuilder,
  });

  final List<PetListEntry> items;
  final Widget Function(PetListEntry item) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useGrid = constraints.maxWidth >= 680;
        const spacing = PawlySpacing.md;
        final cardWidth = useGrid
            ? (constraints.maxWidth - spacing) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items.map((item) {
            return SizedBox(
              width: cardWidth,
              child: itemBuilder(item),
            );
          }).toList(growable: false),
        );
      },
    );
  }
}
