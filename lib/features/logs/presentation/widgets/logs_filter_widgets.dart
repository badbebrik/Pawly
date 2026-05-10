import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../models/log_models.dart';
import '../../shared/formatters/log_display_formatters.dart';
import '../../shared/utils/log_catalog_filters.dart';
import '../../states/logs_state.dart';
import 'log_type_filter_sheet.dart';

class LogsFilters extends StatelessWidget {
  const LogsFilters({
    required this.state,
    required this.onSearchChanged,
    required this.onToggleType,
    required this.onApplyTypeFilters,
    required this.onSetSource,
    required this.onSetWithAttachmentsOnly,
    required this.onSetWithMetricsOnly,
    super.key,
  });

  final PetLogsState state;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onToggleType;
  final ValueChanged<Set<String>> onApplyTypeFilters;
  final ValueChanged<String?> onSetSource;
  final ValueChanged<bool> onSetWithAttachmentsOnly;
  final ValueChanged<bool> onSetWithMetricsOnly;

  @override
  Widget build(BuildContext context) {
    final facets = state.facets;
    final allTypes = buildLogTypeFilterItems(
      bootstrap: state.bootstrap,
      facets: facets,
    );
    final selectedTypes = allTypes
        .where((type) => state.selectedTypeIds.contains(type.id))
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        PawlyTextField(
          hintText: 'Поиск по названию и описанию',
          prefixIcon: const Icon(Icons.search_rounded),
          onChanged: onSearchChanged,
        ),
        const SizedBox(height: PawlySpacing.md),
        Wrap(
          spacing: PawlySpacing.xs,
          runSpacing: PawlySpacing.xs,
          children: <Widget>[
            _LogsFilterPill(
              label: 'Все источники',
              isSelected: state.selectedSource == null,
              onTap: () => onSetSource(null),
            ),
            for (final source
                in facets?.sources ?? const <LogSourceFacetItem>[])
              _LogsFilterPill(
                label: logSourceLabel(source.value),
                isSelected: state.selectedSource == source.value,
                onTap: () => onSetSource(
                  state.selectedSource == source.value ? null : source.value,
                ),
              ),
            _LogsFilterPill(
              label: state.selectedTypeIds.isEmpty
                  ? 'Типы'
                  : 'Типы (${state.selectedTypeIds.length})',
              isSelected: state.selectedTypeIds.isNotEmpty,
              onTap: () => _openTypeFilterSheet(context),
            ),
            _LogsFilterPill(
              label: 'С файлами',
              isSelected: state.withAttachmentsOnly,
              onTap: () => onSetWithAttachmentsOnly(!state.withAttachmentsOnly),
            ),
            _LogsFilterPill(
              label: 'С показателями',
              isSelected: state.withMetricsOnly,
              onTap: () => onSetWithMetricsOnly(!state.withMetricsOnly),
            ),
          ],
        ),
        if (selectedTypes.isNotEmpty) ...<Widget>[
          const SizedBox(height: PawlySpacing.md),
          Wrap(
            spacing: PawlySpacing.xs,
            runSpacing: PawlySpacing.xs,
            children: <Widget>[
              for (final type in selectedTypes)
                _LogsSelectedToken(
                  label: type.name,
                  onDelete: () => onToggleType(type.id),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _openTypeFilterSheet(BuildContext context) async {
    final selectedTypeIds = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return LogTypeFilterSheet(
          allTypes: buildLogTypeFilterItems(
            bootstrap: state.bootstrap,
            facets: state.facets,
          ),
          initialSelectedIds: state.selectedTypeIds,
        );
      },
    );

    if (!context.mounted || selectedTypeIds == null) {
      return;
    }
    onApplyTypeFilters(selectedTypeIds);
  }
}

class _LogsFilterPill extends StatelessWidget {
  const _LogsFilterPill({
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

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.48),
          borderRadius: BorderRadius.circular(PawlyRadius.pill),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant.withValues(alpha: 0.84),
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

class _LogsSelectedToken extends StatelessWidget {
  const _LogsSelectedToken({required this.label, required this.onDelete});

  final String label;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(PawlyRadius.pill),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.72),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(
          left: PawlySpacing.sm,
          right: PawlySpacing.xxs,
          top: PawlySpacing.xxs,
          bottom: PawlySpacing.xxs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: PawlySpacing.xxs),
            GestureDetector(
              onTap: onDelete,
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
