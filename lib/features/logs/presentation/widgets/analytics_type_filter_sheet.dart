import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../shared/formatters/log_form_formatters.dart';
import '../../shared/utils/analytics_type_catalog.dart';

class AnalyticsTypeFilterSheet extends StatefulWidget {
  const AnalyticsTypeFilterSheet({
    required this.catalog,
    required this.selectedTypeIds,
    super.key,
  });

  final AnalyticsTypeCatalog catalog;
  final Set<String> selectedTypeIds;

  @override
  State<AnalyticsTypeFilterSheet> createState() =>
      _AnalyticsTypeFilterSheetState();
}

class _AnalyticsTypeFilterSheetState extends State<AnalyticsTypeFilterSheet> {
  late final TextEditingController _searchController;
  late final Set<String> _selectedTypeIds;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _selectedTypeIds = Set<String>.from(widget.selectedTypeIds);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredSections = widget.catalog.filter(_query);

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
              'Фильтр по типам записей',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: PawlySpacing.md),
            PawlyTextField(
              controller: _searchController,
              hintText: 'Поиск по типам',
              prefixIcon: const Icon(Icons.search_rounded),
              onChanged: (value) {
                setState(() {
                  _query = value;
                });
              },
            ),
            const SizedBox(height: PawlySpacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _selectedTypeIds.clear();
                  });
                },
                child: const Text('Снять фильтр по типам'),
              ),
            ),
            Flexible(
              child: filteredSections.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(PawlySpacing.lg),
                        child: Text('Типы записей не найдены.'),
                      ),
                    )
                  : ListView(
                      shrinkWrap: true,
                      children: filteredSections
                          .map(
                            (section) => _AnalyticsTypeSectionWidget(
                              section: section,
                              selectedTypeIds: _selectedTypeIds,
                              onToggle: _toggleType,
                            ),
                          )
                          .toList(growable: false),
                    ),
            ),
            const SizedBox(height: PawlySpacing.md),
            Row(
              children: <Widget>[
                Expanded(
                  child: PawlyButton(
                    label: 'Сбросить',
                    onPressed: () => Navigator.of(context).pop(<String>[]),
                    variant: PawlyButtonVariant.secondary,
                  ),
                ),
                const SizedBox(width: PawlySpacing.sm),
                Expanded(
                  child: PawlyButton(
                    label: 'Применить',
                    onPressed: () => Navigator.of(
                      context,
                    ).pop(_selectedTypeIds.toList(growable: false)..sort()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _toggleType(String typeId, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedTypeIds.add(typeId);
      } else {
        _selectedTypeIds.remove(typeId);
      }
    });
  }
}

class _AnalyticsTypeSectionWidget extends StatelessWidget {
  const _AnalyticsTypeSectionWidget({
    required this.section,
    required this.selectedTypeIds,
    required this.onToggle,
  });

  final AnalyticsTypeSection section;
  final Set<String> selectedTypeIds;
  final void Function(String typeId, bool isSelected) onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: PawlySpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            section.title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: PawlySpacing.xs),
          ...section.items.map(
            (type) {
              final metrics = logTypeMetricNames(type);
              return _AnalyticsTypeOption(
                isSelected: selectedTypeIds.contains(type.id),
                title: Text(type.name),
                subtitle: metrics.isEmpty ? null : Text(metrics),
                onTap: () =>
                    onToggle(type.id, !selectedTypeIds.contains(type.id)),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AnalyticsTypeOption extends StatelessWidget {
  const _AnalyticsTypeOption({
    required this.isSelected,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final bool isSelected;
  final Widget title;
  final Widget? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: PawlySpacing.xs),
      child: Material(
        color: isSelected
            ? colorScheme.primary.withValues(alpha: 0.10)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(PawlyRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(PawlyRadius.lg),
          child: Container(
            padding: const EdgeInsets.all(PawlySpacing.sm),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(PawlyRadius.lg),
              border: Border.all(
                color: isSelected
                    ? colorScheme.primary.withValues(alpha: 0.52)
                    : colorScheme.outlineVariant.withValues(alpha: 0.48),
              ),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      DefaultTextStyle.merge(
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        child: title,
                      ),
                      if (subtitle != null) ...<Widget>[
                        const SizedBox(height: PawlySpacing.xxs),
                        DefaultTextStyle.merge(
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          child: subtitle!,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: PawlySpacing.sm),
                Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
