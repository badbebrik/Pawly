class AclInviteRef {
  const AclInviteRef({
    required this.petId,
    required this.inviteId,
  });

  final String petId;
  final String inviteId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is AclInviteRef &&
        other.petId == petId &&
        other.inviteId == inviteId;
  }

  @override
  int get hashCode => Object.hash(petId, inviteId);
}
