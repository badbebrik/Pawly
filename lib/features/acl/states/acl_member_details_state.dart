import '../models/acl_access.dart';
import '../models/acl_member.dart';
import '../models/acl_permission.dart';
import '../models/acl_role_option.dart';

class AclMemberDetailsState {
  const AclMemberDetailsState({
    required this.petId,
    required this.me,
    required this.capabilities,
    required this.member,
    required this.roles,
    required this.presets,
    required this.selectedRoleId,
    required this.selectedPresetId,
    required this.permissions,
    required this.isSubmitting,
  });

  factory AclMemberDetailsState.initial({
    required String petId,
    required AclMember me,
    required AclAccessCapabilities capabilities,
    required AclMember member,
    required List<AclRoleOption> roles,
    required List<AclPresetOption> presets,
  }) {
    final preset = _presetForRole(presets, member.roleCode);
    return AclMemberDetailsState(
      petId: petId,
      me: me,
      capabilities: capabilities,
      member: member,
      roles: roles,
      presets: presets,
      selectedRoleId: member.roleId,
      selectedPresetId: preset?.id,
      permissions: member.permissions,
      isSubmitting: false,
    );
  }

  final String petId;
  final AclMember me;
  final AclAccessCapabilities capabilities;
  final AclMember member;
  final List<AclRoleOption> roles;
  final List<AclPresetOption> presets;
  final String? selectedRoleId;
  final String? selectedPresetId;
  final AclPermissionDraft permissions;
  final bool isSubmitting;

  List<AclRoleOption> get systemRoles {
    return roles.where((role) {
      return role.isSystem && !role.isOwner;
    }).toList(growable: false);
  }

  List<AclRoleOption> get customRoles {
    return roles.where((role) => role.isCustom).toList(growable: false);
  }

  AclRoleOption? roleById(String? roleId) {
    if (roleId == null || roleId.isEmpty) {
      return null;
    }

    for (final role in roles) {
      if (role.id == roleId) {
        return role;
      }
    }

    return null;
  }

  AclPresetOption? presetForRole(AclRoleOption role) {
    return _presetForRole(presets, role.code);
  }

  AclMemberDetailsState copyWith({
    AclMember? me,
    AclAccessCapabilities? capabilities,
    AclMember? member,
    List<AclRoleOption>? roles,
    List<AclPresetOption>? presets,
    String? selectedRoleId,
    String? selectedPresetId,
    AclPermissionDraft? permissions,
    bool? isSubmitting,
  }) {
    return AclMemberDetailsState(
      petId: petId,
      me: me ?? this.me,
      capabilities: capabilities ?? this.capabilities,
      member: member ?? this.member,
      roles: roles ?? this.roles,
      presets: presets ?? this.presets,
      selectedRoleId: selectedRoleId ?? this.selectedRoleId,
      selectedPresetId: selectedPresetId,
      permissions: permissions ?? this.permissions,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

AclPresetOption? _presetForRole(
  List<AclPresetOption> presets,
  String? roleCode,
) {
  if (roleCode == null || roleCode.isEmpty) {
    return null;
  }

  for (final preset in presets) {
    if (preset.roleCode == roleCode) {
      return preset;
    }
  }
  return null;
}
