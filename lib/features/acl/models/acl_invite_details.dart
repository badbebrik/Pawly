import 'acl_permission.dart';

class AclInviteDetails {
  const AclInviteDetails({
    required this.petId,
    required this.roleTitle,
    required this.code,
    required this.deeplinkUrl,
    required this.expiresAt,
    required this.permissions,
  });

  final String petId;
  final String roleTitle;
  final String code;
  final String? deeplinkUrl;
  final DateTime? expiresAt;
  final AclPermissionDraft permissions;

  bool get hasDeeplinkUrl {
    final url = deeplinkUrl;
    return url != null && url.isNotEmpty;
  }
}
