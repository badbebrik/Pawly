import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../models/calendar_occurrence_target.dart';

void openCalendarOccurrenceTarget(
  BuildContext context,
  CalendarOccurrenceTarget target,
) {
  switch (target.kind) {
    case CalendarOccurrenceTargetKind.vetVisitDetails:
      context.pushNamed(
        'petVetVisitDetails',
        pathParameters: <String, String>{
          'petId': target.petId,
          'visitId': target.sourceId!,
        },
      );
    case CalendarOccurrenceTargetKind.vaccinationDetails:
      context.pushNamed(
        'petVaccinationDetails',
        pathParameters: <String, String>{
          'petId': target.petId,
          'vaccinationId': target.sourceId!,
        },
      );
    case CalendarOccurrenceTargetKind.procedureDetails:
      context.pushNamed(
        'petProcedureDetails',
        pathParameters: <String, String>{
          'petId': target.petId,
          'procedureId': target.sourceId!,
        },
      );
    case CalendarOccurrenceTargetKind.logCreate:
      context.pushNamed(
        'petLogCreate',
        pathParameters: <String, String>{'petId': target.petId},
        queryParameters: <String, String>{'logTypeId': target.sourceId!},
      );
    case CalendarOccurrenceTargetKind.reminderEdit:
      context.pushNamed(
        'petReminderEdit',
        pathParameters: <String, String>{
          'petId': target.petId,
          'itemId': target.scheduledItemId!,
        },
      );
    case CalendarOccurrenceTargetKind.reminders:
      context.pushNamed(
        'petReminders',
        pathParameters: <String, String>{'petId': target.petId},
      );
  }
}
