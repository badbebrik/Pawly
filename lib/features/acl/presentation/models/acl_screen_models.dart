import '../../../../core/network/models/acl_models.dart';

const Object _unset = Object();

enum AclPermissionDomain {
  pet,
  log,
  health,
  members,
}

extension AclPermissionDomainX on AclPermissionDomain {
  String get readKey => '${name}_read';

  String get writeKey => '${name}_write';
}

class AclPermissionSelection {
  const AclPermissionSelection({
    required this.domain,
    required this.canRead,
    required this.canWrite,
  });

  final AclPermissionDomain domain;
  final bool canRead;
  final bool canWrite;

  AclPermissionSelection copyWith({
    bool? canRead,
    bool? canWrite,
  }) {
    return AclPermissionSelection(
      domain: domain,
      canRead: canRead ?? this.canRead,
      canWrite: canWrite ?? this.canWrite,
    );
  }
}

class AclPermissionDraft {
  const AclPermissionDraft({required this.items});

  factory AclPermissionDraft.fromPolicy(AclPolicy policy) {
    return AclPermissionDraft(
      items: AclPermissionDomain.values.map((domain) {
        return AclPermissionSelection(
          domain: domain,
          canRead: policy.permissions[domain.readKey] ?? false,
          canWrite: policy.permissions[domain.writeKey] ?? false,
        );
      }).toList(growable: false),
    );
  }

  final List<AclPermissionSelection> items;

  AclPermissionSelection selectionFor(AclPermissionDomain domain) {
    return items.firstWhere((item) => item.domain == domain);
  }

  AclPermissionDraft updateRead(AclPermissionDomain domain, bool value) {
    return AclPermissionDraft(
      items: items.map((item) {
        if (item.domain != domain) {
          return item;
        }

        return item.copyWith(
          canRead: value,
          canWrite: value ? item.canWrite : false,
        );
      }).toList(growable: false),
    );
  }

  AclPermissionDraft updateWrite(AclPermissionDomain domain, bool value) {
    return AclPermissionDraft(
      items: items.map((item) {
        if (item.domain != domain) {
          return item;
        }

        return item.copyWith(
          canRead: value ? true : item.canRead,
          canWrite: value,
        );
      }).toList(growable: false),
    );
  }

  AclPolicy toPolicy() {
    final permissions = <String, bool>{};
    for (final item in items) {
      permissions[item.domain.readKey] = item.canRead;
      permissions[item.domain.writeKey] = item.canWrite;
    }
    return AclPolicy(permissions: permissions);
  }
}

class AclAccessScreenState {
  const AclAccessScreenState({
    required this.petId,
    required this.me,
    required this.capabilities,
    required this.members,
    required this.roles,
    required this.presets,
    required this.invites,
  });

  factory AclAccessScreenState.fromBootstrap(AclBootstrapResponse response) {
    return AclAccessScreenState(
      petId: response.petId,
      me: response.me,
      capabilities: response.capabilities,
      members: response.members,
      roles: response.roles,
      presets: response.presets,
      invites: response.invites,
    );
  }

  final String petId;
  final AclMember me;
  final AclCapabilities capabilities;
  final List<AclMember> members;
  final List<AclRole> roles;
  final List<AclPreset> presets;
  final List<AclInvite> invites;

  List<AclMember> get activeMembers {
    return members
        .where((member) => member.status == 'ACTIVE')
        .toList(growable: false);
  }

  List<AclMember> get membersForDisplay {
    final owners = <AclMember>[];
    final others = <AclMember>[];

    for (final member in activeMembers) {
      if (member.isPrimaryOwner) {
        owners.add(member);
      } else {
        others.add(member);
      }
    }

    return <AclMember>[...owners, ...others];
  }

  List<AclInvite> get activeInvites {
    return invites
        .where((invite) => invite.status == 'ACTIVE')
        .toList(growable: false);
  }

  AclAccessScreenState copyWith({
    AclMember? me,
    AclCapabilities? capabilities,
    List<AclMember>? members,
    List<AclRole>? roles,
    List<AclPreset>? presets,
    List<AclInvite>? invites,
  }) {
    return AclAccessScreenState(
      petId: petId,
      me: me ?? this.me,
      capabilities: capabilities ?? this.capabilities,
      members: members ?? this.members,
      roles: roles ?? this.roles,
      presets: presets ?? this.presets,
      invites: invites ?? this.invites,
    );
  }
}

class AclCreateInviteState {
  const AclCreateInviteState({
    required this.petId,
    required this.roles,
    required this.presets,
    required this.selectedRoleId,
    required this.customRoleTitle,
    required this.selectedPresetId,
    required this.permissions,
    required this.isSubmitting,
  });

  factory AclCreateInviteState.initial({
    required String petId,
    required List<AclRole> roles,
    required List<AclPreset> presets,
    required AclPolicy policy,
  }) {
    return AclCreateInviteState(
      petId: petId,
      roles: roles,
      presets: presets,
      selectedRoleId: null,
      customRoleTitle: '',
      selectedPresetId: null,
      permissions: AclPermissionDraft.fromPolicy(policy),
      isSubmitting: false,
    );
  }

  final String petId;
  final List<AclRole> roles;
  final List<AclPreset> presets;
  final String? selectedRoleId;
  final String customRoleTitle;
  final String? selectedPresetId;
  final AclPermissionDraft permissions;
  final bool isSubmitting;

  List<AclRole> get systemRoles {
    return roles.where((role) => role.kind == 'SYSTEM').toList(growable: false);
  }

  List<AclRole> get customRoles {
    return roles.where((role) => role.kind == 'CUSTOM').toList(growable: false);
  }

  AclRole? roleById(String? roleId) {
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

  AclPreset? presetForRole(AclRole role) {
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

  AclPolicy get policy => permissions.toPolicy();

  AclCreateInviteState copyWith({
    List<AclRole>? roles,
    List<AclPreset>? presets,
    Object? selectedRoleId = _unset,
    Object? customRoleTitle = _unset,
    Object? selectedPresetId = _unset,
    AclPermissionDraft? permissions,
    bool? isSubmitting,
  }) {
    return AclCreateInviteState(
      petId: petId,
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

class AclInviteDetailsState {
  const AclInviteDetailsState({
    required this.petId,
    required this.invite,
  });

  final String petId;
  final AclInvite invite;

  bool get hasDeeplinkUrl {
    final url = invite.deeplinkUrl;
    return url != null && url.isNotEmpty;
  }

  AclInviteDetailsState copyWith({AclInvite? invite}) {
    return AclInviteDetailsState(
      petId: petId,
      invite: invite ?? this.invite,
    );
  }
}

class AclInvitePreviewState {
  const AclInvitePreviewState({
    required this.invite,
    required this.isSubmitting,
  });

  factory AclInvitePreviewState.initial({required AclInvite invite}) {
    return AclInvitePreviewState(
      invite: invite,
      isSubmitting: false,
    );
  }

  final AclInvite invite;
  final bool isSubmitting;

  AclInvitePreviewState copyWith({
    AclInvite? invite,
    bool? isSubmitting,
  }) {
    return AclInvitePreviewState(
      invite: invite ?? this.invite,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}
