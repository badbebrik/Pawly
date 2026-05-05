import 'package:flutter/material.dart';

import '../../../../shared/attachments/data/attachment_input.dart';
import '../../../../shared/attachments/models/attachment_draft_item.dart';
import '../../../models/log_constants.dart';
import '../../../models/log_form.dart';
import '../../../models/log_models.dart';
import '../../../shared/formatters/log_form_formatters.dart';
import '../../../shared/mappers/log_attachment_form_mappers.dart';
import '../../../shared/validators/log_form_validator.dart';

class LogFormDraft {
  LogFormDraft({
    String? initialLogTypeId,
    DateTime? initialOccurredAt,
  })  : descriptionController = TextEditingController(),
        occurredAt = initialOccurredAt ?? DateTime.now(),
        selectedTypeId = initialLogTypeId;

  final TextEditingController descriptionController;
  final Map<String, TextEditingController> _metricControllers =
      <String, TextEditingController>{};
  final Map<String, bool?> _booleanMetricValues = <String, bool?>{};
  final List<AttachmentDraftItem> attachments = <AttachmentDraftItem>[];

  DateTime occurredAt;
  String? selectedTypeId;
  bool isUploadingAttachments = false;
  bool _didPopulateFromLog = false;

  TextEditingController controllerForMetric(String metricId) {
    return _metricControllers.putIfAbsent(metricId, TextEditingController.new);
  }

  bool? booleanValueForMetric(String metricId) {
    return _booleanMetricValues[metricId];
  }

  void setBooleanMetric(String metricId, bool value) {
    _booleanMetricValues[metricId] = value;
  }

  void setAttachments(List<AttachmentDraftItem> value) {
    attachments
      ..clear()
      ..addAll(value);
  }

  void setUploadingAttachments(bool value) {
    isUploadingAttachments = value;
  }

  void setTypePickerResult(String selectedTypePickerResult) {
    selectedTypeId = selectedTypePickerResult == noLogTypeSelectionId
        ? null
        : selectedTypePickerResult;
  }

  void populateFromLogOnce(LogDetails log) {
    if (_didPopulateFromLog) {
      return;
    }
    _didPopulateFromLog = true;
    selectedTypeId = log.logTypeId;
    occurredAt = (log.occurredAt ?? DateTime.now()).toLocal();
    descriptionController.text = log.description;
    attachments
      ..clear()
      ..addAll(log.attachments.map(mapLogAttachmentToDraft));
    for (final metric in log.metricValues) {
      if (metric.inputKind == LogMetricInputKind.boolean) {
        _booleanMetricValues[metric.metricId] = metric.valueNum != 0;
      } else {
        controllerForMetric(metric.metricId).text =
            formatLogMetricInputValue(metric.valueNum);
      }
    }
  }

  LogFormDraftValidation validate(LogTypeItem? selectedType) {
    final metricValidation = validateLogMetricValues(
      requirements: selectedType?.metricRequirements ?? const [],
      textValueForMetric: (metricId) => controllerForMetric(metricId).text,
      booleanValueForMetric: (metricId) => _booleanMetricValues[metricId],
    );
    if (!metricValidation.isValid) {
      return LogFormDraftValidation.failure(metricValidation.errorMessage!);
    }

    return LogFormDraftValidation.success(
      LogForm(
        occurredAt: occurredAt,
        logTypeId: selectedTypeId,
        description: descriptionController.text,
        metricValues: metricValidation.values,
      ),
    );
  }

  List<AttachmentInput> attachmentInputs() {
    return mapAttachmentDraftsToInputs(attachments);
  }

  void dispose() {
    descriptionController.dispose();
    for (final controller in _metricControllers.values) {
      controller.dispose();
    }
  }
}

class LogFormDraftValidation {
  const LogFormDraftValidation._({
    this.form,
    this.errorMessage,
  });

  factory LogFormDraftValidation.success(LogForm form) {
    return LogFormDraftValidation._(form: form);
  }

  factory LogFormDraftValidation.failure(String message) {
    return LogFormDraftValidation._(errorMessage: message);
  }

  final LogForm? form;
  final String? errorMessage;

  bool get isValid => errorMessage == null;
}
