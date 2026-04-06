import 'package:flutter/material.dart';

import '../../features/pet_care/presentation/models/attachment_kind.dart';
import '../../features/pet_care/presentation/models/attachment_viewer_item.dart';
import '../../features/pet_care/presentation/pages/attachment_viewer_page.dart';

Future<void> openAttachmentUrl(
  BuildContext context, {
  required String fileType,
  required String fileName,
  String? previewUrl,
  String? downloadUrl,
  List<AttachmentViewerItem>? imageGalleryItems,
  int? initialImageIndex,
}) async {
  final item = AttachmentViewerItem.fromAttachment(
    fileType: fileType,
    fileName: fileName,
    previewUrl: previewUrl,
    downloadUrl: downloadUrl,
  );
  final candidate = item.url;

  if (candidate == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Для этого вложения нет ссылки на просмотр.')),
    );
    return;
  }

  final uri = Uri.tryParse(candidate);
  if (uri == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Не удалось открыть вложение.')),
    );
    return;
  }

  if (item.kind == AttachmentKind.image) {
    final galleryItems = imageGalleryItems == null
        ? <AttachmentViewerItem>[item]
        : imageGalleryItems
            .where(
              (galleryItem) =>
                  galleryItem.kind == AttachmentKind.image && galleryItem.url != null,
            )
            .toList(growable: false);
    final fallbackIndex = galleryItems.indexWhere(
      (galleryItem) => galleryItem.url == item.url && galleryItem.title == item.title,
    );
    final resolvedIndex = initialImageIndex ?? fallbackIndex;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AttachmentGalleryPage(
          items: galleryItems.isEmpty ? <AttachmentViewerItem>[item] : galleryItems,
          initialIndex: resolvedIndex >= 0 ? resolvedIndex : 0,
        ),
      ),
    );
    return;
  }

  if (item.kind == AttachmentKind.pdf) {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AttachmentViewerPage(
          title: item.title,
          url: candidate,
          kind: item.kind,
        ),
      ),
    );
    return;
  }

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Этот тип вложения пока нельзя открыть внутри приложения.'),
      ),
    );
  }
}
