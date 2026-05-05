import '../models/attachment_kind.dart';

String attachmentTypeLabel(String mimeType, {String? fileName}) {
  return switch (detectAttachmentKind(fileType: mimeType, fileName: fileName)) {
    AttachmentKind.image => 'Фото',
    AttachmentKind.pdf => 'PDF',
    AttachmentKind.other => 'Документ',
  };
}

String attachmentSizeLabel(int sizeBytes) {
  if (sizeBytes < 1024) {
    return '$sizeBytes Б';
  }
  final sizeKb = sizeBytes / 1024;
  if (sizeKb < 1024) {
    return '${sizeKb.toStringAsFixed(sizeKb >= 100 ? 0 : 1)} КБ';
  }
  final sizeMb = sizeKb / 1024;
  return '${sizeMb.toStringAsFixed(sizeMb >= 100 ? 0 : 1)} МБ';
}
