class PetAccessPolicy {
  const PetAccessPolicy({required this.permissions});

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

const Map<String, bool> ownerPetPermissions = <String, bool>{
  'pet_read': true,
  'pet_write': true,
  'log_read': true,
  'log_write': true,
  'health_read': true,
  'health_write': true,
  'members_read': true,
  'members_write': true,
};
