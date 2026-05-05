enum PetHealthSectionType {
  vetVisits,
  vaccinations,
  procedures,
  medicalRecords,
}

class PetHealthHomeState {
  const PetHealthHomeState({
    required this.petName,
    required this.canRead,
    required this.canWrite,
    required this.sections,
  });

  final String petName;
  final bool canRead;
  final bool canWrite;
  final List<PetHealthHomeSectionState> sections;
}

class PetHealthHomeSectionState {
  const PetHealthHomeSectionState({
    required this.type,
    required this.countLabel,
  });

  final PetHealthSectionType type;
  final String countLabel;
}
