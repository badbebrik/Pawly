import 'acl_permission.dart';

class AclMember {
  const AclMember({
    required this.id,
    required this.petId,
    required this.userId,
    required this.status,
    required this.isPrimaryOwner,
    required this.roleId,
    required this.roleCode,
    required this.roleTitle,
    required this.permissions,
    required this.profile,
  });

  final String id;
  final String petId;
  final String userId;
  final String status;
  final bool isPrimaryOwner;
  final String roleId;
  final String? roleCode;
  final String roleTitle;
  final AclPermissionDraft permissions;
  final AclMemberProfile? profile;

  bool get isActive => status == 'ACTIVE';

  String get displayName {
    final resolvedProfile = profile;
    if (resolvedProfile == null) {
      return 'Участник';
    }
    return resolvedProfile.displayName;
  }
}

class AclMemberProfile {
  const AclMemberProfile({
    required this.firstName,
    required this.lastName,
    required this.displayNameValue,
    required this.avatarUrl,
  });

  final String? firstName;
  final String? lastName;
  final String? displayNameValue;
  final String? avatarUrl;

  String get displayName {
    final first = firstName?.trim() ?? '';
    final last = lastName?.trim() ?? '';
    final fullName = '$first $last'.trim();
    if (fullName.isNotEmpty) {
      return fullName;
    }

    final fallback = displayNameValue?.trim();
    if (fallback != null && fallback.isNotEmpty) {
      return fallback;
    }

    return 'Участник';
  }
}
