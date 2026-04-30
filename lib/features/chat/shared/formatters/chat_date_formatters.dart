import 'package:intl/intl.dart';

final DateFormat _inboxTimeFormat = DateFormat('HH:mm');
final DateFormat _inboxDateFormat = DateFormat('d MMM', 'ru');
final DateFormat _messageTimeFormat = DateFormat('HH:mm');
final DateFormat _messageDateFormat = DateFormat('d MMMM', 'ru');

String chatInboxTimestampLabel(DateTime? value) {
  if (value == null) {
    return '';
  }

  final local = value.toLocal();
  final now = DateTime.now();
  final sameDay = now.year == local.year &&
      now.month == local.month &&
      now.day == local.day;

  return sameDay
      ? _inboxTimeFormat.format(local)
      : _inboxDateFormat.format(local);
}

String chatMessageTimeLabel(DateTime? value) {
  if (value == null) {
    return '';
  }

  return _messageTimeFormat.format(value.toLocal());
}

String chatMessageDateLabel(DateTime value) {
  return _messageDateFormat.format(value.toLocal());
}
