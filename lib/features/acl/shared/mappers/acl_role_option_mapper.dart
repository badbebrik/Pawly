import '../../../../core/network/models/acl_models.dart' as network;
import '../../models/acl_role_option.dart';
import 'acl_permission_mapper.dart';

AclRoleOption aclRoleOptionFromNetwork(network.AclRole role) {
  return AclRoleOption(
    id: role.id,
    kind: role.kind,
    code: role.code,
    title: role.title,
    permissions: aclPermissionDraftFromNetwork(role.policy),
  );
}

AclPresetOption aclPresetOptionFromNetwork(network.AclPreset preset) {
  return AclPresetOption(
    id: preset.id,
    roleCode: preset.roleCode,
    permissions: aclPermissionDraftFromNetwork(preset.policy),
  );
}
