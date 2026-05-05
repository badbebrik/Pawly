import 'package:flutter/material.dart';

import '../../../models/health_models.dart';
import '../../../../../design_system/design_system.dart';
import '../../../shared/formatters/health_log_formatters.dart';

class VetVisitRelatedLogsSection extends StatelessWidget {
  const VetVisitRelatedLogsSection({
    required this.logs,
    required this.canAttachLogs,
    required this.canReadLogs,
    required this.canEdit,
    required this.isMutating,
    required this.onAttach,
    required this.onOpenLog,
    required this.onUnlinkLog,
    super.key,
  });

  final List<RelatedLog> logs;
  final bool canAttachLogs;
  final bool canReadLogs;
  final bool canEdit;
  final bool isMutating;
  final VoidCallback onAttach;
  final ValueChanged<RelatedLog> onOpenLog;
  final ValueChanged<RelatedLog> onUnlinkLog;

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty && !canAttachLogs) {
      return const SizedBox.shrink();
    }

    return PawlyListSection(
      title: 'Связанные записи',
      footer: canAttachLogs
          ? PawlyButton(
              label: isMutating ? 'Обновляем...' : 'Прикрепить запись',
              onPressed: isMutating ? null : onAttach,
              icon: Icons.add_link_rounded,
              variant: PawlyButtonVariant.secondary,
            )
          : null,
      children: logs.isEmpty
          ? const <Widget>[
              Padding(
                padding: EdgeInsets.all(PawlySpacing.md),
                child: _AttachedLogsEmptyState(),
              ),
            ]
          : logs
              .map(
                (log) => PawlyListTile(
                  title: log.logTypeName ?? 'Запись',
                  subtitle: formatHealthRelatedLogSubtitle(log),
                  leadingIcon: Icons.notes_rounded,
                  trailing: canEdit
                      ? IconButton(
                          onPressed: isMutating ? null : () => onUnlinkLog(log),
                          icon: const Icon(Icons.link_off_rounded),
                          tooltip: 'Открепить',
                        )
                      : null,
                  onTap: canReadLogs ? () => onOpenLog(log) : null,
                ),
              )
              .toList(growable: false),
    );
  }
}

class _AttachedLogsEmptyState extends StatelessWidget {
  const _AttachedLogsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Text(
      'К этому визиту пока не прикреплены записи.',
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}
