import 'json_map.dart';
import 'json_parsers.dart';

class AclPolicy {
  const AclPolicy({required this.permissions});

  final Map<String, bool> permissions;

  factory AclPolicy.fromJson(Object? data) {
    final json = asJsonMap(data);
    return AclPolicy(
      permissions: json.map(
        (String key, dynamic value) => MapEntry(key, asBool(value)),
      ),
    );
  }

  JsonMap toJson() => permissions;
}

class AclRole {
  const AclRole({
    required this.id,
    required this.kind,
    required this.petId,
    required this.code,
    required this.title,
    required this.createdByUserId,
  });

  final String id;
  final String kind;
  final String? petId;
  final String? code;
  final String title;
  final String? createdByUserId;

  factory AclRole.fromJson(Object? data) {
    final json = asJsonMap(data);
    return AclRole(
      id: asString(json['id']),
      kind: asString(json['kind']),
      petId: asNullableString(json['pet_id']),
      code: asNullableString(json['code']),
      title: asString(json['title']),
      createdByUserId: asNullableString(json['created_by_user_id']),
    );
  }
}

class AclMemberProfile {
  const AclMemberProfile({
    required this.firstName,
    required this.lastName,
    required this.displayName,
    required this.avatarDownloadUrl,
  });

  final String? firstName;
  final String? lastName;
  final String? displayName;
  final String? avatarDownloadUrl;

  factory AclMemberProfile.fromJson(Object? data) {
    final json = asJsonMap(data);
    return AclMemberProfile(
      firstName: asNullableString(json['first_name']),
      lastName: asNullableString(json['last_name']),
      displayName: asNullableString(json['display_name']),
      avatarDownloadUrl: asNullableString(json['avatar_download_url']),
    );
  }
}

class AclMember {
  const AclMember({
    required this.id,
    required this.petId,
    required this.userId,
    required this.status,
    required this.isPrimaryOwner,
    required this.role,
    required this.policy,
    required this.profile,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String petId;
  final String userId;
  final String status;
  final bool isPrimaryOwner;
  final AclRole role;
  final AclPolicy policy;
  final AclMemberProfile? profile;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory AclMember.fromJson(Object? data) {
    final json = asJsonMap(data);

    return AclMember(
      id: asString(json['id']),
      petId: asString(json['pet_id']),
      userId: asString(json['user_id']),
      status: asString(json['status']),
      isPrimaryOwner: asBool(json['is_primary_owner']),
      role: AclRole.fromJson(json['role']),
      policy: AclPolicy.fromJson(json['policy']),
      profile: json['profile'] == null
          ? null
          : AclMemberProfile.fromJson(json['profile']),
      createdAt: asDateTime(json['created_at']),
      updatedAt: asDateTime(json['updated_at']),
    );
  }
}

class AclInvite {
  const AclInvite({
    required this.id,
    required this.petId,
    required this.status,
    required this.code,
    required this.deeplinkUrl,
    required this.expiresAt,
    required this.role,
    required this.basePresetId,
    required this.policy,
    required this.createdByUserId,
    required this.createdAt,
    required this.consumedAt,
    required this.consumedByUserId,
  });

  final String id;
  final String petId;
  final String status;
  final String code;
  final String? deeplinkUrl;
  final DateTime? expiresAt;
  final AclRole role;
  final String? basePresetId;
  final AclPolicy policy;
  final String createdByUserId;
  final DateTime? createdAt;
  final DateTime? consumedAt;
  final String? consumedByUserId;

  factory AclInvite.fromJson(Object? data) {
    final json = asJsonMap(data);

    return AclInvite(
      id: asString(json['id']),
      petId: asString(json['pet_id']),
      status: asString(json['status']),
      code: asString(json['code']),
      deeplinkUrl: asNullableString(json['deeplink_url']),
      expiresAt: asDateTime(json['expires_at']),
      role: AclRole.fromJson(json['role']),
      basePresetId: asNullableString(json['base_preset_id']),
      policy: AclPolicy.fromJson(json['policy']),
      createdByUserId: asString(json['created_by_user_id']),
      createdAt: asDateTime(json['created_at']),
      consumedAt: asDateTime(json['consumed_at']),
      consumedByUserId: asNullableString(json['consumed_by_user_id']),
    );
  }
}

class AclPreset {
  const AclPreset({
    required this.id,
    required this.name,
    required this.roleCode,
    required this.policy,
  });

  final String id;
  final String name;
  final String? roleCode;
  final AclPolicy policy;

  factory AclPreset.fromJson(Object? data) {
    final json = asJsonMap(data);

    return AclPreset(
      id: asString(json['id']),
      name: asString(json['name']),
      roleCode: asNullableString(json['role_code']),
      policy: AclPolicy.fromJson(json['policy']),
    );
  }
}

class AclPresetListResponse {
  const AclPresetListResponse({required this.items});

  final List<AclPreset> items;

  factory AclPresetListResponse.fromJson(Object? data) {
    final json = asJsonMap(data);
    final items = asJsonMapList(json['items'])
        .map(AclPreset.fromJson)
        .toList(growable: false);
    return AclPresetListResponse(items: items);
  }
}

class AclMemberEnvelope {
  const AclMemberEnvelope({required this.member});

  final AclMember member;

  factory AclMemberEnvelope.fromJson(Object? data) {
    final json = asJsonMap(data);
    return AclMemberEnvelope(member: AclMember.fromJson(json['member']));
  }
}

class AclMemberListResponse {
  const AclMemberListResponse({required this.items});

  final List<AclMember> items;

  factory AclMemberListResponse.fromJson(Object? data) {
    final json = asJsonMap(data);
    final items = asJsonMapList(json['items'])
        .map(AclMember.fromJson)
        .toList(growable: false);
    return AclMemberListResponse(items: items);
  }
}

class AclRoleEnvelope {
  const AclRoleEnvelope({required this.role});

  final AclRole role;

  factory AclRoleEnvelope.fromJson(Object? data) {
    final json = asJsonMap(data);
    return AclRoleEnvelope(role: AclRole.fromJson(json['role']));
  }
}

class AclRoleListResponse {
  const AclRoleListResponse({required this.items});

  final List<AclRole> items;

  factory AclRoleListResponse.fromJson(Object? data) {
    final json = asJsonMap(data);
    final items = asJsonMapList(json['items'])
        .map(AclRole.fromJson)
        .toList(growable: false);
    return AclRoleListResponse(items: items);
  }
}

class AclInviteEnvelope {
  const AclInviteEnvelope({required this.invite});

  final AclInvite invite;

  factory AclInviteEnvelope.fromJson(Object? data) {
    final json = asJsonMap(data);
    return AclInviteEnvelope(invite: AclInvite.fromJson(json['invite']));
  }
}

class AclInviteListResponse {
  const AclInviteListResponse({required this.items});

  final List<AclInvite> items;

  factory AclInviteListResponse.fromJson(Object? data) {
    final json = asJsonMap(data);
    final items = asJsonMapList(json['items'])
        .map(AclInvite.fromJson)
        .toList(growable: false);
    return AclInviteListResponse(items: items);
  }
}

class AclMyAccess {
  const AclMyAccess({
    required this.memberId,
    required this.status,
    required this.isPrimaryOwner,
    required this.role,
    required this.policy,
  });

  final String memberId;
  final String status;
  final bool isPrimaryOwner;
  final AclRole role;
  final AclPolicy policy;

  factory AclMyAccess.fromJson(Object? data) {
    final json = asJsonMap(data);
    return AclMyAccess(
      memberId: asString(json['member_id']),
      status: asString(json['status']),
      isPrimaryOwner: asBool(json['is_primary_owner']),
      role: AclRole.fromJson(json['role']),
      policy: AclPolicy.fromJson(json['policy']),
    );
  }
}

class AclAccessResponse {
  const AclAccessResponse({required this.petId, required this.member});

  final String petId;
  final AclMember member;

  factory AclAccessResponse.fromJson(Object? data) {
    final json = asJsonMap(data);
    return AclAccessResponse(
      petId: asString(json['pet_id']),
      member: AclMember.fromJson(json['member']),
    );
  }
}

class AclCapabilities {
  const AclCapabilities({
    required this.membersRead,
    required this.membersWrite,
  });

  final bool membersRead;
  final bool membersWrite;

  factory AclCapabilities.fromJson(Object? data) {
    final json = asJsonMap(data);
    return AclCapabilities(
      membersRead: asBool(json['members_read']),
      membersWrite: asBool(json['members_write']),
    );
  }
}

class AclBootstrapResponse {
  const AclBootstrapResponse({
    required this.petId,
    required this.me,
    required this.capabilities,
    required this.members,
    required this.roles,
    required this.presets,
    required this.invites,
  });

  final String petId;
  final AclMember me;
  final AclCapabilities capabilities;
  final List<AclMember> members;
  final List<AclRole> roles;
  final List<AclPreset> presets;
  final List<AclInvite> invites;

  factory AclBootstrapResponse.fromJson(Object? data) {
    final json = asJsonMap(data);
    return AclBootstrapResponse(
      petId: asString(json['pet_id']),
      me: AclMember.fromJson(json['me']),
      capabilities: AclCapabilities.fromJson(json['capabilities']),
      members: asJsonMapList(json['members'])
          .map(AclMember.fromJson)
          .toList(growable: false),
      roles: asJsonMapList(json['roles'])
          .map(AclRole.fromJson)
          .toList(growable: false),
      presets: asJsonMapList(json['presets'])
          .map(AclPreset.fromJson)
          .toList(growable: false),
      invites: asJsonMapList(json['invites'])
          .map(AclInvite.fromJson)
          .toList(growable: false),
    );
  }
}

class AcceptInviteResponse {
  const AcceptInviteResponse({required this.petId, required this.member});

  final String petId;
  final AclMember member;

  factory AcceptInviteResponse.fromJson(Object? data) {
    final json = asJsonMap(data);
    return AcceptInviteResponse(
      petId: asString(json['pet_id']),
      member: AclMember.fromJson(json['member']),
    );
  }
}

class AclInvitePreviewResponse {
  const AclInvitePreviewResponse({required this.invite});

  final AclInvite invite;

  factory AclInvitePreviewResponse.fromJson(Object? data) {
    final json = asJsonMap(data);
    return AclInvitePreviewResponse(
      invite: AclInvite.fromJson(json['invite']),
    );
  }
}

class UpdateMemberPayload {
  const UpdateMemberPayload({
    required this.roleId,
    required this.policy,
    this.basePresetId,
  });

  final String roleId;
  final String? basePresetId;
  final AclPolicy policy;

  JsonMap toJson() {
    return <String, dynamic>{
      'role_id': roleId,
      'base_preset_id': basePresetId,
      'policy': policy.toJson(),
    }..removeWhere((_, dynamic value) => value == null);
  }
}

class CreateRolePayload {
  const CreateRolePayload({required this.title});

  final String title;

  JsonMap toJson() => <String, dynamic>{'title': title};
}

class CreateInvitePayload {
  const CreateInvitePayload({
    required this.roleId,
    required this.policy,
    this.basePresetId,
  });

  final String roleId;
  final String? basePresetId;
  final AclPolicy policy;

  JsonMap toJson() {
    return <String, dynamic>{
      'role_id': roleId,
      'base_preset_id': basePresetId,
      'policy': policy.toJson(),
    }..removeWhere((_, dynamic value) => value == null);
  }
}

class AcceptInviteByCodePayload {
  const AcceptInviteByCodePayload({required this.code});

  final String code;

  JsonMap toJson() => <String, dynamic>{'code': code};
}

class PreviewInviteByTokenPayload {
  const PreviewInviteByTokenPayload({required this.token});

  final String token;

  JsonMap toJson() => <String, dynamic>{'token': token};
}

class AcceptInviteByTokenPayload {
  const AcceptInviteByTokenPayload({required this.token});

  final String token;

  JsonMap toJson() => <String, dynamic>{'token': token};
}
