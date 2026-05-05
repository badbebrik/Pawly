import '../../../shared/attachments/models/attachment_kind.dart';
import '../../models/document_item.dart';

String documentMetaLabel(DocumentItem document) {
  final parts = <String>[
    documentFileTypeLabel(document.fileType),
    if (document.addedAt != null) documentDateLabel(document.addedAt!),
  ];
  return parts.join(' • ');
}

String documentEntityLabel(String entityType) {
  return switch (entityType.trim().toLowerCase()) {
    'log' => 'Запись',
    'vet_visit' => 'Визит',
    'vaccination' => 'Вакцинация',
    'procedure' => 'Процедура',
    'medical_record' => 'Медкарта',
    _ => 'Документ',
  };
}

String documentOpenEntityLabel(String entityType) {
  return switch (entityType.trim().toLowerCase()) {
    'log' => 'К записи',
    'vet_visit' => 'К визиту',
    'vaccination' => 'К вакцинации',
    'procedure' => 'К процедуре',
    'medical_record' => 'К медкарте',
    _ => 'К сущности',
  };
}

String documentFileTypeLabel(String fileType) {
  return switch (detectAttachmentKind(fileType: fileType)) {
    AttachmentKind.image => 'Изображение',
    AttachmentKind.pdf => 'PDF',
    AttachmentKind.other => 'Файл',
  };
}

String documentDateLabel(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day.$month.${value.year}';
}

String documentsCountLabel(int count, String? nextCursor) {
  if (count == 0) {
    return 'Пока пусто';
  }

  final hasMore = nextCursor != null && nextCursor.isNotEmpty;
  if (hasMore) {
    return '$count+ ${_documentsWord(count)}';
  }

  return '$count ${_documentsWord(count)}';
}

String documentErrorMessage(Object error, String fallback) {
  final text = error.toString().trim();
  if (text.isEmpty || text == 'null') {
    return fallback;
  }
  return text;
}

String _documentsWord(int value) {
  final mod10 = value % 10;
  final mod100 = value % 100;

  if (mod10 == 1 && mod100 != 11) {
    return 'файл';
  }

  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
    return 'файла';
  }

  return 'файлов';
}
