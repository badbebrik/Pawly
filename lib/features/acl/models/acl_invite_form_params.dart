class AclInviteFormParams {
  const AclInviteFormParams({
    required this.petId,
    this.inviteId,
  });

  final String petId;
  final String? inviteId;

  bool get isEditMode => inviteId != null && inviteId!.isNotEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is AclInviteFormParams &&
        other.petId == petId &&
        other.inviteId == inviteId;
  }

  @override
  int get hashCode => Object.hash(petId, inviteId);
}
