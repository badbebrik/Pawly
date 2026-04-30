class AclMemberDetailsParams {
  const AclMemberDetailsParams({
    required this.petId,
    required this.memberId,
  });

  final String petId;
  final String memberId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is AclMemberDetailsParams &&
        other.petId == petId &&
        other.memberId == memberId;
  }

  @override
  int get hashCode => Object.hash(petId, memberId);
}
