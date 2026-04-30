import 'acl_permission.dart';

class AclRoleOption {
  const AclRoleOption({
    required this.id,
    required this.kind,
    required this.code,
    required this.title,
    required this.permissions,
  });

  final String id;
  final String kind;
  final String? code;
  final String title;
  final AclPermissionDraft permissions;

  bool get isSystem => kind == 'SYSTEM';
  bool get isCustom => kind == 'CUSTOM';
  bool get isOwner => code == 'OWNER';
}

class AclPresetOption {
  const AclPresetOption({
    required this.id,
    required this.roleCode,
    required this.permissions,
  });

  final String id;
  final String? roleCode;
  final AclPermissionDraft permissions;
}
