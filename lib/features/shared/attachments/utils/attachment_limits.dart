import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import '../models/attachment_draft_item.dart';

const int maxAttachmentCount = 10;
const int maxAttachmentsTotalBytes = 50 * 1024 * 1024;
const int maxPdfAttachmentBytes = 25 * 1024 * 1024;
const int maxImageAttachmentBytes = 15 * 1024 * 1024;

Future<void> validatePlatformAttachments({
  required List<AttachmentDraftItem> existingAttachments,
  required List<PlatformFile> files,
}) async {
  final candidates = files
      .map(
        (file) => _PendingAttachment(fileName: file.name, sizeBytes: file.size),
      )
      .toList(growable: false);
  _validatePendingAttachments(
    existingAttachments: existingAttachments,
    candidates: candidates,
  );
}

Future<void> validateXFileAttachments({
  required List<AttachmentDraftItem> existingAttachments,
  required List<XFile> files,
}) async {
  final candidates = <_PendingAttachment>[];
  for (final file in files) {
    candidates.add(
      _PendingAttachment(
        fileName: _xFileName(file),
        sizeBytes: await file.length(),
      ),
    );
  }
  _validatePendingAttachments(
    existingAttachments: existingAttachments,
    candidates: candidates,
  );
}

void _validatePendingAttachments({
  required List<AttachmentDraftItem> existingAttachments,
  required List<_PendingAttachment> candidates,
}) {
  if (existingAttachments.length + candidates.length > maxAttachmentCount) {
    throw StateError('Можно добавить не больше 10 файлов.');
  }

  for (final candidate in candidates) {
    final type = _supportedAttachmentType(candidate.fileName);
    if (type == null) {
      throw StateError('Поддерживаются только PNG, JPEG и PDF.');
    }

    if (type == _SupportedAttachmentType.pdf &&
        candidate.sizeBytes > maxPdfAttachmentBytes) {
      throw StateError('PDF должен быть не больше 25 МБ.');
    }

    if (type == _SupportedAttachmentType.image &&
        candidate.sizeBytes > maxImageAttachmentBytes) {
      throw StateError('Фото должно быть не больше 15 МБ.');
    }
  }

  final existingTotal = existingAttachments.fold<int>(
    0,
    (sum, attachment) => sum + attachment.sizeBytes,
  );
  final pendingTotal = candidates.fold<int>(
    0,
    (sum, attachment) => sum + attachment.sizeBytes,
  );
  if (existingTotal + pendingTotal > maxAttachmentsTotalBytes) {
    throw StateError('Суммарный объём вложений должен быть не больше 50 МБ.');
  }
}

_SupportedAttachmentType? _supportedAttachmentType(String fileName) {
  final lower = fileName.trim().toLowerCase();
  if (lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.png')) {
    return _SupportedAttachmentType.image;
  }
  if (lower.endsWith('.pdf')) {
    return _SupportedAttachmentType.pdf;
  }
  return null;
}

String _xFileName(XFile file) {
  if (file.name.trim().isNotEmpty) {
    return file.name.trim();
  }
  final segments = file.path.replaceAll('\\', '/').split('/');
  return segments.isEmpty ? 'attachment' : segments.last;
}

class _PendingAttachment {
  const _PendingAttachment({required this.fileName, required this.sizeBytes});

  final String fileName;
  final int sizeBytes;
}

enum _SupportedAttachmentType { image, pdf }
