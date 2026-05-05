import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../models/health_models.dart';
import '../../../../../design_system/design_system.dart';
import '../../../shared/formatters/health_display_formatters.dart';
import '../../../shared/formatters/health_status_formatters.dart';

class MedicalRecordListCard extends StatelessWidget {
  const MedicalRecordListCard({
    required this.petId,
    required this.item,
    super.key,
  });

  final String petId;
  final MedicalRecordCard item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateLabel = _dateLine(item);
    final bodyText = nonEmptyHealthText(item.descriptionPreview);
    final chips = <Widget>[
      if (item.status != 'ACTIVE')
        PawlyBadge(
          label: formatMedicalRecordStatusLabel(item.status),
          tone: medicalRecordStatusTone(item.status),
        ),
      PawlyBadge(
        label: formatMedicalRecordTypeItemLabel(item.recordTypeItem),
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
            'petMedicalRecordDetails',
            pathParameters: <String, String>{
              'petId': petId,
              'recordId': item.id,
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
                const SizedBox(height: PawlySpacing.sm),
                Wrap(
                  spacing: PawlySpacing.xs,
                  runSpacing: PawlySpacing.xs,
                  children: chips,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _dateLine(MedicalRecordCard item) {
    final date = switch (item.status) {
      'RESOLVED' => item.resolvedAt ?? item.startedAt,
      _ => item.startedAt,
    };
    if (date == null) {
      return null;
    }
    final prefix = switch (item.status) {
      'RESOLVED' => 'Закрыто',
      _ => 'С',
    };
    return '$prefix ${formatHealthDate(date)}';
  }
}
