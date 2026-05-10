import 'package:flutter/material.dart';

import '../../features/shared/attachments/models/attachment_kind.dart';
import '../../features/shared/attachments/models/attachment_viewer_item.dart';
import '../../features/shared/attachments/presentation/pages/attachment_viewer_page.dart';

Future<void> openAttachmentUrl(
  BuildContext context, {
  String? fileId,
  required String fileType,
  required String fileName,
  String? previewUrl,
  String? downloadUrl,
  List<AttachmentViewerItem>? imageGalleryItems,
  int? initialImageIndex,
}) async {
  try {
    final item = AttachmentViewerItem.fromAttachment(
      fileId: fileId,
      fileType: fileType,
      fileName: fileName,
      previewUrl: previewUrl,
      downloadUrl: downloadUrl,
    );
    final candidate = item.url;

    if (candidate == null) {
      _showAttachmentSnackBar(
        context,
        'Для этого вложения нет ссылки на просмотр.',
      );
      return;
    }

    final uri = Uri.tryParse(candidate);
    if (uri == null) {
      _showAttachmentSnackBar(context, 'Не удалось открыть вложение.');
      return;
    }

    if (item.kind == AttachmentKind.image) {
      final galleryItems = imageGalleryItems == null
          ? <AttachmentViewerItem>[item]
          : imageGalleryItems
              .where(
                (galleryItem) =>
                    galleryItem.kind == AttachmentKind.image &&
                    galleryItem.url != null,
              )
              .toList(growable: false);
      final fallbackIndex = galleryItems.indexWhere(
        (galleryItem) =>
            galleryItem.url == item.url && galleryItem.title == item.title,
      );
      final resolvedIndex = initialImageIndex ?? fallbackIndex;

      if (!context.mounted) {
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => AttachmentGalleryPage(
            items: galleryItems.isEmpty
                ? <AttachmentViewerItem>[item]
                : galleryItems,
            initialIndex: resolvedIndex >= 0 ? resolvedIndex : 0,
          ),
        ),
      );
      return;
    }

    if (item.kind == AttachmentKind.pdf) {
      if (!context.mounted) {
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => AttachmentViewerPage(
            fileId: item.fileId,
            title: item.title,
            url: candidate,
            downloadUrl: item.downloadUrl,
            kind: item.kind,
          ),
        ),
      );
      return;
    }

    _showAttachmentSnackBar(
      context,
      'Этот тип вложения пока нельзя открыть внутри приложения.',
    );
  } catch (_) {
    _showAttachmentSnackBar(context, 'Не удалось открыть вложение.');
  }
}

void _showAttachmentSnackBar(BuildContext context, String message) {
  if (!context.mounted) {
    return;
  }
  final messenger = ScaffoldMessenger.maybeOf(context);
  messenger?.showSnackBar(
    SnackBar(content: Text(message)),
  );
}
