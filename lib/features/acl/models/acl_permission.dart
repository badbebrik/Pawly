enum AclPermissionDomain {
  pet,
  log,
  health,
  members,
}

extension AclPermissionDomainX on AclPermissionDomain {
  String get readKey => '${name}_read';

  String get writeKey => '${name}_write';
}

class AclPermissionSelection {
  const AclPermissionSelection({
    required this.domain,
    required this.canRead,
    required this.canWrite,
  });

  final AclPermissionDomain domain;
  final bool canRead;
  final bool canWrite;

  AclPermissionSelection copyWith({
    bool? canRead,
    bool? canWrite,
  }) {
    return AclPermissionSelection(
      domain: domain,
      canRead: canRead ?? this.canRead,
      canWrite: canWrite ?? this.canWrite,
    );
  }
}

class AclPermissionDraft {
  const AclPermissionDraft({required this.items});

  final List<AclPermissionSelection> items;

  AclPermissionSelection selectionFor(AclPermissionDomain domain) {
    return items.firstWhere((item) => item.domain == domain);
  }

  AclPermissionDraft updateRead(AclPermissionDomain domain, bool value) {
    return AclPermissionDraft(
      items: items.map((item) {
        if (item.domain != domain) {
          return item;
        }

        return item.copyWith(
          canRead: value,
          canWrite: value ? item.canWrite : false,
        );
      }).toList(growable: false),
    );
  }

  AclPermissionDraft updateWrite(AclPermissionDomain domain, bool value) {
    return AclPermissionDraft(
      items: items.map((item) {
        if (item.domain != domain) {
          return item;
        }

        return item.copyWith(
          canRead: value ? true : item.canRead,
          canWrite: value,
        );
      }).toList(growable: false),
    );
  }
}
