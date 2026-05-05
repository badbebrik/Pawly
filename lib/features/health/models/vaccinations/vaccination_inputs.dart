import '../../../shared/attachments/data/attachment_input.dart';
import '../shared/health_inputs.dart';

class VaccinationListQuery {
  const VaccinationListQuery({
    this.cursor,
    this.limit = 20,
    this.searchQuery,
    this.status,
    this.bucket,
    this.dateFrom,
    this.dateTo,
    this.sort,
  });

  final String? cursor;
  final int limit;
  final String? searchQuery;
  final String? status;
  final String? bucket;
  final String? dateFrom;
  final String? dateTo;
  final String? sort;
}

class UpsertVaccinationInput {
  const UpsertVaccinationInput({
    required this.status,
    required this.vaccineName,
    this.catalogMedicationId,
    this.targets,
    this.scheduledAtIso,
    this.administeredAtIso,
    this.nextDueAtIso,
    this.vetVisitId,
    this.clinicName,
    this.vetName,
    this.notes,
    this.attachments,
    this.attachmentFileIds = const <String>[],
    this.reminder,
    this.rowVersion,
  });

  final String status;
  final String vaccineName;
  final String? catalogMedicationId;
  final List<HealthDictionaryRefInput>? targets;
  final String? scheduledAtIso;
  final String? administeredAtIso;
  final String? nextDueAtIso;
  final String? vetVisitId;
  final String? clinicName;
  final String? vetName;
  final String? notes;
  final List<AttachmentInput>? attachments;
  final List<String> attachmentFileIds;
  final HealthEntityReminderInput? reminder;
  final int? rowVersion;
}
