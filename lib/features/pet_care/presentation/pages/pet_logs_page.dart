import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/design_system.dart';
import '../../../../core/network/models/log_models.dart';
import '../providers/health_controllers.dart';

class PetLogsPage extends ConsumerWidget {
  const PetLogsPage({
    required this.petId,
    super.key,
  });

  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsState = ref.watch(petLogsControllerProvider(petId));

    return Scaffold(
      appBar: AppBar(title: const Text('Записи')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await context.pushNamed<bool>(
            'petLogCreate',
            pathParameters: <String, String>{'petId': petId},
          );
          if (created == true && context.mounted) {
            await ref.read(petLogsControllerProvider(petId).notifier).reload();
          }
        },
        child: const Icon(Icons.add_rounded),
      ),
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
          onLoadMore: () =>
              ref.read(petLogsControllerProvider(petId).notifier).loadMore(),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _LogsErrorView(
          onRetry: () =>
              ref.read(petLogsControllerProvider(petId).notifier).reload(),
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
    final selectedTypes = allTypes
        .where((type) => state.selectedTypeIds.contains(type.id))
        .toList(growable: false);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(PawlySpacing.lg),
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
              FilterChip(
                label: const Text('Все источники'),
                selected: state.selectedSource == null,
                onSelected: (_) => onSetSource(null),
              ),
              for (final source in facets?.sources ?? const <LogSourceFacet>[])
                FilterChip(
                  label: Text(_sourceLabel(source.value)),
                  selected: state.selectedSource == source.value,
                  onSelected: (_) => onSetSource(
                    state.selectedSource == source.value ? null : source.value,
                  ),
                ),
              FilterChip(
                label: Text(
                  state.selectedTypeIds.isEmpty
                      ? 'Типы'
                      : 'Типы (${state.selectedTypeIds.length})',
                ),
                selected: state.selectedTypeIds.isNotEmpty,
                onSelected: (_) => _openTypeFilterSheet(context),
              ),
              FilterChip(
                label: const Text('С файлами'),
                selected: state.withAttachmentsOnly,
                onSelected: onSetWithAttachmentsOnly,
              ),
              FilterChip(
                label: const Text('С метриками'),
                selected: state.withMetricsOnly,
                onSelected: onSetWithMetricsOnly,
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
                  InputChip(
                    label: Text(type.name),
                    onDeleted: () => onToggleType(type.id),
                  ),
              ],
            ),
          ],
          const SizedBox(height: PawlySpacing.lg),
          if (state.logs.isEmpty)
            const PawlyCard(
              child: Text('По выбранным фильтрам записей пока нет.'),
            )
          else
            ...state.logs.map(
              (log) => _LogCardItem(
                log: log,
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
    required this.onTap,
  });

  final LogCard log;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: PawlySpacing.md),
      child: PawlyCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        log.logTypeName ?? 'Запись без типа',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: PawlySpacing.xxs),
                      Text(
                        _formatOccurredAt(log.occurredAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                PawlyBadge(
                  label: _sourceLabel(log.source),
                  tone: log.source == 'HEALTH'
                      ? PawlyBadgeTone.info
                      : PawlyBadgeTone.neutral,
                ),
              ],
            ),
            if (log.descriptionPreview.isNotEmpty) ...<Widget>[
              const SizedBox(height: PawlySpacing.sm),
              Text(
                log.descriptionPreview,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (_relatedEntityLabel(log) case final relatedLabel?) ...<Widget>[
              const SizedBox(height: PawlySpacing.xs),
              Text(
                relatedLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: PawlySpacing.sm),
            Wrap(
              spacing: PawlySpacing.xs,
              runSpacing: PawlySpacing.xs,
              children: <Widget>[
                if (log.metricValuesPreview.isNotEmpty)
                  for (final metric in log.metricValuesPreview.take(3))
                    PawlyBadge(
                      label:
                          '${metric.metricName} ${_formatMetricValue(metric)}',
                    ),
                if (log.hasAttachments)
                  PawlyBadge(
                    label: 'Вложений: ${log.attachmentsCount}',
                    tone: PawlyBadgeTone.warning,
                  ),
              ],
            ),
          ],
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PawlySpacing.lg),
        child: PawlyCard(
          title: const Text('Не удалось загрузить записи.'),
          footer: PawlyButton(
            label: 'Повторить',
            onPressed: onRetry,
            variant: PawlyButtonVariant.secondary,
          ),
          child: const SizedBox.shrink(),
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
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
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
                        padding:
                            EdgeInsets.symmetric(vertical: PawlySpacing.xl),
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

                        return CheckboxListTile(
                          value: selected,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.trailing,
                          onChanged: (value) {
                            setState(() {
                              if (value ?? false) {
                                _selectedIds.add(type.id);
                              } else {
                                _selectedIds.remove(type.id);
                              }
                            });
                          },
                          title: Text(type.name),
                          subtitle: Text(
                            type.scope == 'SYSTEM' ? 'Системный' : 'Мой',
                          ),
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
  return value.unitCode == null || value.unitCode!.isEmpty
      ? number
      : '$number ${value.unitCode}';
}

String? _relatedEntityLabel(LogCard log) {
  final relatedType = log.sourceEntityType;
  if (relatedType == null || relatedType.isEmpty) {
    return null;
  }

  return switch (relatedType) {
    'VACCINATION' => 'Автолог вакцинации',
    'PROCEDURE' => 'Автолог процедуры',
    'VET_VISIT' => 'Связано с визитом',
    _ => 'Связано: $relatedType',
  };
}
