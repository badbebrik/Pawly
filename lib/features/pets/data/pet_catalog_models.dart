class PetCatalog {
  const PetCatalog({
    required this.version,
    required this.species,
    required this.breeds,
    required this.colors,
    required this.patterns,
  });

  final int version;
  final List<PetSpeciesOption> species;
  final List<PetBreedOption> breeds;
  final List<PetColorOption> colors;
  final List<PetCoatPatternOption> patterns;

  factory PetCatalog.fromJson(Map<String, dynamic> json) {
    return PetCatalog(
      version: (json['version'] as num?)?.toInt() ?? 0,
      species: (json['species'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map>()
          .map((e) => PetSpeciesOption.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false),
      breeds: (json['breeds'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map>()
          .map((e) => PetBreedOption.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false),
      colors: (json['colors'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map>()
          .map((e) => PetColorOption.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false),
      patterns: (json['patterns'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map>()
          .map((e) =>
              PetCoatPatternOption.fromJson(Map<String, dynamic>.from(e)))
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

class PetSpeciesOption {
  const PetSpeciesOption({
    required this.id,
    required this.name,
    required this.iconName,
  });

  final String id;
  final String name;
  final String iconName;

  factory PetSpeciesOption.fromJson(Map<String, dynamic> json) {
    return PetSpeciesOption(
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

class PetBreedOption {
  const PetBreedOption({
    required this.id,
    required this.speciesId,
    required this.name,
  });

  final String id;
  final String speciesId;
  final String name;

  factory PetBreedOption.fromJson(Map<String, dynamic> json) {
    return PetBreedOption(
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

class PetColorOption {
  const PetColorOption({
    required this.id,
    required this.name,
    required this.hex,
  });

  final String id;
  final String name;
  final String hex;

  factory PetColorOption.fromJson(Map<String, dynamic> json) {
    return PetColorOption(
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

class PetCoatPatternOption {
  const PetCoatPatternOption({
    required this.id,
    required this.name,
    required this.iconKey,
  });

  final String id;
  final String name;
  final String iconKey;

  factory PetCoatPatternOption.fromJson(Map<String, dynamic> json) {
    return PetCoatPatternOption(
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
