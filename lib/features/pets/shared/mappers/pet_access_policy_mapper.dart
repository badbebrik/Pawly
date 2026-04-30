import '../../../../core/network/models/acl_models.dart';
import '../../models/pet_access_policy.dart';

PetAccessPolicy petAccessPolicyFromAclPolicy(
  AclPolicy? policy, {
  required bool isOwner,
}) {
  if (policy != null) {
    return PetAccessPolicy(permissions: policy.permissions);
  }

  if (isOwner) {
    return const PetAccessPolicy(permissions: ownerPetPermissions);
  }

  return const PetAccessPolicy(permissions: <String, bool>{});
}
