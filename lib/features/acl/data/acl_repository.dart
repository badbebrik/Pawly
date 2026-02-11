import '../../../core/network/clients/acl_api_client.dart';
import '../../../core/network/models/acl_models.dart';
import 'acl_repository_models.dart';

class AclRepository {
  AclRepository({required AclApiClient aclApiClient})
      : _aclApiClient = aclApiClient;

  final AclApiClient _aclApiClient;

  Future<AclBootstrapResponse> getBootstrap(String petId) async {
    return _aclApiClient.getBootstrap(petId);
  }

  Future<AclCreateInviteResult> createInvite(AclCreateInviteInput input) async {
    final trimmedCustomRoleTitle = input.customRoleTitle?.trim();
    final hasRoleId = input.roleId != null && input.roleId!.isNotEmpty;
    final hasCustomRoleTitle =
        trimmedCustomRoleTitle != null && trimmedCustomRoleTitle.isNotEmpty;

    if (hasRoleId == hasCustomRoleTitle) {
      throw StateError(
        'Для создания приглашения нужно передать либо roleId, либо customRoleTitle.',
      );
    }

    AclRole? createdRole;
    late final String roleId;
    if (hasRoleId) {
      roleId = input.roleId!;
    } else {
      createdRole = (await _aclApiClient.createRole(
        input.petId,
        CreateRolePayload(title: trimmedCustomRoleTitle!),
      ))
          .role;
      roleId = createdRole.id;
    }

    final inviteResponse = await _aclApiClient.createInvite(
      input.petId,
      CreateInvitePayload(
        roleId: roleId,
        basePresetId: input.basePresetId,
        policy: input.policy,
      ),
    );

    return AclCreateInviteResult(
      invite: inviteResponse.invite,
      createdRole: createdRole,
    );
  }

  Future<AclMember> updateMember({
    required String petId,
    required String memberId,
    required String roleId,
    required AclPolicy policy,
    String? basePresetId,
  }) async {
    final response = await _aclApiClient.updateMember(
      petId,
      memberId,
      UpdateMemberPayload(
        roleId: roleId,
        basePresetId: basePresetId,
        policy: policy,
      ),
    );
    return response.member;
  }

  Future<AclMember> removeMember({
    required String petId,
    required String memberId,
  }) async {
    final response = await _aclApiClient.removeMember(petId, memberId);
    return response.member;
  }

  Future<void> revokeInvite({
    required String petId,
    required String inviteId,
  }) async {
    await _aclApiClient.revokeInvite(petId, inviteId);
  }

  Future<AclInvite> previewInviteByToken(String token) async {
    final response = await _aclApiClient.previewInviteByToken(
      PreviewInviteByTokenPayload(token: token),
    );
    return response.invite;
  }

  Future<AcceptInviteResponse> acceptInviteByToken(String token) async {
    return _aclApiClient.acceptInviteByToken(
      AcceptInviteByTokenPayload(token: token),
    );
  }
}
