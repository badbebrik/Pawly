import '../models/acl_permission.dart';
import '../models/acl_role_option.dart';

const Object _unset = Object();

class AclInviteFormState {
  const AclInviteFormState({
    required this.petId,
    required this.inviteId,
    required this.roles,
    required this.presets,
    required this.selectedRoleId,
    required this.customRoleTitle,
    required this.selectedPresetId,
    required this.permissions,
    required this.isSubmitting,
  });

  factory AclInviteFormState.initial({
    required String petId,
    required List<AclRoleOption> roles,
    required List<AclPresetOption> presets,
    required AclPermissionDraft permissions,
    String? inviteId,
    String? selectedRoleId,
    String? selectedPresetId,
  }) {
    return AclInviteFormState(
      petId: petId,
      inviteId: inviteId,
      roles: roles,
      presets: presets,
      selectedRoleId: selectedRoleId,
      customRoleTitle: '',
      selectedPresetId: selectedPresetId,
      permissions: permissions,
      isSubmitting: false,
    );
  }

  final String petId;
  final String? inviteId;
  final List<AclRoleOption> roles;
  final List<AclPresetOption> presets;
  final String? selectedRoleId;
  final String customRoleTitle;
  final String? selectedPresetId;
  final AclPermissionDraft permissions;
  final bool isSubmitting;

  List<AclRoleOption> get systemRoles {
    return roles.where((role) => role.isSystem).toList(growable: false);
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
    final roleCode = role.code;
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

  String? get normalizedCustomRoleTitle {
    final value = customRoleTitle.trim();
    return value.isEmpty ? null : value;
  }

  bool get hasSelectedSystemRole {
    return selectedRoleId != null && selectedRoleId!.isNotEmpty;
  }

  bool get hasCustomRoleTitle => normalizedCustomRoleTitle != null;

  bool get isRoleSelectionValid => hasSelectedSystemRole != hasCustomRoleTitle;

  AclInviteFormState copyWith({
    List<AclRoleOption>? roles,
    List<AclPresetOption>? presets,
    Object? selectedRoleId = _unset,
    Object? customRoleTitle = _unset,
    Object? selectedPresetId = _unset,
    AclPermissionDraft? permissions,
    bool? isSubmitting,
  }) {
    return AclInviteFormState(
      petId: petId,
      inviteId: inviteId,
      roles: roles ?? this.roles,
      presets: presets ?? this.presets,
      selectedRoleId: selectedRoleId == _unset
          ? this.selectedRoleId
          : selectedRoleId as String?,
      customRoleTitle: customRoleTitle == _unset
          ? this.customRoleTitle
          : customRoleTitle as String,
      selectedPresetId: selectedPresetId == _unset
          ? this.selectedPresetId
          : selectedPresetId as String?,
      permissions: permissions ?? this.permissions,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}
