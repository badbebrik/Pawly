import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/design_system.dart';
import '../../../../core/network/models/log_models.dart';
import '../../../pets/presentation/providers/pets_controller.dart';
import '../providers/health_controllers.dart';
import '../utils/metric_unit_formatter.dart';

class PetLogsPage extends ConsumerWidget {
  const PetLogsPage({required this.petId, super.key});

  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessAsync = ref.watch(petAccessPolicyProvider(petId));

    return accessAsync.when(
      data: (access) {
        if (!access.logRead) {
          return const PawlyScreenScaffold(
            title: 'Записи',
            body: _LogsNoAccessView(),
          );
        }

        final logsState = ref.watch(petLogsControllerProvider(petId));
        return PawlyScreenScaffold(
          title: 'Записи',
          floatingActionButton: access.logWrite
              ? PawlyAddActionButton(
                  label: 'Добавить',
                  tooltip: 'Добавить запись',
                  onTap: () async {
                    final created = await context.pushNamed<bool>(
                      'petLogCreate',
                      pathParameters: <String, String>{'petId': petId},
                    );
                    if (created == true && context.mounted) {
                      await ref
                          .read(petLogsControllerProvider(petId).notifier)
                          .reload();
                    }
                  },
                )
              : null,
          body: logsState.when(
            data: (state) => _PetLogsView(
              petId: petId,
              state: state,
              onRefresh: () =>
                  ref.read(petLogsControllerProvider(petId).notifier).reload(),
              onSearchChanged: (value) => ref
                  .read(petLogsControllerProvider(petId).notifier)
                  .setSearchQuery(value),
              onToggleType: (typeId) => ref
                  .read(petLogsControllerProvider(petId).notifier)
                  .toggleTypeFilter(typeId),
              onApplyTypeFilters: (typeIds) => ref
                  .read(petLogsControllerProvider(petId).notifier)
                  .setTypeFilters(typeIds),
              onSetSource: (source) => ref
                  .read(petLogsControllerProvider(petId).notifier)
                  .setSourceFilter(source),
              onSetWithAttachmentsOnly: (value) => ref
                  .read(petLogsControllerProvider(petId).notifier)
                  .setWithAttachmentsOnly(value),
              onSetWithMetricsOnly: (value) => ref
                  .read(petLogsControllerProvider(petId).notifier)
                  .setWithMetricsOnly(value),
              onLoadMore: () => ref
                  .read(petLogsControllerProvider(petId).notifier)
                  .loadMore(),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _LogsErrorView(
              onRetry: () =>
                  ref.read(petLogsControllerProvider(petId).notifier).reload(),
            ),
          ),
        );
      },
      loading: () => const PawlyScreenScaffold(
        title: 'Записи',
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => PawlyScreenScaffold(
        title: 'Записи',
        body: _LogsErrorView(
          onRetry: () => ref.invalidate(petAccessPolicyProvider(petId)),
        ),
      ),
    );
  }
}

class _PetLogsView extends StatelessWidget {
  const _PetLogsView({
    required this.petId,
    required this.state,
    required this.onRefresh,
    required this.onSearchChanged,
    required this.onToggleType,
    required this.onApplyTypeFilters,
    required this.onSetSource,
    required this.onSetWithAttachmentsOnly,
    required this.onSetWithMetricsOnly,
    required this.onLoadMore,
  });

  final String petId;
  final PetLogsState state;
  final Future<void> Function() onRefresh;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onToggleType;
  final ValueChanged<Set<String>> onApplyTypeFilters;
  final ValueChanged<String?> onSetSource;
  final ValueChanged<bool> onSetWithAttachmentsOnly;
  final ValueChanged<bool> onSetWithMetricsOnly;
  final Future<void> Function() onLoadMore;

  @override
  Widget build(BuildContext context) {
    final facets = state.facets;
    final allTypes = _allFilterTypes(state);
    final logTypeCodesById = <String, String?>{
      for (final type in <LogType>[
        ...state.bootstrap.systemLogTypes,
        ...state.bootstrap.recentLogTypes,
        ...state.bootstrap.customLogTypes,
      ])
        type.id: type.code,
    };
    final selectedTypes = allTypes
        .where((type) => state.selectedTypeIds.contains(type.id))
        .toList(growable: false);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          PawlySpacing.md,
          PawlySpacing.sm,
          PawlySpacing.md,
          PawlySpacing.xl,
        ),
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
              for (final source in facets?.sources ?? const <LogSourceFacet>[])
                _LogsFilterPill(
                  label: _sourceLabel(source.value),
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
                onTap: () =>
                    onSetWithAttachmentsOnly(!state.withAttachmentsOnly),
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
          const SizedBox(height: PawlySpacing.md),
          if (state.logs.isEmpty)
            const _LogsInlineMessage(
              title: 'Записей нет',
              message: 'По выбранным фильтрам записей пока нет.',
            )
          else
            ...state.logs.map(
              (log) => _LogCardItem(
                log: log,
                logTypeCode: log.logTypeId == null
                    ? null
                    : logTypeCodesById[log.logTypeId!],
                onTap: () async {
                  final changed = await context.pushNamed<bool>(
                    'petLogDetails',
                    pathParameters: <String, String>{
                      'petId': petId,
                      'logId': log.id,
                    },
                  );
                  if (changed == true && context.mounted) {
                    await onRefresh();
                  }
                },
              ),
            ),
          if (state.nextCursor != null) ...<Widget>[
            const SizedBox(height: PawlySpacing.md),
            PawlyButton(
              label: state.isLoadingMore ? 'Загрузка...' : 'Загрузить еще',
              onPressed: state.isLoadingMore ? null : onLoadMore,
              variant: PawlyButtonVariant.secondary,
            ),
          ],
        ],
      ),
    );
  }

  List<_TypeFilterItem> _allFilterTypes(PetLogsState state) {
    final result = <_TypeFilterItem>[];
    final seenIds = <String>{};

    void addType({
      required String id,
      required String name,
      required String scope,
    }) {
      if (!seenIds.add(id)) {
        return;
      }
      result.add(_TypeFilterItem(id: id, name: name, scope: scope));
    }

    for (final type in state.bootstrap.systemLogTypes) {
      addType(id: type.id, name: type.name, scope: type.scope);
    }
    for (final type in state.bootstrap.customLogTypes) {
      addType(id: type.id, name: type.name, scope: type.scope);
    }
    for (final type in state.facets?.types ?? const <LogTypeFacet>[]) {
      addType(id: type.id, name: type.name, scope: type.scope);
    }

    return result;
  }

  Future<void> _openTypeFilterSheet(BuildContext context) async {
    final selectedTypeIds = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return _TypeFilterSheet(
          allTypes: _allFilterTypes(state),
          initialSelectedIds: state.selectedTypeIds,
        );
      },
    );

    if (selectedTypeIds == null) {
      return;
    }
    onApplyTypeFilters(selectedTypeIds);
  }
}

class _LogCardItem extends StatelessWidget {
  const _LogCardItem({
    required this.log,
    required this.logTypeCode,
    required this.onTap,
  });

  final LogCard log;
  final String? logTypeCode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final emoji = _logTypeEmoji(
      code: logTypeCode,
      name: log.logTypeName,
      metricNames: log.metricValuesPreview.map((item) => item.metricName),
    );
    final singleMetric = log.metricValuesPreview.length == 1
        ? log.metricValuesPreview.single
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: PawlySpacing.sm),
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(PawlyRadius.xl),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(PawlyRadius.xl),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(PawlyRadius.xl),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.72),
              ),
            ),
            padding: const EdgeInsets.all(PawlySpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  width: 52,
                  height: 52,
                  child: Center(
                    child: Text(emoji, style: theme.textTheme.headlineMedium),
                  ),
                ),
                const SizedBox(width: PawlySpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        log.logTypeName ?? 'Запись без типа',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: PawlySpacing.xxs),
                      Text(
                        _formatOccurredAt(log.occurredAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (singleMetric != null) ...<Widget>[
                        const SizedBox(height: PawlySpacing.sm),
                        Text(
                          '${singleMetric.metricName}: ${_formatMetricValue(singleMetric)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                      if (log.descriptionPreview.isNotEmpty) ...<Widget>[
                        const SizedBox(height: PawlySpacing.sm),
                        Text(
                          log.descriptionPreview,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                      if (_relatedEntityLabel(log)
                          case final relatedLabel?) ...<Widget>[
                        const SizedBox(height: PawlySpacing.xs),
                        Text(
                          relatedLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (log.hasAttachments) ...<Widget>[
                        const SizedBox(height: PawlySpacing.sm),
                        Wrap(
                          spacing: PawlySpacing.xs,
                          runSpacing: PawlySpacing.xs,
                          children: <Widget>[
                            _LogMetaToken(
                              label: 'Вложений: ${log.attachmentsCount}',
                              icon: Icons.attach_file_rounded,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: PawlySpacing.sm),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
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

class _LogMetaToken extends StatelessWidget {
  const _LogMetaToken({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(PawlyRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: PawlySpacing.sm,
          vertical: PawlySpacing.xxs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: PawlySpacing.xxs),
            ],
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogsInlineMessage extends StatelessWidget {
  const _LogsInlineMessage({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(PawlyRadius.xl),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.72),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(PawlySpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: PawlySpacing.xs),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogsNoAccessView extends StatelessWidget {
  const _LogsNoAccessView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(PawlySpacing.md),
        child: _LogsInlineMessage(
          title: 'Нет доступа',
          message: 'У вас нет права просмотра записей этого питомца.',
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

class _LogsErrorView extends StatelessWidget {
  const _LogsErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PawlySpacing.md),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(PawlyRadius.xl),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.72),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(PawlySpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Не удалось загрузить записи',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: PawlySpacing.xs),
                Text(
                  'Попробуйте обновить журнал через несколько секунд.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: PawlySpacing.md),
                PawlyButton(
                  label: 'Повторить',
                  onPressed: onRetry,
                  variant: PawlyButtonVariant.secondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeFilterItem {
  const _TypeFilterItem({
    required this.id,
    required this.name,
    required this.scope,
  });

  final String id;
  final String name;
  final String scope;
}

class _TypeFilterSheet extends StatefulWidget {
  const _TypeFilterSheet({
    required this.allTypes,
    required this.initialSelectedIds,
  });

  final List<_TypeFilterItem> allTypes;
  final Set<String> initialSelectedIds;

  @override
  State<_TypeFilterSheet> createState() => _TypeFilterSheetState();
}

class _TypeFilterSheetState extends State<_TypeFilterSheet> {
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
    final filteredTypes = widget.allTypes.where((type) {
      final query = _searchQuery.trim().toLowerCase();
      if (query.isEmpty) {
        return true;
      }
      return type.name.toLowerCase().contains(query);
    }).toList(growable: false);

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
                          subtitle:
                              type.scope == 'SYSTEM' ? 'Системный' : 'Мой',
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

String _sourceLabel(String source) {
  switch (source) {
    case 'HEALTH':
      return 'Из здоровья';
    case 'USER':
      return 'Пользовательская';
    default:
      return source;
  }
}

String _formatOccurredAt(DateTime? value) {
  if (value == null) {
    return 'Дата не указана';
  }

  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day.$month.${local.year} $hour:$minute';
}

String _formatMetricValue(LogMetricValue value) {
  if (value.inputKind == 'BOOLEAN') {
    return value.valueNum == 0 ? 'Нет' : 'Да';
  }
  final number = value.valueNum % 1 == 0
      ? value.valueNum.toStringAsFixed(0)
      : value.valueNum.toStringAsFixed(1);
  final unit = formatDisplayUnitCode(value.unitCode);
  return unit.isEmpty ? number : '$number $unit';
}

String? _relatedEntityLabel(LogCard log) {
  final relatedType = log.sourceEntityType;
  if (relatedType == null || relatedType.isEmpty) {
    return null;
  }

  return switch (relatedType) {
    'VACCINATION' => 'Автоматическая запись вакцинации',
    'PROCEDURE' => 'Автоматическая запись процедуры',
    'VET_VISIT' => 'Связано с визитом',
    _ => 'Связано: $relatedType',
  };
}

String _logTypeEmoji({
  required String? code,
  required String? name,
  required Iterable<String> metricNames,
}) {
  final normalizedCode =
      code?.trim().toUpperCase() ?? _inferLogTypeCode(name, metricNames);

  return switch (normalizedCode) {
    'WEIGHING' => '⚖️',
    'WEIGHT' => '⚖️',
    'TEMPERATURE' => '🌡️',
    'APPETITE' => '🍽️',
    'WATER_INTAKE' => '💧',
    'ACTIVITY' => '🏃',
    'SLEEP' => '😴',
    'STOOL' => '💩',
    'URINATION' => '🚽',
    'VOMITING' => '🤮',
    'COUGHING' => '😮‍💨',
    'ITCHING' => '🐾',
    'PAIN_EPISODE' => '⚠️',
    'SEIZURE_EPISODE' => '⚡',
    'MEDICATION' => '💊',
    'RESPIRATORY_SYMPTOMS' => '🫁',
    _ => '📝',
  };
}

String _inferLogTypeCode(String? name, Iterable<String> metricNames) {
  final haystack = <String>[
    if (name != null) name,
    ...metricNames,
  ].join(' ').toLowerCase();

  if (haystack.contains('вес')) {
    return 'WEIGHT';
  }
  if (haystack.contains('температур')) {
    return 'TEMPERATURE';
  }
  if (haystack.contains('аппетит')) {
    return 'APPETITE';
  }
  if (haystack.contains('пить') || haystack.contains('вода')) {
    return 'WATER_INTAKE';
  }
  if (haystack.contains('активност')) {
    return 'ACTIVITY';
  }
  if (haystack.contains('сон')) {
    return 'SLEEP';
  }
  if (haystack.contains('стул')) {
    return 'STOOL';
  }
  if (haystack.contains('моч')) {
    return 'URINATION';
  }
  if (haystack.contains('рвот')) {
    return 'VOMITING';
  }
  if (haystack.contains('дых') ||
      haystack.contains('каш') ||
      haystack.contains('чих')) {
    return 'RESPIRATORY_SYMPTOMS';
  }
  if (haystack.contains('зуд')) {
    return 'ITCHING';
  }
  if (haystack.contains('бол')) {
    return 'PAIN_EPISODE';
  }
  if (haystack.contains('судорог')) {
    return 'SEIZURE_EPISODE';
  }
  if (haystack.contains('лекар')) {
    return 'MEDICATION';
  }

  return '';
}
