import 'attachment_kind.dart';

class AttachmentViewerItem {
  const AttachmentViewerItem({
    this.fileId,
    required this.title,
    required this.url,
    this.downloadUrl,
    required this.kind,
  });

  factory AttachmentViewerItem.fromAttachment({
    String? fileId,
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
      fileId: fileId,
      title: (fileName == null || fileName.trim().isEmpty)
          ? 'Файл'
          : fileName.trim(),
      url: resolvedUrl,
      downloadUrl: (downloadUrl == null || downloadUrl.trim().isEmpty)
          ? resolvedUrl
          : downloadUrl.trim(),
      kind: detectAttachmentKind(
        fileType: fileType,
        fileName: fileName,
        fileUrl: resolvedUrl,
      ),
    );
  }

  final String? fileId;
  final String title;
  final String? url;
  final String? downloadUrl;
  final AttachmentKind kind;

  String cacheKeyFor(String variant) {
    final normalizedVariant = variant.trim().isEmpty ? 'default' : variant;
    final normalizedFileId = fileId?.trim();
    if (normalizedFileId != null && normalizedFileId.isNotEmpty) {
      return 'attachment:$normalizedVariant:$normalizedFileId';
    }

    final normalizedUrl = _normalizedUrlForCache(url);
    return 'attachment:$normalizedVariant:$normalizedUrl';
  }

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

  static String _normalizedUrlForCache(String? value) {
    final candidate = value?.trim();
    if (candidate == null || candidate.isEmpty) {
      return 'empty';
    }

    final uri = Uri.tryParse(candidate);
    if (uri == null) {
      return candidate;
    }

    return uri.replace(query: null, fragment: null).toString();
  }
}
