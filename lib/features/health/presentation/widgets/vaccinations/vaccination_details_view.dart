import 'package:flutter/material.dart';

import '../../../models/health_models.dart';
import '../../../../../design_system/design_system.dart';
import '../../../shared/formatters/health_display_formatters.dart';
import '../../../shared/formatters/health_status_formatters.dart';
import '../shared/health_attachments_section.dart';
import '../shared/health_common_widgets.dart';

class VaccinationDetailsView extends StatelessWidget {
  const VaccinationDetailsView({
    required this.vaccination,
    required this.onRefresh,
    super.key,
  });

  final Vaccination vaccination;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final canMutate = vaccination.canEdit || vaccination.canDelete;
    final mainRows = <Widget>[
      if (formatHealthDateTimeOrNull(vaccination.scheduledAt) case final value?)
        HealthDetailsRow(
          label: 'По плану',
          value: value,
        ),
      if (formatHealthDateTimeOrNull(vaccination.administeredAt)
          case final value?)
        HealthDetailsRow(
          label: 'Выполнена',
          value: value,
        ),
      if (formatHealthDateTimeOrNull(vaccination.nextDueAt) case final value?)
        HealthDetailsRow(
          label: 'Ревакцинация',
          value: value,
        ),
      if (vaccination.targets.isNotEmpty)
        HealthDetailsRow(
          label: 'Цели',
          value: vaccination.targets.map((target) => target.name).join(', '),
        ),
      if (nonEmptyHealthText(vaccination.clinicName) case final value?)
        HealthDetailsRow(
          label: 'Клиника',
          value: value,
        ),
      if (nonEmptyHealthText(vaccination.vetName) case final value?)
        HealthDetailsRow(
          label: 'Врач',
          value: value,
        ),
    ];
    final notes = vaccination.notes?.trim() ?? '';

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
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: vaccinationStatusColor(vaccination.status)
                              .withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.vaccines_rounded,
                          color: vaccinationStatusColor(vaccination.status),
                        ),
                      ),
                      const SizedBox(width: PawlySpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              vaccination.vaccineName,
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
                                  label: formatVaccinationStatusLabel(
                                    vaccination.status,
                                  ),
                                  tone:
                                      vaccinationStatusTone(vaccination.status),
                                ),
                                if (!canMutate)
                                  const PawlyBadge(
                                    label: 'Только просмотр',
                                    tone: PawlyBadgeTone.warning,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: PawlySpacing.md),
          if (mainRows.isNotEmpty)
            HealthDetailsSection(
              title: 'Основное',
              children: mainRows,
            ),
          if (notes.isNotEmpty) ...<Widget>[
            const SizedBox(height: PawlySpacing.md),
            PawlyListSection(
              title: 'Заметки',
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(PawlySpacing.md),
                  child: Text(
                    notes,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (vaccination.attachments.isNotEmpty) ...<Widget>[
            const SizedBox(height: PawlySpacing.md),
            HealthAttachmentsSection(attachments: vaccination.attachments),
          ],
        ],
      ),
    );
  }
}
