import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/health_models.dart';
import '../../../../../design_system/design_system.dart';
import '../../../shared/formatters/health_display_formatters.dart';
import '../../../shared/formatters/health_status_formatters.dart';

class VetVisitListCard extends StatelessWidget {
  const VetVisitListCard({
    required this.petId,
    required this.item,
    super.key,
  });

  final String petId;
  final VetVisitCard item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateLabel = _primaryDateLabel(item);
    final title = formatVetVisitTitle(item.title, item.visitType);
    final typeLabel = formatVetVisitTypeLabel(item.visitType);
    final clinicName = nonEmptyHealthText(item.clinicName);
    final vetName = nonEmptyHealthText(item.vetName);
    final bodyText = nonEmptyHealthText(item.reasonText);
    final chips = <Widget>[
      if (item.status != 'PLANNED')
        PawlyBadge(
          label: formatVetVisitStatusLabel(item.status),
          tone: vetVisitStatusTone(item.status),
        ),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: PawlySpacing.sm),
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(PawlyRadius.xl),
        child: InkWell(
          onTap: () => context.pushNamed(
            'petVetVisitDetails',
            pathParameters: <String, String>{
              'petId': petId,
              'visitId': item.id,
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
                        title,
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
                if (title != typeLabel) ...<Widget>[
                  const SizedBox(height: PawlySpacing.xxs),
                  Text(
                    typeLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
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
                if (clinicName != null || vetName != null) ...<Widget>[
                  const SizedBox(height: PawlySpacing.sm),
                  Text(
                    <String>[
                      if (clinicName != null) clinicName,
                      if (vetName != null) vetName,
                    ].join(' · '),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _primaryDateLabel(VetVisitCard item) {
    final date = switch (item.status) {
      'COMPLETED' => item.completedAt ?? item.scheduledAt,
      _ => item.scheduledAt,
    };
    if (date == null) return null;

    final prefix = switch (item.status) {
      'COMPLETED' => 'Завершен',
      _ => 'Запланирован',
    };
    return '$prefix ${formatHealthDateTime(date)}';
  }
}
