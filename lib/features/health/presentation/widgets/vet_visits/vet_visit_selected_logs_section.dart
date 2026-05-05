import 'package:flutter/material.dart';

import '../../../../../design_system/design_system.dart';
import '../../../../logs/models/log_models.dart';
import '../../../shared/formatters/health_log_formatters.dart';

class VetVisitSelectedLogsSection extends StatelessWidget {
  const VetVisitSelectedLogsSection({
    required this.logs,
    required this.onAddLog,
    required this.onRemoveLog,
    super.key,
  });

  final List<LogListItem> logs;
  final VoidCallback onAddLog;
  final ValueChanged<String> onRemoveLog;

  @override
  Widget build(BuildContext context) {
    return PawlyListSection(
      title: 'Прикрепленные записи',
      footer: Align(
        alignment: Alignment.centerLeft,
        child: PawlyButton(
          label: 'Прикрепить запись',
          onPressed: onAddLog,
          variant: PawlyButtonVariant.secondary,
        ),
      ),
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
                  subtitle: formatHealthLogListItemSubtitle(log),
                  leadingIcon: Icons.notes_rounded,
                  trailing: IconButton(
                    onPressed: () => onRemoveLog(log.id),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Убрать',
                  ),
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
