import '../../../logs/models/log_models.dart';

String? findReminderLogTypeName(LogsBootstrap bootstrap, String logTypeId) {
  for (final type in _allReminderLogTypes(bootstrap)) {
    if (type.id == logTypeId) {
      return type.name;
    }
  }
  return null;
}

List<LogTypeItem> _allReminderLogTypes(LogsBootstrap bootstrap) {
  return <LogTypeItem>[
    ...bootstrap.recentLogTypes,
    ...bootstrap.systemLogTypes,
    ...bootstrap.customLogTypes,
  ];
}
