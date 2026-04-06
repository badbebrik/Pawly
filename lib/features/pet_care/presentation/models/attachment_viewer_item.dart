import 'attachment_kind.dart';

class AttachmentViewerItem {
  const AttachmentViewerItem({
    required this.title,
    required this.url,
    required this.kind,
  });

  factory AttachmentViewerItem.fromAttachment({
    required String fileType,
    String? fileName,
    String? previewUrl,
    String? downloadUrl,
  }) {
    final resolvedUrl = _resolveAttachmentUrl(
      previewUrl: previewUrl,
      downloadUrl: downloadUrl,
    );

    return AttachmentViewerItem(
      title: (fileName == null || fileName.trim().isEmpty) ? 'Файл' : fileName.trim(),
      url: resolvedUrl,
      kind: detectAttachmentKind(
        fileType: fileType,
        fileName: fileName,
        fileUrl: resolvedUrl,
      ),
    );
  }

  final String title;
  final String? url;
  final AttachmentKind kind;

  static String? _resolveAttachmentUrl({
    String? previewUrl,
    String? downloadUrl,
  }) {
    if (previewUrl != null && previewUrl.trim().isNotEmpty) {
      return previewUrl.trim();
    }
    if (downloadUrl != null && downloadUrl.trim().isNotEmpty) {
      return downloadUrl.trim();
    }
    return null;
  }
}
