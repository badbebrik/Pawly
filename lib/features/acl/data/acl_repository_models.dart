import '../../../core/network/models/acl_models.dart';

class AclCreateInviteInput {
  const AclCreateInviteInput({
    required this.petId,
    required this.policy,
    this.roleId,
    this.customRoleTitle,
    this.basePresetId,
  });

  final String petId;
  final String? roleId;
  final String? customRoleTitle;
  final String? basePresetId;
  final AclPolicy policy;
}

class AclCreateInviteResult {
  const AclCreateInviteResult({
    required this.inviteId,
  });

  final String inviteId;
}
