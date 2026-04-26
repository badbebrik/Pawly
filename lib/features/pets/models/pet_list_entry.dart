import '../../../core/network/models/pet_models.dart';
import 'pet_access_policy.dart';

class PetListEntry {
  const PetListEntry({
    required this.id,
    required this.pet,
    required this.name,
    required this.speciesName,
    required this.photoUrl,
    required this.roleTitle,
    required this.isOwnedByMe,
    required this.accessPolicy,
  });

  final String id;
  final Pet pet;
  final String name;
  final String speciesName;
  final String? photoUrl;
  final String roleTitle;
  final bool isOwnedByMe;
  final PetAccessPolicy accessPolicy;
}
