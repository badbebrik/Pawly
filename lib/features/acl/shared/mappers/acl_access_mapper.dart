import '../../../../core/network/models/acl_models.dart' as network;
import '../../models/acl_access.dart';
import '../../states/acl_access_state.dart';
import '../formatters/acl_role_formatters.dart';
import 'acl_member_mapper.dart';

AclAccessState aclAccessStateFromNetwork(
    network.AclBootstrapResponse response) {
  return AclAccessState(
    petId: response.petId,
    me: aclMemberFromNetwork(response.me),
    capabilities: AclAccessCapabilities(
      membersRead: response.capabilities.membersRead,
      membersWrite: response.capabilities.membersWrite,
    ),
    members: response.members.map(aclMemberFromNetwork).toList(growable: false),
    invites: response.invites.map(aclAccessInviteFromNetwork).toList(
          growable: false,
        ),
  );
}

AclAccessInvite aclAccessInviteFromNetwork(network.AclInvite invite) {
  return AclAccessInvite(
    id: invite.id,
    status: invite.status,
    code: invite.code,
    roleTitle: aclRoleTitleFromValues(
      code: invite.role.code,
      title: invite.role.title,
    ),
  );
}
