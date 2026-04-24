import 'json_map.dart';
import 'json_parsers.dart';

class PetDictionariesResponse {
  const PetDictionariesResponse({
    required this.species,
    required this.breeds,
    required this.patterns,
    required this.colorPresets,
  });

  final List<SpeciesDictionaryItem> species;
  final List<BreedDictionaryItem> breeds;
  final List<PatternDictionaryItem> patterns;
  final List<ColorPresetDictionaryItem> colorPresets;

  factory PetDictionariesResponse.fromJson(Object? data) {
    final json = asJsonMap(data);

    return PetDictionariesResponse(
      species: asJsonMapList(json['species'])
          .map(SpeciesDictionaryItem.fromJson)
          .toList(growable: false),
      breeds: asJsonMapList(json['breeds'])
          .map(BreedDictionaryItem.fromJson)
          .toList(growable: false),
      patterns: asJsonMapList(json['patterns'])
          .map(PatternDictionaryItem.fromJson)
          .toList(growable: false),
      colorPresets: asJsonMapList(json['color_presets'])
          .map(ColorPresetDictionaryItem.fromJson)
          .toList(growable: false),
    );
  }

  int get version {
    var hash = 0x811C9DC5;

    void add(String value) {
      for (final codeUnit in value.codeUnits) {
        hash ^= codeUnit;
        hash = (hash * 0x01000193) & 0x7fffffff;
      }
    }

    for (final item in species) {
      add(item.id);
      add(item.code);
      add(item.nameRu);
      add(item.nameEn);
      add(item.iconKey);
      add(item.sortOrder.toString());
      add(item.isActive.toString());
    }

    for (final item in breeds) {
      add(item.id);
      add(item.speciesId);
      add(item.nameRu);
      add(item.nameEn);
      add(item.sortOrder.toString());
      add(item.isActive.toString());
    }

    for (final item in patterns) {
      add(item.id);
      add(item.speciesId ?? '');
      add(item.nameRu);
      add(item.nameEn);
      add(item.iconKey ?? '');
      add(item.sortOrder.toString());
      add(item.isActive.toString());
    }

    for (final item in colorPresets) {
      add(item.id);
      add(item.nameRu);
      add(item.nameEn);
      add(item.hex);
      add(item.sortOrder.toString());
      add(item.isActive.toString());
    }

    return hash == 0 ? 1 : hash;
  }
}

class SpeciesDictionaryItem {
  const SpeciesDictionaryItem({
    required this.id,
    required this.code,
    required this.nameRu,
    required this.nameEn,
    required this.iconKey,
    required this.sortOrder,
    required this.isActive,
  });

  final String id;
  final String code;
  final String nameRu;
  final String nameEn;
  final String iconKey;
  final int sortOrder;
  final bool isActive;

  factory SpeciesDictionaryItem.fromJson(Object? data) {
    final json = asJsonMap(data);

    return SpeciesDictionaryItem(
      id: asString(json['id'], fallback: asString(json['code'])),
      code: asString(json['code'], fallback: asString(json['id'])),
      nameRu: _readLocalizedName(json, primaryKey: 'name_ru'),
      nameEn: _readLocalizedName(json, primaryKey: 'name_en'),
      iconKey: asString(json['icon_key'], fallback: 'paw'),
      sortOrder: asInt(json['sort_order']),
      isActive: asBool(json['is_active'], fallback: asBool(json['active'])),
    );
  }

  String localizedName({String? locale}) {
    return _pickLocalizedName(nameRu: nameRu, nameEn: nameEn, locale: locale);
  }
}

class BreedDictionaryItem {
  const BreedDictionaryItem({
    required this.id,
    required this.speciesId,
    required this.nameRu,
    required this.nameEn,
    required this.sortOrder,
    required this.isActive,
  });

  final String id;
  final String speciesId;
  final String nameRu;
  final String nameEn;
  final int sortOrder;
  final bool isActive;

  factory BreedDictionaryItem.fromJson(Object? data) {
    final json = asJsonMap(data);

    return BreedDictionaryItem(
      id: asString(json['id']),
      speciesId: asString(json['species_id']),
      nameRu: _readLocalizedName(json, primaryKey: 'name_ru'),
      nameEn: _readLocalizedName(json, primaryKey: 'name_en'),
      sortOrder: asInt(json['sort_order']),
      isActive: asBool(json['is_active']),
    );
  }

  String localizedName({String? locale}) {
    return _pickLocalizedName(nameRu: nameRu, nameEn: nameEn, locale: locale);
  }
}

class PatternDictionaryItem {
  const PatternDictionaryItem({
    required this.id,
    required this.speciesId,
    required this.nameRu,
    required this.nameEn,
    required this.iconKey,
    required this.sortOrder,
    required this.isActive,
  });

  final String id;
  final String? speciesId;
  final String nameRu;
  final String nameEn;
  final String? iconKey;
  final int sortOrder;
  final bool isActive;

  factory PatternDictionaryItem.fromJson(Object? data) {
    final json = asJsonMap(data);

    return PatternDictionaryItem(
      id: asString(json['id']),
      speciesId: asNullableString(json['species_id']),
      nameRu: _readLocalizedName(json, primaryKey: 'name_ru'),
      nameEn: _readLocalizedName(json, primaryKey: 'name_en'),
      iconKey: asNullableString(json['icon_key']),
      sortOrder: asInt(json['sort_order']),
      isActive: asBool(json['is_active']),
    );
  }

  String localizedName({String? locale}) {
    return _pickLocalizedName(nameRu: nameRu, nameEn: nameEn, locale: locale);
  }
}

class ColorPresetDictionaryItem {
  const ColorPresetDictionaryItem({
    required this.id,
    required this.nameRu,
    required this.nameEn,
    required this.hex,
    required this.sortOrder,
    required this.isActive,
  });

  final String id;
  final String nameRu;
  final String nameEn;
  final String hex;
  final int sortOrder;
  final bool isActive;

  factory ColorPresetDictionaryItem.fromJson(Object? data) {
    final json = asJsonMap(data);

    return ColorPresetDictionaryItem(
      id: asString(json['id']),
      nameRu: _readLocalizedName(json, primaryKey: 'name_ru'),
      nameEn: _readLocalizedName(json, primaryKey: 'name_en'),
      hex: asString(json['hex']),
      sortOrder: asInt(json['sort_order']),
      isActive: asBool(json['is_active']),
    );
  }

  String localizedName({String? locale}) {
    return _pickLocalizedName(nameRu: nameRu, nameEn: nameEn, locale: locale);
  }
}

String _readLocalizedName(JsonMap json, {required String primaryKey}) {
  final localized = asString(json[primaryKey]);
  if (localized.isNotEmpty) {
    return localized;
  }

  return asString(json['name']);
}

String _pickLocalizedName({
  required String nameRu,
  required String nameEn,
  String? locale,
}) {
  final normalized = (locale ?? 'ru').toLowerCase();

  if (normalized.startsWith('en')) {
    return nameEn.isNotEmpty ? nameEn : nameRu;
  }

  return nameRu.isNotEmpty ? nameRu : nameEn;
}
