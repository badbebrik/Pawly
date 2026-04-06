import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../models/attachment_kind.dart';
import '../models/attachment_draft_item.dart';

class HealthAttachmentsField extends StatelessWidget {
  const HealthAttachmentsField({
    required this.attachments,
    required this.isUploading,
    required this.enabled,
    required this.onAddFiles,
    required this.onAddFromGallery,
    required this.onAddFromCamera,
    required this.onRemove,
    super.key,
  });

  final List<AttachmentDraftItem> attachments;
  final bool isUploading;
  final bool enabled;
  final VoidCallback onAddFiles;
  final VoidCallback onAddFromGallery;
  final VoidCallback onAddFromCamera;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return PawlyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Вложения',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              TextButton.icon(
                onPressed: enabled ? () => _showAddAttachmentSheet(context) : null,
                icon: isUploading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.attach_file_rounded),
                label: Text(isUploading ? 'Загрузка...' : 'Добавить'),
              ),
            ],
          ),
          const SizedBox(height: PawlySpacing.xs),
          Text(
            'Поддерживаются JPG, PNG, WEBP, HEIC, HEIF и PDF.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          if (attachments.isEmpty) ...<Widget>[
            const SizedBox(height: PawlySpacing.sm),
            Text(
              'Файлы не добавлены.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ] else ...<Widget>[
            const SizedBox(height: PawlySpacing.md),
            ...attachments.map(
              (attachment) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  switch (
                    detectAttachmentKind(
                      fileType: attachment.mimeType,
                      fileName: attachment.fileName,
                    )
                  ) {
                    AttachmentKind.image => Icons.photo_rounded,
                    AttachmentKind.pdf => Icons.picture_as_pdf_rounded,
                    AttachmentKind.other => Icons.description_rounded,
                  },
                ),
                title: Text(attachment.fileName),
                subtitle: Text(
                  attachment.sizeBytes > 0
                      ? formatAttachmentSize(attachment.sizeBytes)
                      : attachmentTypeLabel(
                          attachment.mimeType,
                          fileName: attachment.fileName,
                        ),
                ),
                trailing: IconButton(
                  onPressed: enabled ? () => onRemove(attachment.fileId) : null,
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Убрать',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showAddAttachmentSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: PawlySpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.folder_rounded),
                title: const Text('Файлы'),
                onTap: () {
                  Navigator.of(context).pop();
                  onAddFiles();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Фото из галереи'),
                onTap: () {
                  Navigator.of(context).pop();
                  onAddFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded),
                title: const Text('Сделать фото'),
                onTap: () {
                  Navigator.of(context).pop();
                  onAddFromCamera();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String attachmentTypeLabel(String mimeType, {String? fileName}) {
  return switch (
    detectAttachmentKind(fileType: mimeType, fileName: fileName)
  ) {
    AttachmentKind.image => 'Фото',
    AttachmentKind.pdf => 'PDF',
    AttachmentKind.other => 'Документ',
  };
}

String formatAttachmentSize(int sizeBytes) {
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
