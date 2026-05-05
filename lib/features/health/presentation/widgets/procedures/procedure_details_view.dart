import 'package:flutter/material.dart';

import '../../../models/health_models.dart';
import '../../../../../design_system/design_system.dart';
import '../../../shared/formatters/health_display_formatters.dart';
import '../../../shared/formatters/health_status_formatters.dart';
import '../shared/health_attachments_section.dart';
import '../shared/health_common_widgets.dart';

class ProcedureDetailsView extends StatelessWidget {
  const ProcedureDetailsView({
    required this.procedure,
    required this.onRefresh,
    super.key,
  });

  final Procedure procedure;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = _detailsLines(procedure);
    final description = nonEmptyHealthText(procedure.description);
    final notes = nonEmptyHealthText(procedure.notes);

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
                        procedure.title,
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
                            label: formatProcedureStatusLabel(procedure.status),
                            tone: procedureStatusTone(procedure.status),
                          ),
                          PawlyBadge(
                            label: formatProcedureTypeItemLabel(
                              procedure.procedureTypeItem,
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
          if (notes != null) ...<Widget>[
            const SizedBox(height: PawlySpacing.md),
            PawlyListSection(
              title: 'Заметки',
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(PawlySpacing.md),
                  child: Text(notes, style: theme.textTheme.bodyLarge),
                ),
              ],
            ),
          ],
          if (procedure.attachments.isNotEmpty) ...<Widget>[
            const SizedBox(height: PawlySpacing.md),
            HealthAttachmentsSection(attachments: procedure.attachments),
          ],
        ],
      ),
    );
  }

  List<(String, String)> _detailsLines(Procedure procedure) {
    return <(String, String)>[
      if (formatHealthDateTimeOrNull(procedure.scheduledAt) case final value?)
        ('Дата и время по плану', value),
      if (formatHealthDateTimeOrNull(procedure.performedAt) case final value?)
        ('Дата и время выполнения', value),
      if (formatHealthDateTimeOrNull(procedure.nextDueAt) case final value?)
        ('Дата и время повтора', value),
      if (nonEmptyHealthText(procedure.productName) case final value?)
        ('Препарат или средство', value),
    ];
  }
}
