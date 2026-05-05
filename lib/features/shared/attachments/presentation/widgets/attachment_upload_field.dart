import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/providers/core_providers.dart';
import '../../../../../design_system/design_system.dart';
import '../../data/attachment_upload_service.dart';
import '../../data/attachment_upload_service_provider.dart';
import '../../models/attachment_draft_item.dart';
import '../../utils/attachment_limits.dart';
import 'attachments_field.dart';

class AttachmentUploadField extends ConsumerStatefulWidget {
  const AttachmentUploadField({
    required this.petId,
    required this.entityType,
    required this.attachments,
    required this.isUploading,
    required this.enabled,
    required this.onChanged,
    required this.onUploadingChanged,
    super.key,
  });

  final String petId;
  final String entityType;
  final List<AttachmentDraftItem> attachments;
  final bool isUploading;
  final bool enabled;
  final ValueChanged<List<AttachmentDraftItem>> onChanged;
  final ValueChanged<bool> onUploadingChanged;

  @override
  ConsumerState<AttachmentUploadField> createState() =>
      _AttachmentUploadFieldState();
}

class _AttachmentUploadFieldState extends ConsumerState<AttachmentUploadField> {
  @override
  Widget build(BuildContext context) {
    return AttachmentsField(
      attachments: widget.attachments,
      isUploading: widget.isUploading,
      enabled: widget.enabled && !widget.isUploading,
      onAddFiles: _pickAndUploadFiles,
      onAddFromGallery: _pickAndUploadFromGallery,
      onAddFromCamera: _pickAndUploadFromCamera,
      onRemove: _removeAttachment,
      onRename: _renameAttachment,
    );
  }

  Future<void> _pickAndUploadFiles() async {
    final List<PlatformFile> files;
    try {
      files = await ref.read(mediaPickerServiceProvider).pickFiles(
            allowedExtensions: AttachmentUploadService.supportedExtensions,
          );
    } catch (error) {
      if (mounted) {
        _showError(_errorMessage(error, 'Не удалось выбрать файлы.'));
      }
      return;
    }

    if (files.isEmpty || !mounted) {
      return;
    }

    try {
      await validatePlatformAttachments(
        existingAttachments: widget.attachments,
        files: files,
      );
    } catch (error) {
      if (mounted) {
        _showError(_errorMessage(error, 'Не удалось добавить файлы.'));
      }
      return;
    }

    _setUploading(true);
    try {
      final uploaded =
          await ref.read(attachmentUploadServiceProvider).uploadFiles(
                widget.petId,
                files: files,
                entityType: widget.entityType,
              );
      if (!mounted) {
        return;
      }
      widget.onChanged(<AttachmentDraftItem>[
        ...widget.attachments,
        ...uploaded.map(AttachmentDraftItem.fromUploaded),
      ]);
    } catch (error) {
      if (mounted) {
        _showError(_errorMessage(error, 'Не удалось загрузить файлы.'));
      }
    } finally {
      if (mounted) {
        _setUploading(false);
      }
    }
  }

  Future<void> _pickAndUploadFromGallery() async {
    final List<XFile> files;
    try {
      files = await ref
          .read(mediaPickerServiceProvider)
          .pickAttachmentImagesFromGallery();
    } catch (error) {
      if (mounted) {
        _showError(_errorMessage(error, 'Не удалось выбрать фото.'));
      }
      return;
    }

    if (files.isEmpty || !mounted) {
      return;
    }
    await _uploadPickedImages(files);
  }

  Future<void> _pickAndUploadFromCamera() async {
    final XFile? file;
    try {
      file = await ref.read(mediaPickerServiceProvider).takeAttachmentPhoto();
    } catch (error) {
      if (mounted) {
        _showError(_errorMessage(error, 'Не удалось сделать фото.'));
      }
      return;
    }

    if (file == null || !mounted) {
      return;
    }
    await _uploadPickedImages(<XFile>[file]);
  }

  Future<void> _uploadPickedImages(List<XFile> files) async {
    try {
      await validateXFileAttachments(
        existingAttachments: widget.attachments,
        files: files,
      );
    } catch (error) {
      if (mounted) {
        _showError(_errorMessage(error, 'Не удалось добавить фото.'));
      }
      return;
    }

    _setUploading(true);
    try {
      final uploaded =
          await ref.read(attachmentUploadServiceProvider).uploadXFiles(
                widget.petId,
                files: files,
                entityType: widget.entityType,
              );
      if (!mounted) {
        return;
      }
      widget.onChanged(<AttachmentDraftItem>[
        ...widget.attachments,
        ...uploaded.map(AttachmentDraftItem.fromUploaded),
      ]);
    } catch (error) {
      if (mounted) {
        _showError(_errorMessage(error, 'Не удалось загрузить файлы.'));
      }
    } finally {
      if (mounted) {
        _setUploading(false);
      }
    }
  }

  void _removeAttachment(String fileId) {
    widget.onChanged(
      widget.attachments
          .where((attachment) => attachment.fileId != fileId)
          .toList(growable: false),
    );
  }

  void _renameAttachment(String fileId, String fileName) {
    widget.onChanged(
      widget.attachments
          .map(
            (attachment) => attachment.fileId == fileId
                ? attachment.copyWith(fileName: fileName)
                : attachment,
          )
          .toList(growable: false),
    );
  }

  void _setUploading(bool value) {
    widget.onUploadingChanged(value);
  }

  void _showError(String message) {
    showPawlySnackBar(
      context,
      message: message,
      tone: PawlySnackBarTone.error,
    );
  }

  String _errorMessage(Object error, String fallback) {
    if (error is StateError) {
      return error.message.toString();
    }
    return fallback;
  }
}
