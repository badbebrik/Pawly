import '../../../shared/attachments/data/attachment_input.dart';
import '../../../shared/attachments/models/attachment_draft_item.dart';
import '../../models/log_models.dart';

AttachmentDraftItem mapLogAttachmentToDraft(LogAttachmentItem attachment) {
  return AttachmentDraftItem(
    fileId: attachment.fileId,
    fileName: attachment.fileName,
    mimeType: attachment.fileType,
    sizeBytes: 0,
  );
}

List<AttachmentInput> mapAttachmentDraftsToInputs(
  Iterable<AttachmentDraftItem> attachments,
) {
  return attachments
      .map(
        (attachment) => AttachmentInput(
          fileId: attachment.fileId,
          fileName: attachment.fileName,
        ),
      )
      .toList(growable: false);
}
