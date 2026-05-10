import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../shared/formatters/analytics_formatters.dart';
import '../../shared/utils/analytics_type_catalog.dart';
import '../../states/analytics_filter_state.dart';
import 'analytics_type_filter_sheet.dart';

class AnalyticsFiltersSheet extends StatefulWidget {
  const AnalyticsFiltersSheet({
    required this.initialState,
    required this.typeCatalog,
    super.key,
  });

  final AnalyticsFilterState initialState;
  final AnalyticsTypeCatalog typeCatalog;

  @override
  State<AnalyticsFiltersSheet> createState() => _AnalyticsFiltersSheetState();
}

class _AnalyticsFiltersSheetState extends State<AnalyticsFiltersSheet> {
  late String _range;
  late DateTimeRange? _customDateRange;
  late String? _dateFrom;
  late String? _dateTo;
  late Set<String> _selectedTypeIds;

  @override
  void initState() {
    super.initState();
    _range = widget.initialState.range;
    _customDateRange = widget.initialState.customDateRange;
    _dateFrom = widget.initialState.dateFrom;
    _dateTo = widget.initialState.dateTo;
    _selectedTypeIds = Set<String>.from(widget.initialState.selectedTypeIds);
  }

  @override
  Widget build(BuildContext context) {
    final selectedTypes = widget.typeCatalog.resolveSelected(_selectedTypeIds);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: PawlySpacing.lg,
          right: PawlySpacing.lg,
          top: PawlySpacing.md,
          bottom: PawlySpacing.lg + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Фильтры динамики',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: PawlySpacing.md),
            Text(
              'Период',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: PawlySpacing.sm),
            Wrap(
              spacing: PawlySpacing.xs,
              runSpacing: PawlySpacing.xs,
              children: <Widget>[
                for (final item in const <String>['7d', '30d', '90d', 'all'])
                  _AnalyticsRangePill(
                    label: Text(analyticsRangeLabel(item)),
                    isSelected: _range == item,
                    onTap: () => _setPresetRange(item),
                  ),
                _AnalyticsRangePill(
                  label: Text(
                    _range == 'custom' && _customDateRange != null
                        ? formatAnalyticsDateRange(_customDateRange!)
                        : 'Свои даты',
                  ),
                  isSelected: _range == 'custom',
                  onTap: _pickCustomRange,
                ),
              ],
            ),
            const SizedBox(height: PawlySpacing.lg),
            Text(
              'Типы записей',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: PawlySpacing.sm),
            OutlinedButton.icon(
              onPressed: widget.typeCatalog.isEmpty ? null : _pickTypes,
              icon: const Icon(Icons.tune_rounded),
              label: Text(_selectedTypesSheetLabel(widget.typeCatalog)),
            ),
            if (selectedTypes.isNotEmpty) ...<Widget>[
              const SizedBox(height: PawlySpacing.sm),
              Wrap(
                spacing: PawlySpacing.xs,
                runSpacing: PawlySpacing.xs,
                children: selectedTypes
                    .map(
                      (type) => _SelectedTypeToken(
                        label: Text(type.name),
                        onDelete: () {
                          setState(() {
                            _selectedTypeIds.remove(type.id);
                          });
                        },
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
            const SizedBox(height: PawlySpacing.lg),
            Row(
              children: <Widget>[
                Expanded(
                  child: PawlyButton(
                    label: 'Сбросить',
                    onPressed: _resetFilters,
                    variant: PawlyButtonVariant.secondary,
                  ),
                ),
                const SizedBox(width: PawlySpacing.sm),
                Expanded(
                  child: PawlyButton(
                    label: 'Применить',
                    onPressed: () => Navigator.of(context).pop(
                      AnalyticsFilterState(
                        range: _range,
                        customDateRange: _customDateRange,
                        dateFrom: _dateFrom,
                        dateTo: _dateTo,
                        selectedTypeIds: _selectedTypeIds,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _setPresetRange(String range) {
    final resolvedRange = resolveAnalyticsPresetRange(range);
    setState(() {
      _range = range;
      _customDateRange = null;
      _dateFrom = resolvedRange.dateFrom;
      _dateTo = resolvedRange.dateTo;
    });
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final initialRange = _customDateRange ??
        DateTimeRange(start: now.subtract(const Duration(days: 29)), end: now);
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: initialRange,
      helpText: 'Выберите период',
      saveText: 'Применить',
      cancelText: 'Отмена',
    );
    if (!mounted || pickedRange == null) {
      return;
    }

    final normalizedRange = DateTimeRange(
      start: DateTime(
        pickedRange.start.year,
        pickedRange.start.month,
        pickedRange.start.day,
      ),
      end: DateTime(
        pickedRange.end.year,
        pickedRange.end.month,
        pickedRange.end.day,
      ),
    );

    setState(() {
      _range = 'custom';
      _customDateRange = normalizedRange;
      _dateFrom = startOfDayUtcIso(normalizedRange.start);
      _dateTo = endOfDayUtcIso(normalizedRange.end);
    });
  }

  Future<void> _pickTypes() async {
    final selectedIds = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => AnalyticsTypeFilterSheet(
        catalog: widget.typeCatalog,
        selectedTypeIds: _selectedTypeIds,
      ),
    );
    if (!mounted || selectedIds == null) {
      return;
    }

    setState(() {
      _selectedTypeIds = selectedIds.toSet();
    });
  }

  void _resetFilters() {
    final resolvedRange = resolveAnalyticsPresetRange('30d');
    setState(() {
      _range = '30d';
      _customDateRange = null;
      _dateFrom = resolvedRange.dateFrom;
      _dateTo = resolvedRange.dateTo;
      _selectedTypeIds.clear();
    });
  }

  String _selectedTypesSheetLabel(AnalyticsTypeCatalog catalog) {
    final selectedTypes = catalog.resolveSelected(_selectedTypeIds);
    if (selectedTypes.isEmpty) {
      return 'Все типы записей';
    }
    if (selectedTypes.length == 1) {
      return selectedTypes.first.name;
    }
    return '${selectedTypes.length} выбрано';
  }
}

class _AnalyticsRangePill extends StatelessWidget {
  const _AnalyticsRangePill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final Widget label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
        child: DefaultTextStyle.merge(
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color:
                    isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
          child: label,
        ),
      ),
    );
  }
}

class _SelectedTypeToken extends StatelessWidget {
  const _SelectedTypeToken({required this.label, required this.onDelete});

  final Widget label;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
            DefaultTextStyle.merge(
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
              child: label,
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
