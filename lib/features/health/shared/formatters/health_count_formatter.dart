String formatHealthRecordsCount(int count, {required bool hasMore}) {
  if (count == 0) {
    return 'Пока пусто';
  }

  if (hasMore) {
    return '$count+ ${_recordsWord(count)}';
  }

  return '$count ${_recordsWord(count)}';
}

bool hasHealthNextPage(String? nextCursor) {
  return nextCursor != null && nextCursor.isNotEmpty;
}

String _recordsWord(int value) {
  final mod10 = value % 10;
  final mod100 = value % 100;

  if (mod10 == 1 && mod100 != 11) {
    return 'запись';
  }

  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
    return 'записи';
  }

  return 'записей';
}
