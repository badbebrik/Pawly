import 'package:flutter/material.dart';

import '../../../models/reminder_form.dart';
import '../../../models/reminder_form_constants.dart';
import '../../../models/reminder_models.dart';
import '../../../shared/utils/reminder_source_utils.dart';

class ReminderFormDraft {
  ReminderFormDraft();

  final titleController = TextEditingController();
  final noteController = TextEditingController();
  final intervalController = TextEditingController(text: '1');

  DateTime startsAt = DateTime.now().add(const Duration(hours: 1));
  String sourceType = 'MANUAL';
  String? selectedLogTypeId;
  String? selectedLogTypeLabel;
  String recurrenceRule = noReminderRecurrenceValue;
  DateTime? untilDate;
  bool pushEnabled = true;
  int? remindOffsetMinutes = 0;
  int rowVersion = 0;

  String? _loadedReminderId;

  bool get canEditRule => isUserManagedReminderSource(sourceType);

  void dispose() {
    titleController.dispose();
    noteController.dispose();
    intervalController.dispose();
  }

  void selectManualSource() {
    sourceType = 'MANUAL';
    selectedLogTypeId = null;
    selectedLogTypeLabel = null;
  }

  void selectLogTypeSource() {
    sourceType = 'LOG_TYPE';
  }

  void setLogTypePickerResult(String logTypeId, String? logTypeName) {
    selectedLogTypeId = logTypeId;
    selectedLogTypeLabel = logTypeName;
    if (titleController.text.trim().isEmpty && logTypeName != null) {
      titleController.text = logTypeName;
    }
  }

  void setRecurrenceRule(String value) {
    recurrenceRule = value;
    if (value == noReminderRecurrenceValue) {
      untilDate = null;
    }
  }

  bool populateFromReminderOnce(ReminderDetails reminder) {
    if (_loadedReminderId == reminder.id) {
      return false;
    }

    _loadedReminderId = reminder.id;
    rowVersion = reminder.rowVersion;
    sourceType = reminder.sourceType;
    selectedLogTypeId = reminder.sourceId;
    selectedLogTypeLabel = null;
    titleController.text = reminder.title;
    noteController.text = reminder.note ?? '';
    startsAt = (reminder.startsAt ?? DateTime.now()).toLocal();
    pushEnabled = reminder.pushEnabled;
    remindOffsetMinutes = reminder.remindOffsetMinutes ?? 0;
    recurrenceRule = reminder.recurrence?.rule ?? noReminderRecurrenceValue;
    intervalController.text = (reminder.recurrence?.interval ?? 1).toString();
    untilDate = reminder.recurrence?.until?.toLocal();
    return true;
  }

  ReminderForm buildForm({bool includeRowVersion = false}) {
    final note = noteController.text.trim();
    return ReminderForm(
      sourceType: sourceType,
      sourceId: sourceType == 'LOG_TYPE' ? selectedLogTypeId : null,
      title: titleController.text.trim(),
      note: note.isEmpty ? null : note,
      startsAt: startsAt,
      pushEnabled: pushEnabled,
      remindOffsetMinutes: pushEnabled ? (remindOffsetMinutes ?? 0) : null,
      recurrenceRule: recurrenceRule,
      recurrenceInterval: int.parse(intervalController.text.trim()),
      recurrenceUntil: untilDate,
      rowVersion: includeRowVersion ? rowVersion : null,
    );
  }
}
