import '../../../shared/attachments/data/attachment_input.dart';
import '../shared/health_inputs.dart';

class VetVisitListQuery {
  const VetVisitListQuery({
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

class UpsertVetVisitInput {
  const UpsertVetVisitInput({
    required this.status,
    required this.visitType,
    this.title,
    this.scheduledAtIso,
    this.completedAtIso,
    this.reasonText,
    this.resultText,
    this.clinicName,
    this.vetName,
    this.attachments,
    this.attachmentFileIds = const <String>[],
    this.relatedLogIds = const <String>[],
    this.reminder,
    this.rowVersion,
  });

  final String status;
  final String visitType;
  final String? title;
  final String? scheduledAtIso;
  final String? completedAtIso;
  final String? reasonText;
  final String? resultText;
  final String? clinicName;
  final String? vetName;
  final List<AttachmentInput>? attachments;
  final List<String> attachmentFileIds;
  final List<String> relatedLogIds;
  final HealthEntityReminderInput? reminder;
  final int? rowVersion;
}
