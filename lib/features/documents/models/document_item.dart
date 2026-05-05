class DocumentItem {
  const DocumentItem({
    this.id,
    required this.fileId,
    this.fileName,
    required this.fileType,
    this.downloadUrl,
    this.previewUrl,
    this.addedAt,
    this.addedByUserId,
    required this.entityType,
    required this.entityId,
  });

  final String? id;
  final String fileId;
  final String? fileName;
  final String fileType;
  final String? downloadUrl;
  final String? previewUrl;
  final DateTime? addedAt;
  final String? addedByUserId;
  final String entityType;
  final String entityId;
}
