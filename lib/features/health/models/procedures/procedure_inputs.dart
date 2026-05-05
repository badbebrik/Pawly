import '../../../shared/attachments/data/attachment_input.dart';
import '../shared/health_inputs.dart';

class ProcedureListQuery {
  const ProcedureListQuery({
    this.cursor,
    this.limit = 20,
    this.searchQuery,
    this.status,
    this.bucket,
    this.procedureTypeId,
    this.dateFrom,
    this.dateTo,
    this.sort,
  });

  final String? cursor;
  final int limit;
  final String? searchQuery;
  final String? status;
  final String? bucket;
  final String? procedureTypeId;
  final String? dateFrom;
  final String? dateTo;
  final String? sort;
}

class UpsertProcedureInput {
  const UpsertProcedureInput({
    required this.status,
    this.procedureTypeId,
    this.procedureTypeName,
    required this.title,
    this.description,
    this.catalogMedicationId,
    this.productName,
    this.scheduledAtIso,
    this.performedAtIso,
    this.nextDueAtIso,
    this.vetVisitId,
    this.notes,
    this.attachments,
    this.attachmentFileIds = const <String>[],
    this.reminder,
    this.rowVersion,
  });

  final String status;
  final String? procedureTypeId;
  final String? procedureTypeName;
  final String title;
  final String? description;
  final String? catalogMedicationId;
  final String? productName;
  final String? scheduledAtIso;
  final String? performedAtIso;
  final String? nextDueAtIso;
  final String? vetVisitId;
  final String? notes;
  final List<AttachmentInput>? attachments;
  final List<String> attachmentFileIds;
  final HealthEntityReminderInput? reminder;
  final int? rowVersion;
}
