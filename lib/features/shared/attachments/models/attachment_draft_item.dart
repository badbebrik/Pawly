import '../../../../core/network/models/health_models.dart';
import '../data/attachment_upload_service.dart';

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

  factory AttachmentDraftItem.fromHealthAttachment(
      HealthAttachment attachment) {
    return AttachmentDraftItem.fromStoredAttachment(
      fileId: attachment.fileId,
      fileName: attachment.fileName,
      fileType: attachment.fileType,
    );
  }

  factory AttachmentDraftItem.fromStoredAttachment({
    required String fileId,
    required String? fileName,
    required String fileType,
  }) {
    return AttachmentDraftItem(
      fileId: fileId,
      fileName: fileName ?? 'Файл',
      mimeType: fileType,
      sizeBytes: 0,
    );
  }

  final String fileId;
  final String fileName;
  final String mimeType;
  final int sizeBytes;

  AttachmentDraftItem copyWith({
    String? fileName,
  }) {
    return AttachmentDraftItem(
      fileId: fileId,
      fileName: fileName ?? this.fileName,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
    );
  }
}
