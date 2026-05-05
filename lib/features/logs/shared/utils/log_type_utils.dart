import '../../models/log_models.dart';

class LogTypeGroups {
  const LogTypeGroups({
    required this.recent,
    required this.system,
    required this.custom,
    required this.all,
  });

  final List<LogTypeItem> recent;
  final List<LogTypeItem> system;
  final List<LogTypeItem> custom;
  final List<LogTypeItem> all;
}

List<LogTypeItem> uniqueLogTypes(Iterable<LogTypeItem> types) {
  final result = <LogTypeItem>[];
  final seenIds = <String>{};

  for (final type in types) {
    if (seenIds.add(type.id)) {
      result.add(type);
    }
  }

  return result;
}

List<LogTypeItem> allBootstrapLogTypes(LogsBootstrap bootstrap) {
  return groupedBootstrapLogTypes(bootstrap).all;
}

LogTypeGroups groupedBootstrapLogTypes(LogsBootstrap bootstrap) {
  final seenIds = <String>{};

  List<LogTypeItem> uniqueGroup(List<LogTypeItem> types) {
    final result = <LogTypeItem>[];
    for (final type in types) {
      if (seenIds.add(type.id)) {
        result.add(type);
      }
    }
    return result;
  }

  final recent = uniqueGroup(bootstrap.recentLogTypes);
  final system = uniqueGroup(bootstrap.systemLogTypes);
  final custom = uniqueGroup(bootstrap.customLogTypes);

  return LogTypeGroups(
    recent: recent,
    system: system,
    custom: custom,
    all: <LogTypeItem>[...recent, ...system, ...custom],
  );
}

LogTypeItem? findLogTypeById(
  Iterable<LogTypeItem> types,
  String? typeId,
) {
  if (typeId == null) {
    return null;
  }
  for (final type in types) {
    if (type.id == typeId) {
      return type;
    }
  }
  return null;
}
