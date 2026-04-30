import '../../../../core/network/models/acl_models.dart' as network;
import '../../models/acl_invite_details.dart';
import '../formatters/acl_role_formatters.dart';
import 'acl_permission_mapper.dart';

AclInviteDetails aclInviteDetailsFromNetwork(network.AclInvite invite) {
  return AclInviteDetails(
    petId: invite.petId,
    roleTitle: aclRoleTitleFromValues(
      code: invite.role.code,
      title: invite.role.title,
    ),
    code: invite.code,
    deeplinkUrl: invite.deeplinkUrl,
    expiresAt: invite.expiresAt,
    permissions: aclPermissionDraftFromNetwork(invite.policy),
  );
}
