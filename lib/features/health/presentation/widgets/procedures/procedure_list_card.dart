import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/health_models.dart';
import '../../../../../design_system/design_system.dart';
import '../../../shared/formatters/health_display_formatters.dart';
import '../../../shared/formatters/health_status_formatters.dart';

class ProcedureListCard extends StatelessWidget {
  const ProcedureListCard({
    required this.petId,
    required this.item,
    required this.canWrite,
    required this.isBusy,
    this.onMarkDone,
    super.key,
  });

  final String petId;
  final ProcedureCard item;
  final bool canWrite;
  final bool isBusy;
  final VoidCallback? onMarkDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateLabel = _primaryDateLabel(item);
    final productName = nonEmptyHealthText(item.productName);
    final bodyText = nonEmptyHealthText(item.descriptionPreview);
    final chips = <Widget>[
      if (item.status != 'PLANNED')
        PawlyBadge(
          label: formatProcedureStatusLabel(item.status),
          tone: procedureStatusTone(item.status),
        ),
      PawlyBadge(
        label: formatProcedureTypeItemLabel(item.procedureTypeItem),
        tone: PawlyBadgeTone.neutral,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: PawlySpacing.sm),
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(PawlyRadius.xl),
        child: InkWell(
          onTap: () => context.pushNamed(
            'petProcedureDetails',
            pathParameters: <String, String>{
              'petId': petId,
              'procedureId': item.id,
            },
          ),
          borderRadius: BorderRadius.circular(PawlyRadius.xl),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(PawlyRadius.xl),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.72),
              ),
            ),
            padding: const EdgeInsets.all(PawlySpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: PawlySpacing.sm),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
                if (dateLabel != null) ...<Widget>[
                  const SizedBox(height: PawlySpacing.xxs),
                  Text(
                    dateLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                if (productName != null) ...<Widget>[
                  const SizedBox(height: PawlySpacing.sm),
                  Text(
                    productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (bodyText != null) ...<Widget>[
                  const SizedBox(height: PawlySpacing.sm),
                  Text(
                    bodyText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                      height: 1.35,
                    ),
                  ),
                ],
                if (chips.isNotEmpty) ...<Widget>[
                  const SizedBox(height: PawlySpacing.sm),
                  Wrap(
                    spacing: PawlySpacing.xs,
                    runSpacing: PawlySpacing.xs,
                    children: chips,
                  ),
                ],
                if (onMarkDone != null && canWrite) ...<Widget>[
                  const SizedBox(height: PawlySpacing.md),
                  PawlyButton(
                    label: isBusy ? 'Сохраняем...' : 'Отметить выполненной',
                    onPressed: isBusy ? null : onMarkDone,
                    fullWidth: false,
                    icon: Icons.check_circle_outline_rounded,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _primaryDateLabel(ProcedureCard item) {
    final date = switch (item.status) {
      'COMPLETED' => item.performedAt ?? item.scheduledAt,
      _ => item.scheduledAt,
    };
    if (date == null) {
      return null;
    }
    final prefix = switch (item.status) {
      'COMPLETED' => 'Выполнено',
      _ => 'Запланировано',
    };
    return '$prefix ${formatHealthDateTime(date)}';
  }
}
