class PetInviteResult {
  const PetInviteResult({
    required this.petId,
    required this.roleTitle,
    required this.isPrimaryOwner,
  });

  final String petId;
  final String roleTitle;
  final bool isPrimaryOwner;
}
