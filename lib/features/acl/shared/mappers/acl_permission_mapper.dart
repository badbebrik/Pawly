import '../../../../core/network/models/acl_models.dart' as network;
import '../../models/acl_permission.dart';

AclPermissionDraft aclPermissionDraftFromNetwork(network.AclPolicy policy) {
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

network.AclPolicy aclPermissionDraftToNetwork(AclPermissionDraft draft) {
  final permissions = <String, bool>{};
  for (final item in draft.items) {
    permissions[item.domain.readKey] = item.canRead;
    permissions[item.domain.writeKey] = item.canWrite;
  }
  return network.AclPolicy(permissions: permissions);
}
