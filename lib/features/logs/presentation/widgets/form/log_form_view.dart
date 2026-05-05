import 'package:flutter/material.dart';

import '../../../../../design_system/design_system.dart';
import '../../../../shared/attachments/models/attachment_draft_item.dart';
import '../../../../shared/attachments/presentation/widgets/attachment_upload_field.dart';
import '../../../models/log_constants.dart';
import '../../../models/log_models.dart';
import '../../../shared/formatters/log_form_formatters.dart';
import 'log_form_section.dart';
import 'log_metric_field.dart';
import 'log_selector_tiles.dart';

class LogFormView extends StatelessWidget {
  const LogFormView({
    required this.petId,
    required this.canSubmit,
    required this.canManageAttachments,
    required this.selectedType,
    required this.occurredAt,
    required this.descriptionController,
    required this.attachments,
    required this.isUploadingAttachments,
    required this.submitLabel,
    required this.onPickType,
    required this.onPickOccurredAt,
    required this.onSubmit,
    required this.controllerForMetric,
    required this.booleanValueForMetric,
    required this.onSetBooleanMetric,
    required this.onAttachmentsChanged,
    required this.onUploadingAttachmentsChanged,
    this.topMessage,
    super.key,
  });

  final String petId;
  final bool canSubmit;
  final bool canManageAttachments;
  final LogTypeItem? selectedType;
  final DateTime occurredAt;
  final TextEditingController descriptionController;
  final List<AttachmentDraftItem> attachments;
  final bool isUploadingAttachments;
  final String submitLabel;
  final VoidCallback? onPickType;
  final VoidCallback? onPickOccurredAt;
  final VoidCallback? onSubmit;
  final TextEditingController Function(String metricId) controllerForMetric;
  final bool? Function(String metricId) booleanValueForMetric;
  final void Function(String metricId, bool value) onSetBooleanMetric;
  final ValueChanged<List<AttachmentDraftItem>> onAttachmentsChanged;
  final ValueChanged<bool> onUploadingAttachmentsChanged;
  final Widget? topMessage;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        PawlySpacing.md,
        PawlySpacing.sm,
        PawlySpacing.md,
        PawlySpacing.xl,
      ),
      children: <Widget>[
        if (topMessage != null) ...<Widget>[
          topMessage!,
          const SizedBox(height: PawlySpacing.md),
        ],
        LogTypeSelectorCard(
          onTap: onPickType,
          title: selectedType == null ? 'Без типа' : selectedType!.name,
          subtitle: selectedType == null
              ? 'Можно оставить запись без типа'
              : '${logTypeScopeLabel(selectedType!.scope)} · ${logTypeMetricsLabel(selectedType!)}',
        ),
        const SizedBox(height: PawlySpacing.md),
        if (selectedType != null &&
            selectedType!.metricRequirements.isNotEmpty) ...<Widget>[
          LogFormSection(
            title: 'Показатели',
            child: Column(
              children: selectedType!.metricRequirements
                  .map(
                    (requirement) => Padding(
                      padding: const EdgeInsets.only(bottom: PawlySpacing.sm),
                      child: LogMetricField(
                        requirement: requirement,
                        enabled: canSubmit,
                        textController:
                            controllerForMetric(requirement.metricId),
                        booleanValue:
                            booleanValueForMetric(requirement.metricId),
                        onSetBooleanValue: (value) => onSetBooleanMetric(
                          requirement.metricId,
                          value,
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
          const SizedBox(height: PawlySpacing.md),
        ],
        LogDateTile(
          value: formatLogFormDateTime(occurredAt),
          onTap: onPickOccurredAt,
        ),
        const SizedBox(height: PawlySpacing.md),
        LogFormSection(
          title: 'Описание',
          child: PawlyTextField(
            controller: descriptionController,
            hintText: 'Что произошло',
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            enabled: canSubmit,
          ),
        ),
        const SizedBox(height: PawlySpacing.lg),
        AttachmentUploadField(
          petId: petId,
          entityType: LogAttachmentEntityType.log,
          attachments: attachments,
          isUploading: isUploadingAttachments,
          enabled: canManageAttachments,
          onChanged: onAttachmentsChanged,
          onUploadingChanged: onUploadingAttachmentsChanged,
        ),
        const SizedBox(height: PawlySpacing.lg),
        PawlyButton(
          label: submitLabel,
          onPressed: onSubmit,
          icon: Icons.check_rounded,
        ),
      ],
    );
  }
}
