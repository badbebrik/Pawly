import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/design_system.dart';
import '../../shared/utils/log_type_utils.dart';
import '../../states/logs_state.dart';
import 'log_card_item.dart';
import 'logs_filter_widgets.dart';
import 'logs_state_views.dart';

class LogsListView extends StatelessWidget {
  const LogsListView({
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
    super.key,
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
    final logTypeCodesById = <String, String?>{
      for (final type in groupedBootstrapLogTypes(state.bootstrap).all)
        type.id: type.code,
    };

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
          LogsFilters(
            state: state,
            onSearchChanged: onSearchChanged,
            onToggleType: onToggleType,
            onApplyTypeFilters: onApplyTypeFilters,
            onSetSource: onSetSource,
            onSetWithAttachmentsOnly: onSetWithAttachmentsOnly,
            onSetWithMetricsOnly: onSetWithMetricsOnly,
          ),
          const SizedBox(height: PawlySpacing.md),
          if (state.logs.isEmpty)
            const LogsInlineMessage(
              title: 'Записей нет',
              message: 'По выбранным фильтрам записей пока нет.',
            )
          else
            ...state.logs.map(
              (log) => LogCardItem(
                log: log,
                logTypeCode: log.logTypeId == null
                    ? null
                    : logTypeCodesById[log.logTypeId!],
                onTap: () => _openLogDetails(context, log.id),
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

  Future<void> _openLogDetails(BuildContext context, String logId) async {
    final changed = await context.pushNamed<bool>(
      'petLogDetails',
      pathParameters: <String, String>{
        'petId': petId,
        'logId': logId,
      },
    );
    if (changed == true && context.mounted) {
      await onRefresh();
    }
  }
}
