class LogMetricInputKind {
  const LogMetricInputKind._();

  static const numeric = 'NUMERIC';
  static const scale = 'SCALE';
  static const boolean = 'BOOLEAN';
}

class LogSort {
  const LogSort._();

  static const occurredAtAsc = 'occurred_at_asc';
  static const occurredAtDesc = 'occurred_at_desc';
}

class LogSource {
  const LogSource._();

  static const user = 'USER';
  static const health = 'HEALTH';
}

class LogTypeScope {
  const LogTypeScope._();

  static const system = 'SYSTEM';
}

class LogAttachmentEntityType {
  const LogAttachmentEntityType._();

  static const log = 'LOG';
}

const String noLogTypeSelectionId = '__none__';
