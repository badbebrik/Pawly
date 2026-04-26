import '../../../core/network/models/pet_models.dart';

class ActivePetDetailsState {
  const ActivePetDetailsState({
    required this.pet,
    required this.speciesName,
    required this.isUploadingPhoto,
  });

  final Pet pet;
  final String speciesName;
  final bool isUploadingPhoto;

  ActivePetDetailsState copyWith({
    Pet? pet,
    String? speciesName,
    bool? isUploadingPhoto,
  }) {
    return ActivePetDetailsState(
      pet: pet ?? this.pet,
      speciesName: speciesName ?? this.speciesName,
      isUploadingPhoto: isUploadingPhoto ?? this.isUploadingPhoto,
    );
  }
}
