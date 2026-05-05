import '../../../shared/attachments/data/attachment_input.dart';

class MedicalRecordListQuery {
  const MedicalRecordListQuery({
    this.cursor,
    this.limit = 20,
    this.searchQuery,
    this.status,
    this.bucket,
    this.recordTypeId,
    this.sort,
  });

  final String? cursor;
  final int limit;
  final String? searchQuery;
  final String? status;
  final String? bucket;
  final String? recordTypeId;
  final String? sort;
}

class UpsertMedicalRecordInput {
  const UpsertMedicalRecordInput({
    this.recordTypeId,
    this.recordTypeName,
    required this.status,
    required this.title,
    this.description,
    this.startedAtIso,
    this.resolvedAtIso,
    this.attachments,
    this.attachmentFileIds = const <String>[],
    this.rowVersion,
  });

  final String? recordTypeId;
  final String? recordTypeName;
  final String status;
  final String title;
  final String? description;
  final String? startedAtIso;
  final String? resolvedAtIso;
  final List<AttachmentInput>? attachments;
  final List<String> attachmentFileIds;
  final int? rowVersion;
}
