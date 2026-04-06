import '../../../../core/network/models/health_models.dart';
import '../../../../core/network/models/log_models.dart';
import '../../data/health_file_upload_service.dart';

class AttachmentDraftItem {
  const AttachmentDraftItem({
    required this.fileId,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
  });

  factory AttachmentDraftItem.fromUploaded(UploadedHealthAttachmentRef file) {
    return AttachmentDraftItem(
      fileId: file.fileId,
      fileName: file.fileName,
      mimeType: file.mimeType,
      sizeBytes: file.sizeBytes,
    );
  }

  factory AttachmentDraftItem.fromLogAttachment(LogAttachment attachment) {
    return AttachmentDraftItem(
      fileId: attachment.fileId,
      fileName: attachment.fileName,
      mimeType: attachment.fileType,
      sizeBytes: 0,
    );
  }

  factory AttachmentDraftItem.fromHealthAttachment(HealthAttachment attachment) {
    return AttachmentDraftItem(
      fileId: attachment.fileId,
      fileName: attachment.fileName ?? 'Файл',
      mimeType: attachment.fileType,
      sizeBytes: 0,
    );
  }

  final String fileId;
  final String fileName;
  final String mimeType;
  final int sizeBytes;
}
