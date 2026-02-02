class CatalogSnapshot {
  const CatalogSnapshot({
    required this.version,
    required this.species,
    required this.breeds,
    required this.colors,
    required this.patterns,
  });

  final int version;
  final List<CatalogOption> species;
  final List<CatalogBreedOption> breeds;
  final List<CatalogColorOption> colors;
  final List<CatalogPatternOption> patterns;

  factory CatalogSnapshot.fromJson(Map<String, dynamic> json) {
    return CatalogSnapshot(
      version: (json['version'] as num?)?.toInt() ?? 0,
      species: (json['species'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map>()
          .map((e) => CatalogOption.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false),
      breeds: (json['breeds'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map>()
          .map((e) => CatalogBreedOption.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false),
      colors: (json['colors'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map>()
          .map((e) => CatalogColorOption.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false),
      patterns: (json['patterns'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map>()
          .map((e) => CatalogPatternOption.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'version': version,
      'species': species.map((e) => e.toJson()).toList(growable: false),
      'breeds': breeds.map((e) => e.toJson()).toList(growable: false),
      'colors': colors.map((e) => e.toJson()).toList(growable: false),
      'patterns': patterns.map((e) => e.toJson()).toList(growable: false),
    };
  }
}

class CatalogOption {
  const CatalogOption({
    required this.id,
    required this.name,
    required this.iconName,
  });

  final String id;
  final String name;
  final String iconName;

  factory CatalogOption.fromJson(Map<String, dynamic> json) {
    return CatalogOption(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      iconName: json['icon_name']?.toString() ?? 'paw',
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'icon_name': iconName,
      };
}

class CatalogBreedOption {
  const CatalogBreedOption({
    required this.id,
    required this.speciesId,
    required this.name,
  });

  final String id;
  final String speciesId;
  final String name;

  factory CatalogBreedOption.fromJson(Map<String, dynamic> json) {
    return CatalogBreedOption(
      id: json['id']?.toString() ?? '',
      speciesId: json['species_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'species_id': speciesId,
        'name': name,
      };
}

class CatalogColorOption {
  const CatalogColorOption({
    required this.id,
    required this.name,
    required this.hex,
  });

  final String id;
  final String name;
  final String hex;

  factory CatalogColorOption.fromJson(Map<String, dynamic> json) {
    return CatalogColorOption(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      hex: json['hex']?.toString() ?? '#000000',
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'hex': hex,
      };
}

class CatalogPatternOption {
  const CatalogPatternOption({
    required this.id,
    required this.name,
    required this.iconKey,
  });

  final String id;
  final String name;
  final String iconKey;

  factory CatalogPatternOption.fromJson(Map<String, dynamic> json) {
    return CatalogPatternOption(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      iconKey: json['icon_key']?.toString() ?? 'pattern_default',
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'icon_key': iconKey,
      };
}
