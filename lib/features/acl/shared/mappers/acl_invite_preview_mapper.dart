import '../../../../core/network/models/acl_models.dart' as network;
import '../../models/acl_invite_preview.dart';
import 'acl_permission_mapper.dart';
import '../formatters/acl_role_formatters.dart';

AclInvitePreview aclInvitePreviewFromNetwork(
  network.AclInvitePreviewResponse response,
) {
  final invite = response.invite;
  final pet = response.pet;

  return AclInvitePreview(
    pet: AclInvitePet(
      id: pet.id,
      name: pet.name,
      photoUrl: pet.photoDownloadUrl,
    ),
    roleTitle: aclRoleTitleFromValues(
      code: invite.role.code,
      title: invite.role.title,
    ),
    code: invite.code,
    expiresAt: invite.expiresAt,
    permissions: aclPermissionDraftFromNetwork(invite.policy),
  );
}

AclAcceptedInvite aclAcceptedInviteFromNetwork(
  network.AcceptInviteResponse response,
) {
  return AclAcceptedInvite(
    petId: response.petId,
    roleTitle: aclRoleTitleFromValues(
      code: response.member.role.code,
      title: response.member.role.title,
    ),
  );
}
