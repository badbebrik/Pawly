import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/models/log_models.dart';
import '../../../../design_system/design_system.dart';
import '../providers/health_controllers.dart';

class PetLogDetailsPage extends ConsumerWidget {
  const PetLogDetailsPage({
    required this.petId,
    required this.logId,
    super.key,
  });

  final String petId;
  final String logId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logRef = PetLogRef(petId: petId, logId: logId);
    final logAsync = ref.watch(
      petLogDetailsControllerProvider(logRef),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Запись'),
        actions: logAsync.maybeWhen(
          data: (log) => <Widget>[
            if (log.canEdit)
              IconButton(
                onPressed: () async {
                  final updated = await context.pushNamed<bool>(
                    'petLogEdit',
                    pathParameters: <String, String>{
                      'petId': petId,
                      'logId': logId,
                    },
                  );
                  if (updated == true && context.mounted) {
                    await ref
                        .read(petLogDetailsControllerProvider(logRef).notifier)
                        .reload();
                  }
                },
                icon: const Icon(Icons.edit_rounded),
                tooltip: 'Редактировать',
              ),
            if (log.canDelete)
              IconButton(
                onPressed: () => _deleteLog(context, ref, log),
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: 'Удалить',
              ),
          ],
          orElse: () => const <Widget>[],
        ),
      ),
      body: logAsync.when(
        data: (log) => _PetLogDetailsView(
          log: log,
          onRefresh: () => ref
              .read(petLogDetailsControllerProvider(logRef).notifier)
              .reload(),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _LogDetailsErrorView(
          onRetry: () => ref
              .read(petLogDetailsControllerProvider(logRef).notifier)
              .reload(),
        ),
      ),
    );
  }

  Future<void> _deleteLog(
    BuildContext context,
    WidgetRef ref,
    LogEntry log,
  ) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Удалить запись?'),
              content: const Text(
                'Запись будет удалена из ленты питомца. Это действие нельзя отменить.',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Отмена'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Удалить'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed || !context.mounted) {
      return;
    }

    try {
      await ref.read(healthRepositoryProvider).deleteLog(
            petId,
            logId,
            rowVersion: log.rowVersion,
          );
      ref.invalidate(petLogsControllerProvider(petId));
      ref.invalidate(petLogDetailsControllerProvider(PetLogRef(
        petId: petId,
        logId: logId,
      )));
      if (!context.mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is StateError
                ? error.message.toString()
                : 'Не удалось удалить запись.',
          ),
        ),
      );
    }
  }
}

class _PetLogDetailsView extends StatelessWidget {
  const _PetLogDetailsView({
    required this.log,
    required this.onRefresh,
  });

  final LogEntry log;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final canMutate = log.canEdit || log.canDelete;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(PawlySpacing.lg),
        children: <Widget>[
          PawlyCard(
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
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: PawlySpacing.xxs),
                          Text(
                            _formatOccurredAt(log.occurredAt),
                            style: Theme.of(context).textTheme.bodyMedium,
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
                if (log.sourceLabel != null && log.sourceLabel!.isNotEmpty) ...[
                  const SizedBox(height: PawlySpacing.sm),
                  Text(
                    log.sourceLabel!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (!canMutate) ...<Widget>[
                  const SizedBox(height: PawlySpacing.md),
                  const PawlyBadge(
                    label: 'Редактирование недоступно',
                    tone: PawlyBadgeTone.warning,
                  ),
                ],
              ],
            ),
          ),
          if (log.description.isNotEmpty) ...<Widget>[
            const SizedBox(height: PawlySpacing.md),
            PawlyCard(
              title: Text(
                'Описание',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              child: Text(log.description),
            ),
          ],
          if (log.metricValues.isNotEmpty) ...<Widget>[
            const SizedBox(height: PawlySpacing.md),
            PawlyCard(
              title: Text(
                'Метрики',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              child: Column(
                children: log.metricValues
                    .map(
                      (metric) => Padding(
                        padding: const EdgeInsets.only(bottom: PawlySpacing.sm),
                        child: Row(
                          children: <Widget>[
                            Expanded(child: Text(metric.metricName)),
                            Text(
                              _formatMetricValue(metric),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ],
          if (log.attachments.isNotEmpty) ...<Widget>[
            const SizedBox(height: PawlySpacing.md),
            PawlyCard(
              title: Text(
                'Вложения',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              child: Column(
                children: log.attachments
                    .map(
                      (attachment) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          attachment.fileType.startsWith('image/')
                              ? Icons.photo_rounded
                              : Icons.description_rounded,
                        ),
                        title: Text(attachment.fileName),
                        subtitle: Text(_attachmentSubtitle(attachment)),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ],
          const SizedBox(height: PawlySpacing.md),
          PawlyCard(
            title: Text(
              'Служебная информация',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _MetaRow(label: 'Создал', value: log.createdByDisplayName),
                _MetaRow(
                  label: 'Создано',
                  value: _formatOccurredAt(log.createdAt),
                ),
                _MetaRow(label: 'Обновил', value: log.updatedByDisplayName),
                _MetaRow(
                  label: 'Обновлено',
                  value: _formatOccurredAt(log.updatedAt),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: PawlySpacing.sm),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(value),
        ],
      ),
    );
  }
}

class _LogDetailsErrorView extends StatelessWidget {
  const _LogDetailsErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PawlySpacing.lg),
        child: PawlyCard(
          title: const Text('Не удалось загрузить запись.'),
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
    return 'Не указано';
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

String _attachmentSubtitle(LogAttachment attachment) {
  final type = attachment.fileType.startsWith('image/') ? 'Фото' : 'Документ';
  final addedAt = _formatOccurredAt(attachment.addedAt);
  return '$type • $addedAt';
}
