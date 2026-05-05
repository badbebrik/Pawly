import 'package:flutter/material.dart';

import '../../../models/health_models.dart';
import '../../../../../core/services/attachment_launcher.dart';
import '../../../../../design_system/design_system.dart';
import '../../../../shared/attachments/models/attachment_kind.dart';
import '../../../../shared/attachments/models/attachment_viewer_item.dart';
import '../../../shared/formatters/health_display_formatters.dart';

class HealthAttachmentsSection extends StatelessWidget {
  const HealthAttachmentsSection({
    required this.attachments,
    this.formatAddedAt = formatHealthDateTime,
    super.key,
  });

  final List<HealthAttachment> attachments;
  final String Function(DateTime value) formatAddedAt;

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) {
      return const SizedBox.shrink();
    }

    final viewerItems = attachments
        .map(
          (attachment) => AttachmentViewerItem.fromAttachment(
            fileId: attachment.fileId,
            fileType: attachment.fileType,
            fileName: attachment.fileName,
            previewUrl: attachment.previewUrl,
            downloadUrl: attachment.downloadUrl,
          ),
        )
        .toList(growable: false);
    final imageItems = viewerItems
        .where((item) => item.kind == AttachmentKind.image && item.url != null)
        .toList(growable: false);

    return PawlyListSection(
      title: 'Вложения',
      children: List<Widget>.generate(attachments.length, (index) {
        final attachment = attachments[index];
        final viewerItem = viewerItems[index];
        final imageIndex = imageItems.indexWhere(
          (item) =>
              item.url == viewerItem.url && item.title == viewerItem.title,
        );

        return PawlyListTile(
          title: viewerItem.title,
          subtitle: attachment.addedAt == null
              ? attachment.fileType
              : '${attachment.fileType} • ${formatAddedAt(attachment.addedAt!)}',
          leadingIcon: switch (viewerItem.kind) {
            AttachmentKind.image => Icons.photo_rounded,
            AttachmentKind.pdf => Icons.picture_as_pdf_rounded,
            AttachmentKind.other => Icons.description_rounded,
          },
          onTap: () => openAttachmentUrl(
            context,
            fileId: attachment.fileId,
            fileType: attachment.fileType,
            fileName: viewerItem.title,
            previewUrl: attachment.previewUrl,
            downloadUrl: attachment.downloadUrl,
            imageGalleryItems: imageItems,
            initialImageIndex: imageIndex >= 0 ? imageIndex : null,
          ),
        );
      }),
    );
  }
}
