import '../../../../core/network/models/acl_models.dart' as network;
import '../../models/acl_member.dart';
import '../formatters/acl_role_formatters.dart';
import 'acl_permission_mapper.dart';

AclMember aclMemberFromNetwork(network.AclMember member) {
  return AclMember(
    id: member.id,
    petId: member.petId,
    userId: member.userId,
    status: member.status,
    isPrimaryOwner: member.isPrimaryOwner,
    roleId: member.role.id,
    roleCode: member.role.code,
    roleTitle: aclRoleTitleFromValues(
      code: member.role.code,
      title: member.role.title,
    ),
    permissions: aclPermissionDraftFromNetwork(member.policy),
    profile: member.profile == null
        ? null
        : AclMemberProfile(
            firstName: member.profile!.firstName,
            lastName: member.profile!.lastName,
            displayNameValue: member.profile!.displayName,
            avatarUrl: member.profile!.avatarDownloadUrl,
          ),
  );
}
