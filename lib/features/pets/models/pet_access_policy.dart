import '../../../core/network/models/acl_models.dart';

class PetAccessPolicy {
  const PetAccessPolicy({required this.permissions});

  factory PetAccessPolicy.fromAclPolicy(
    AclPolicy? policy, {
    required bool isOwner,
  }) {
    if (policy != null) {
      return PetAccessPolicy(permissions: policy.permissions);
    }

    if (isOwner) {
      return const PetAccessPolicy(permissions: _ownerPermissions);
    }

    return const PetAccessPolicy(permissions: <String, bool>{});
  }

  static const Map<String, bool> _ownerPermissions = <String, bool>{
    'pet_read': true,
    'pet_write': true,
    'log_read': true,
    'log_write': true,
    'health_read': true,
    'health_write': true,
    'members_read': true,
    'members_write': true,
  };

  final Map<String, bool> permissions;

  bool can(String permission) => permissions[permission] == true;

  bool get petRead => can('pet_read');
  bool get petWrite => can('pet_write');
  bool get logRead => can('log_read');
  bool get logWrite => can('log_write');
  bool get healthRead => can('health_read');
  bool get healthWrite => can('health_write');
  bool get membersRead => can('members_read');
  bool get membersWrite => can('members_write');

  bool get remindersRead => petRead || logRead || healthRead;
  bool get remindersWrite => petWrite || logWrite || healthWrite;
  bool get documentsRead => healthRead;

  bool canWriteScheduledSource(String sourceType) {
    return switch (sourceType) {
      'MANUAL' || 'PET_EVENT' => petWrite,
      'LOG_TYPE' => logWrite,
      'VET_VISIT' || 'VACCINATION' || 'PROCEDURE' => healthWrite,
      _ => false,
    };
  }
}
