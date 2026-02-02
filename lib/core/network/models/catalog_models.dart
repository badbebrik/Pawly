import 'json_parsers.dart';

class CatalogVersionResponse {
  const CatalogVersionResponse({required this.version});
  final int version;

  factory CatalogVersionResponse.fromJson(Object? data) {
    final json = asJsonMap(data);
    return CatalogVersionResponse(version: asInt(json['version']));
  }
}

class SpeciesItem {
  const SpeciesItem({
    required this.id,
    required this.name,
    required this.isActive,
    required this.version,
  });

  final String id;
  final String name;
  final bool isActive;
  final int version;

  factory SpeciesItem.fromJson(Object? data) {
    final json = asJsonMap(data);
    return SpeciesItem(
      id: asString(json['id']),
      name: asString(json['name']),
      isActive: asBool(json['is_active']),
      version: asInt(json['version']),
    );
  }
}

class BreedItem {
  const BreedItem({
    required this.id,
    required this.speciesId,
    required this.name,
    required this.isActive,
    required this.version,
  });

  final String id;
  final String speciesId;
  final String name;
  final bool isActive;
  final int version;

  factory BreedItem.fromJson(Object? data) {
    final json = asJsonMap(data);
    return BreedItem(
      id: asString(json['id']),
      speciesId: asString(json['species_id']),
      name: asString(json['name']),
      isActive: asBool(json['is_active']),
      version: asInt(json['version']),
    );
  }
}

class ColorItem {
  const ColorItem({
    required this.id,
    required this.name,
    required this.hex,
    required this.isActive,
    required this.version,
  });

  final String id;
  final String name;
  final String hex;
  final bool isActive;
  final int version;

  factory ColorItem.fromJson(Object? data) {
    final json = asJsonMap(data);
    return ColorItem(
      id: asString(json['id']),
      name: asString(json['name']),
      hex: asString(json['hex']),
      isActive: asBool(json['is_active']),
      version: asInt(json['version']),
    );
  }
}

class PatternItem {
  const PatternItem({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.isActive,
    required this.version,
  });

  final String id;
  final String name;
  final String iconKey;
  final bool isActive;
  final int version;

  factory PatternItem.fromJson(Object? data) {
    final json = asJsonMap(data);
    return PatternItem(
      id: asString(json['id']),
      name: asString(json['name']),
      iconKey: asString(json['icon_key']),
      isActive: asBool(json['is_active']),
      version: asInt(json['version']),
    );
  }
}
