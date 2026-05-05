class ReminderRef {
  const ReminderRef({
    required this.petId,
    required this.itemId,
  });

  final String petId;
  final String itemId;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ReminderRef && other.petId == petId && other.itemId == itemId;
  }

  @override
  int get hashCode => Object.hash(petId, itemId);
}
