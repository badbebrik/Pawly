import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../models/health_models.dart';
import '../../../../../design_system/design_system.dart';
import '../../../../logs/models/log_models.dart';
import '../../../controllers/home/health_home_controller.dart';
import '../../../controllers/vet_visits/vet_visits_controller.dart';
import '../../../shared/formatters/health_display_formatters.dart';
import '../../../shared/formatters/health_status_formatters.dart';
import '../../../shared/utils/health_error_messages.dart';
import '../../../states/vet_visits/vet_visits_state.dart';
import '../shared/health_attachments_section.dart';
import '../shared/health_common_widgets.dart';
import 'vet_visit_log_picker_sheet.dart';
import 'vet_visit_related_logs_section.dart';

class VetVisitDetailsView extends ConsumerStatefulWidget {
  const VetVisitDetailsView({
    required this.petId,
    required this.visit,
    required this.onRefresh,
    super.key,
  });

  final String petId;
  final VetVisit visit;
  final Future<void> Function() onRefresh;

  @override
  ConsumerState<VetVisitDetailsView> createState() =>
      _VetVisitDetailsViewState();
}

class _VetVisitDetailsViewState extends ConsumerState<VetVisitDetailsView> {
  bool _isMutatingLogs = false;

  @override
  Widget build(BuildContext context) {
    final visit = widget.visit;
    final listState =
        ref.watch(petVetVisitsControllerProvider(widget.petId)).asData?.value;
    final canReadLogs = listState?.bootstrap.permissions.logRead == true;
    final canAttachLogs = visit.canEdit && canReadLogs;
    final theme = Theme.of(context);
    final mainRows = <Widget>[
      if (formatHealthDateTimeOrNull(visit.scheduledAt) case final value?)
        HealthDetailsRow(label: 'Дата визита', value: value),
      if (formatHealthDateTimeOrNull(visit.completedAt) case final value?)
        HealthDetailsRow(label: 'Дата завершения', value: value),
      if (nonEmptyHealthText(visit.clinicName) case final value?)
        HealthDetailsRow(label: 'Клиника', value: value),
      if (nonEmptyHealthText(visit.vetName) case final value?)
        HealthDetailsRow(label: 'Ветеринар', value: value),
    ];
    final reason = nonEmptyHealthText(visit.reasonText);
    final result = nonEmptyHealthText(visit.resultText);

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
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
                        formatVetVisitTitle(visit.title, visit.visitType),
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
                            label: formatVetVisitStatusLabel(visit.status),
                            tone: vetVisitStatusTone(visit.status),
                          ),
                          PawlyBadge(
                            label: formatVetVisitTypeLabel(visit.visitType),
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
          if (mainRows.isNotEmpty) ...<Widget>[
            const SizedBox(height: PawlySpacing.md),
            HealthDetailsSection(
              title: 'Основное',
              children: mainRows,
            ),
          ],
          if (reason != null) ...<Widget>[
            const SizedBox(height: PawlySpacing.md),
            PawlyListSection(
              title: 'Причина визита',
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(PawlySpacing.md),
                  child: Text(reason, style: theme.textTheme.bodyLarge),
                ),
              ],
            ),
          ],
          if (result != null) ...<Widget>[
            const SizedBox(height: PawlySpacing.md),
            PawlyListSection(
              title: 'Результат визита',
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(PawlySpacing.md),
                  child: Text(result, style: theme.textTheme.bodyLarge),
                ),
              ],
            ),
          ],
          if (visit.relatedLogs.isNotEmpty || canAttachLogs) ...<Widget>[
            const SizedBox(height: PawlySpacing.md),
            VetVisitRelatedLogsSection(
              logs: visit.relatedLogs,
              canAttachLogs: canAttachLogs,
              canReadLogs: canReadLogs,
              canEdit: visit.canEdit,
              isMutating: _isMutatingLogs,
              onAttach: _attachLog,
              onOpenLog: _openLog,
              onUnlinkLog: _unlinkLog,
            ),
          ],
          if (visit.attachments.isNotEmpty) ...<Widget>[
            const SizedBox(height: PawlySpacing.md),
            HealthAttachmentsSection(attachments: visit.attachments),
          ],
        ],
      ),
    );
  }

  Future<void> _attachLog() async {
    final selected = await showModalBottomSheet<LogListItem>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => VetVisitLogPickerSheet(
        petId: widget.petId,
        excludedLogIds: widget.visit.relatedLogs.map((log) => log.id).toSet(),
      ),
    );
    if (selected == null || !mounted) {
      return;
    }

    setState(() => _isMutatingLogs = true);
    try {
      await ref
          .read(petVetVisitsControllerProvider(widget.petId).notifier)
          .linkLogToVisit(
            visitId: widget.visit.id,
            logId: selected.id,
          );
      _refreshVisitData();
      if (!mounted) return;
      showPawlySnackBar(
        context,
        message: 'Запись прикреплена.',
        tone: PawlySnackBarTone.success,
      );
    } catch (error) {
      if (!mounted) return;
      showPawlySnackBar(
        context,
        message: healthMutationErrorMessage(
          error,
          'Не удалось прикрепить запись.',
        ),
        tone: PawlySnackBarTone.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isMutatingLogs = false);
      }
    }
  }

  void _openLog(RelatedLog log) {
    context.pushNamed(
      'petLogDetails',
      pathParameters: <String, String>{
        'petId': widget.petId,
        'logId': log.id,
      },
    );
  }

  Future<void> _unlinkLog(RelatedLog log) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Открепить запись?'),
            content: const Text(
              'Запись останется в журнале питомца, но больше не будет связана с этим визитом.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Отмена'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Открепить'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) {
      return;
    }

    setState(() => _isMutatingLogs = true);
    try {
      await ref
          .read(petVetVisitsControllerProvider(widget.petId).notifier)
          .unlinkLogFromVisit(
            visitId: widget.visit.id,
            logId: log.id,
          );
      _refreshVisitData();
      if (!mounted) return;
      showPawlySnackBar(
        context,
        message: 'Запись откреплена.',
        tone: PawlySnackBarTone.success,
      );
    } catch (error) {
      if (!mounted) return;
      showPawlySnackBar(
        context,
        message: healthMutationErrorMessage(
          error,
          'Не удалось открепить запись.',
        ),
        tone: PawlySnackBarTone.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isMutatingLogs = false);
      }
    }
  }

  void _refreshVisitData() {
    ref.invalidate(
      petVetVisitDetailsProvider(
        PetVetVisitRef(petId: widget.petId, visitId: widget.visit.id),
      ),
    );
    ref.invalidate(petVetVisitsControllerProvider(widget.petId));
    ref.invalidate(petHealthHomeProvider(widget.petId));
  }
}
