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
  final ValueChanged<String?> onSetSource;
  final ValueChanged<bool> onSetWithAttachmentsOnly;
  final ValueChanged<bool> onSetWithMetricsOnly;
  final Future<void> Function() onLoadMore;

  @override
  Widget build(BuildContext context) {
    final facets = state.facets;
    final typeFacets = facets?.types.take(6).toList(growable: false) ?? const [];

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
          if (typeFacets.isNotEmpty) ...<Widget>[
            const SizedBox(height: PawlySpacing.md),
            Text(
              'Типы',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: PawlySpacing.xs),
            Wrap(
              spacing: PawlySpacing.xs,
              runSpacing: PawlySpacing.xs,
              children: <Widget>[
                for (final type in typeFacets)
                  FilterChip(
                    label: Text(type.name),
                    selected: state.selectedTypeIds.contains(type.id),
                    onSelected: (_) => onToggleType(type.id),
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
            const SizedBox(height: PawlySpacing.sm),
            Wrap(
              spacing: PawlySpacing.xs,
              runSpacing: PawlySpacing.xs,
              children: <Widget>[
                if (log.metricValuesPreview.isNotEmpty)
                  for (final metric in log.metricValuesPreview.take(3))
                    PawlyBadge(
                      label: '${metric.metricName} ${_formatMetricValue(metric)}',
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

  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$day.$month.${value.year} $hour:$minute';
}

String _formatMetricValue(LogMetricValue value) {
  final number = value.valueNum % 1 == 0
      ? value.valueNum.toStringAsFixed(0)
      : value.valueNum.toStringAsFixed(1);
  return value.unitCode == null || value.unitCode!.isEmpty
      ? number
      : '$number ${value.unitCode}';
}
