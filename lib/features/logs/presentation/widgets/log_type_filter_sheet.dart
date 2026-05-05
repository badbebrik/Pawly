import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../shared/formatters/log_form_formatters.dart';
import '../../shared/utils/log_catalog_filters.dart';

class LogTypeFilterSheet extends StatefulWidget {
  const LogTypeFilterSheet({
    required this.allTypes,
    required this.initialSelectedIds,
    super.key,
  });

  final List<LogTypeFilterItem> allTypes;
  final Set<String> initialSelectedIds;

  @override
  State<LogTypeFilterSheet> createState() => _LogTypeFilterSheetState();
}

class _LogTypeFilterSheetState extends State<LogTypeFilterSheet> {
  late final TextEditingController _searchController;
  late Set<String> _selectedIds;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _selectedIds = Set<String>.from(widget.initialSelectedIds);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredTypes = filterLogTypeFilterItemsByName(
      types: widget.allTypes,
      query: _searchQuery,
    );

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: PawlySpacing.lg,
          right: PawlySpacing.lg,
          top: PawlySpacing.md,
          bottom: MediaQuery.viewInsetsOf(context).bottom + PawlySpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Фильтр по типам',
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
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: PawlySpacing.md),
            Flexible(
              child: filteredTypes.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: PawlySpacing.xl,
                        ),
                        child: Text('Типы не найдены.'),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: filteredTypes.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: PawlySpacing.xs),
                      itemBuilder: (context, index) {
                        final type = filteredTypes[index];
                        final selected = _selectedIds.contains(type.id);

                        return _TypeFilterOption(
                          title: type.name,
                          subtitle: logTypeScopeLabel(type.scope),
                          isSelected: selected,
                          onTap: () {
                            setState(() {
                              if (!selected) {
                                _selectedIds.add(type.id);
                              } else {
                                _selectedIds.remove(type.id);
                              }
                            });
                          },
                        );
                      },
                    ),
            ),
            const SizedBox(height: PawlySpacing.md),
            Row(
              children: <Widget>[
                Expanded(
                  child: PawlyButton(
                    label: 'Сбросить',
                    onPressed: () {
                      Navigator.of(context).pop(<String>{});
                    },
                    variant: PawlyButtonVariant.secondary,
                  ),
                ),
                const SizedBox(width: PawlySpacing.md),
                Expanded(
                  child: PawlyButton(
                    label: 'Применить (${_selectedIds.length})',
                    onPressed: () {
                      Navigator.of(context).pop(_selectedIds);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeFilterOption extends StatelessWidget {
  const _TypeFilterOption({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: isSelected
          ? colorScheme.primary.withValues(alpha: 0.10)
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.36),
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
                  : colorScheme.outlineVariant.withValues(alpha: 0.64),
            ),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: PawlySpacing.xxs),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: PawlySpacing.sm),
              Icon(
                isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
