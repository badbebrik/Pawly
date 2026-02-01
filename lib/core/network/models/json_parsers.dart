import 'json_map.dart';

JsonMap asJsonMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map(
      (dynamic key, dynamic val) => MapEntry(key.toString(), val),
    );
  }
  return <String, dynamic>{};
}

List<JsonMap> asJsonMapList(Object? value) {
  if (value is! List) {
    return const <JsonMap>[];
  }

  return value.map(asJsonMap).toList(growable: false);
}

String asString(Object? value, {String fallback = ''}) {
  if (value == null) {
    return fallback;
  }
  return value.toString();
}

String? asNullableString(Object? value) {
  if (value == null) {
    return null;
  }
  final string = value.toString();
  return string.isEmpty ? null : string;
}

int asInt(Object? value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? fallback;
  }
  return fallback;
}

bool asBool(Object? value, {bool fallback = false}) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  if (value is String) {
    return value.toLowerCase() == 'true' || value == '1';
  }
  return fallback;
}

DateTime? asDateTime(Object? value) {
  if (value is! String || value.isEmpty) {
    return null;
  }

  return DateTime.tryParse(value);
}

Map<String, String> asStringMap(Object? value) {
  if (value is! Map) {
    return const <String, String>{};
  }

  return value.map(
    (dynamic key, dynamic val) => MapEntry(key.toString(), val.toString()),
  );
}
