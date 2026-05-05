import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../states/documents_state.dart';

class DocumentsFilterSection extends StatelessWidget {
  const DocumentsFilterSection({
    required this.searchController,
    required this.selectedEntityFilter,
    required this.selectedKindFilter,
    required this.onSearchChanged,
    required this.onEntityFilterChanged,
    required this.onKindFilterChanged,
    super.key,
  });

  final TextEditingController searchController;
  final DocumentsEntityFilter selectedEntityFilter;
  final DocumentsKindFilter selectedKindFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<DocumentsEntityFilter> onEntityFilterChanged;
  final ValueChanged<DocumentsKindFilter> onKindFilterChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        PawlyTextField(
          controller: searchController,
          label: 'Поиск',
          hintText: 'Название файла',
          textInputAction: TextInputAction.search,
          prefixIcon: const Icon(Icons.search_rounded),
          onChanged: onSearchChanged,
        ),
        const SizedBox(height: PawlySpacing.md),
        Text(
          'Тип файла',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: PawlySpacing.xs),
        _HorizontalFilterList<DocumentsKindFilter>(
          values: DocumentsKindFilter.values,
          selectedValue: selectedKindFilter,
          labelBuilder: (filter) => filter.label,
          onChanged: onKindFilterChanged,
        ),
        const SizedBox(height: PawlySpacing.sm),
        Text(
          'Источник',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: PawlySpacing.xs),
        _HorizontalFilterList<DocumentsEntityFilter>(
          values: DocumentsEntityFilter.values,
          selectedValue: selectedEntityFilter,
          labelBuilder: (filter) => filter.label,
          onChanged: onEntityFilterChanged,
        ),
      ],
    );
  }
}

class _HorizontalFilterList<T> extends StatelessWidget {
  const _HorizontalFilterList({
    required this.values,
    required this.selectedValue,
    required this.labelBuilder,
    required this.onChanged,
  });

  final List<T> values;
  final T selectedValue;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: List<Widget>.generate(values.length, (index) {
          final value = values[index];
          return Padding(
            padding: EdgeInsets.only(
              right: index == values.length - 1 ? 0 : PawlySpacing.xs,
            ),
            child: _DocumentFilterPill(
              label: labelBuilder(value),
              isSelected: value == selectedValue,
              onTap: () => onChanged(value),
            ),
          );
        }),
      ),
    );
  }
}

class _DocumentFilterPill extends StatelessWidget {
  const _DocumentFilterPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(PawlyRadius.pill),
      child: Ink(
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : colorScheme.surface,
          borderRadius: BorderRadius.circular(PawlyRadius.pill),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant.withValues(alpha: 0.72),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: PawlySpacing.md,
          vertical: PawlySpacing.xs,
        ),
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
