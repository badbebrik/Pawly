class AclAccessCapabilities {
  const AclAccessCapabilities({
    required this.membersRead,
    required this.membersWrite,
  });

  final bool membersRead;
  final bool membersWrite;
}

class AclAccessInvite {
  const AclAccessInvite({
    required this.id,
    required this.status,
    required this.code,
    required this.roleTitle,
  });

  final String id;
  final String status;
  final String code;
  final String roleTitle;

  bool get isActive => status == 'ACTIVE';
}
