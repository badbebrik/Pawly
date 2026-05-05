import 'package:flutter/material.dart';

import '../../../models/health_models.dart';
import '../../../../../design_system/design_system.dart';
import '../../../shared/formatters/health_display_formatters.dart';
import '../../../shared/formatters/health_status_formatters.dart';
import '../shared/health_attachments_section.dart';
import '../shared/health_common_widgets.dart';

class MedicalRecordDetailsView extends StatelessWidget {
  const MedicalRecordDetailsView({
    required this.record,
    required this.onRefresh,
    super.key,
  });

  final MedicalRecord record;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = _detailsLines(record);
    final description = nonEmptyHealthText(record.description);

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
          PawlyListSection(
            children: <Widget>[
              SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.all(PawlySpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        record.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: PawlySpacing.xs),
                      Wrap(
                        spacing: PawlySpacing.xs,
                        runSpacing: PawlySpacing.xs,
                        children: <Widget>[
                          PawlyBadge(
                            label:
                                formatMedicalRecordStatusLabel(record.status),
                            tone: medicalRecordStatusTone(record.status),
                          ),
                          PawlyBadge(
                            label: formatMedicalRecordTypeItemLabel(
                              record.recordTypeItem,
                            ),
                            tone: PawlyBadgeTone.neutral,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (details.isNotEmpty) ...<Widget>[
            const SizedBox(height: PawlySpacing.md),
            HealthDetailsSection(
              title: 'Основное',
              children: details
                  .map(
                    (line) => HealthDetailsRow(
                      label: line.$1,
                      value: line.$2,
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
          if (description != null) ...<Widget>[
            const SizedBox(height: PawlySpacing.md),
            PawlyListSection(
              title: 'Описание',
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(PawlySpacing.md),
                  child: Text(description, style: theme.textTheme.bodyLarge),
                ),
              ],
            ),
          ],
          if (record.attachments.isNotEmpty) ...<Widget>[
            const SizedBox(height: PawlySpacing.md),
            HealthAttachmentsSection(
              attachments: record.attachments,
              formatAddedAt: formatHealthDate,
            ),
          ],
        ],
      ),
    );
  }

  List<(String, String)> _detailsLines(MedicalRecord record) {
    return <(String, String)>[
      if (formatHealthDateOrNull(record.startedAt) case final value?)
        ('Дата начала', value),
      if (formatHealthDateOrNull(record.resolvedAt) case final value?)
        ('Дата закрытия', value),
    ];
  }
}
