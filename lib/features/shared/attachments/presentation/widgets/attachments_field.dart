import 'package:flutter/material.dart';

import '../../../../../design_system/design_system.dart';
import '../../formatters/attachment_formatters.dart';
import '../../models/attachment_kind.dart';
import '../../models/attachment_draft_item.dart';
import 'attachment_rename_dialog.dart';

typedef AttachmentRenameCallback = void Function(
    String fileId, String fileName);

class AttachmentsField extends StatelessWidget {
  const AttachmentsField({
    required this.attachments,
    required this.isUploading,
    required this.enabled,
    required this.onAddFiles,
    required this.onAddFromGallery,
    required this.onAddFromCamera,
    required this.onRemove,
    this.onRename,
    super.key,
  });

  final List<AttachmentDraftItem> attachments;
  final bool isUploading;
  final bool enabled;
  final VoidCallback onAddFiles;
  final VoidCallback onAddFromGallery;
  final VoidCallback onAddFromCamera;
  final ValueChanged<String> onRemove;
  final AttachmentRenameCallback? onRename;

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
                onPressed:
                    enabled ? () => _showAddAttachmentSheet(context) : null,
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
            'Поддерживаются PNG, JPEG и PDF. До 10 файлов, всего до 50 МБ. PDF до 25 МБ, фото до 15 МБ.',
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
                leading: Icon(switch (detectAttachmentKind(
                  fileType: attachment.mimeType,
                  fileName: attachment.fileName,
                )) {
                  AttachmentKind.image => Icons.photo_rounded,
                  AttachmentKind.pdf => Icons.picture_as_pdf_rounded,
                  AttachmentKind.other => Icons.description_rounded,
                }),
                title: Text(attachment.fileName),
                subtitle: Text(
                  attachment.sizeBytes > 0
                      ? attachmentSizeLabel(attachment.sizeBytes)
                      : attachmentTypeLabel(
                          attachment.mimeType,
                          fileName: attachment.fileName,
                        ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    IconButton(
                      onPressed: enabled && onRename != null
                          ? () => _renameAttachment(context, attachment)
                          : null,
                      icon: const Icon(Icons.edit_rounded),
                      tooltip: 'Переименовать',
                    ),
                    IconButton(
                      onPressed:
                          enabled ? () => onRemove(attachment.fileId) : null,
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Убрать',
                    ),
                  ],
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

  Future<void> _renameAttachment(
    BuildContext context,
    AttachmentDraftItem attachment,
  ) async {
    final newName = await showAttachmentRenameDialog(
      context,
      initialName: attachment.fileName,
    );
    if (newName == null || newName == attachment.fileName) {
      return;
    }
    onRename?.call(attachment.fileId, newName);
  }
}
