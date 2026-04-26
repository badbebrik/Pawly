import '../../data/pet_catalog_models.dart';

String petSpeciesEmoji(PetSpeciesOption option) {
  final iconKey = option.iconName.trim().toLowerCase().replaceAll('-', '_');

  switch (iconKey) {
    case 'dog':
      return '🐕';
    case 'cat':
      return '🐈';
    case 'parrot':
      return '🦜';
    case 'rabbit':
      return '🐇';
    case 'hamster':
      return '🐹';
    case 'rat':
      return '🐀';
    case 'mouse':
      return '🐁';
    case 'lizard':
      return '🦎';
    case 'snake':
      return '🐍';
    case 'horse':
      return '🐎';
    case 'bird':
      return '🐦';
  }

  return '🐾';
}
