import '../../models/log_constants.dart';
import '../../models/log_models.dart';
import 'log_metric_formatters.dart';

String formatLogDateTime(DateTime? value, {String emptyLabel = 'Не указано'}) {
  if (value == null) {
    return emptyLabel;
  }

  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day.$month.${local.year} $hour:$minute';
}

String formatLogMetricValue(LogMetricItem value) {
  if (value.inputKind == LogMetricInputKind.boolean) {
    return value.valueNum == 0 ? 'Нет' : 'Да';
  }

  final number = value.valueNum % 1 == 0
      ? value.valueNum.toStringAsFixed(0)
      : value.valueNum.toStringAsFixed(1);
  final unit = formatDisplayUnitCode(value.unitCode);
  return unit.isEmpty ? number : '$number $unit';
}

String logSourceLabel(String source) {
  return switch (source) {
    LogSource.health => 'Из здоровья',
    LogSource.user => 'Пользовательская',
    _ => source,
  };
}

String? logListRelatedEntityLabel(LogListItem log) {
  final relatedType = log.sourceEntityType;
  if (relatedType == null || relatedType.isEmpty) {
    return null;
  }

  return switch (relatedType) {
    'VACCINATION' => 'Автоматическая запись вакцинации',
    'PROCEDURE' => 'Автоматическая запись процедуры',
    'VET_VISIT' => 'Связано с визитом',
    _ => 'Связано: $relatedType',
  };
}

String? logDetailsRelatedEntityLabel(LogDetails log) {
  final relatedType = log.sourceEntityType;
  if (relatedType == null || relatedType.isEmpty) {
    return null;
  }

  return switch (relatedType) {
    'VACCINATION' => 'Связано с вакцинацией',
    'PROCEDURE' => 'Связано с процедурой',
    'VET_VISIT' => 'Связано с визитом',
    _ => 'Связано: $relatedType',
  };
}

String formatLogAttachmentSubtitle(LogAttachmentItem attachment) {
  final type = attachment.fileType.startsWith('image/') ? 'Фото' : 'Документ';
  final addedAt = formatLogDateTime(attachment.addedAt);
  return '$type • $addedAt';
}
