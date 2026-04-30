import 'acl_permission.dart';

class AclInvitePreview {
  const AclInvitePreview({
    required this.pet,
    required this.roleTitle,
    required this.code,
    required this.expiresAt,
    required this.permissions,
  });

  final AclInvitePet pet;
  final String roleTitle;
  final String code;
  final DateTime? expiresAt;
  final AclPermissionDraft permissions;
}

class AclInvitePet {
  const AclInvitePet({
    required this.id,
    required this.name,
    required this.photoUrl,
  });

  final String id;
  final String name;
  final String? photoUrl;

  String get displayName => name.isEmpty ? 'Питомец' : name;
}

class AclAcceptedInvite {
  const AclAcceptedInvite({
    required this.petId,
    required this.roleTitle,
  });

  final String petId;
  final String roleTitle;
}
