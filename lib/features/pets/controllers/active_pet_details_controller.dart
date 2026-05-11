import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/providers/core_providers.dart';
import '../models/pet.dart';
import '../states/active_pet_details_state.dart';
import 'active_pet_controller.dart';
import 'pets_controller.dart';

final activePetDetailsControllerProvider = AsyncNotifierProvider.family<
    ActivePetDetailsController, ActivePetDetailsState?, String>(
  ActivePetDetailsController.new,
);

class ActivePetDetailsController extends AsyncNotifier<ActivePetDetailsState?> {
  ActivePetDetailsController(this._petId);

  final String _petId;

  @override
  Future<ActivePetDetailsState?> build() async {
    return _load();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = AsyncData(await _load());
  }

  Future<void> uploadPhotoFromGallery() {
    return _uploadPhoto(fromCamera: false);
  }

  Future<void> uploadPhotoFromCamera() {
    return _uploadPhoto(fromCamera: true);
  }

  Future<void> _uploadPhoto({required bool fromCamera}) async {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }

    final mediaPicker = ref.read(mediaPickerServiceProvider);
    final file = fromCamera
        ? await mediaPicker.takeAvatarPhoto()
        : await mediaPicker.pickAvatarFromGallery();
    if (file == null) {
      return;
    }

    state = AsyncData(current.copyWith(isUploadingPhoto: true));

    try {
      final updatedPet = await ref.read(petsRepositoryProvider).uploadPetPhoto(
            pet: current.pet,
            file: file,
          );

      state = AsyncData(
        current.copyWith(
          pet: updatedPet,
          speciesName: _speciesNameWithoutCatalog(updatedPet),
          isUploadingPhoto: false,
        ),
      );

      await ref.read(petsControllerProvider.notifier).refreshAfterPetMutation();
    } catch (_) {
      state = AsyncData(current.copyWith(isUploadingPhoto: false));
      rethrow;
    }
  }

  Future<void> deletePhoto() async {
    final current = state.asData?.value;
    if (current == null ||
        ((current.pet.profilePhotoFileId ?? '').isEmpty &&
            (current.pet.profilePhotoDownloadUrl ?? '').isEmpty)) {
      return;
    }

    state = AsyncData(current.copyWith(isUploadingPhoto: true));

    try {
      final updatedPet = await ref.read(petsRepositoryProvider).deletePetPhoto(
            pet: current.pet,
          );

      state = AsyncData(
        current.copyWith(
          pet: updatedPet,
          speciesName: _speciesNameWithoutCatalog(updatedPet),
          isUploadingPhoto: false,
        ),
      );

      await ref.read(petsControllerProvider.notifier).refreshAfterPetMutation();
    } catch (_) {
      state = AsyncData(current.copyWith(isUploadingPhoto: false));
      rethrow;
    }
  }

  Future<void> archivePet() async {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }

    final updatedPet = await ref.read(petsRepositoryProvider).changeStatus(
          petId: current.pet.id,
          rowVersion: current.pet.rowVersion,
          status: 'ARCHIVED',
        );

    await ref.read(activePetControllerProvider.notifier).clear();
    await ref.read(petsControllerProvider.notifier).refreshAfterPetMutation();

    state = AsyncData(
      current.copyWith(
        pet: updatedPet,
      ),
    );
  }

  Future<ActivePetDetailsState?> _load() async {
    if (_petId.isEmpty) {
      return null;
    }

    final Pet pet;
    try {
      pet = await ref.read(petsRepositoryProvider).getPet(_petId);
    } on ApiException catch (error) {
      if (_isInactiveAccessError(error)) {
        await ref.read(activePetControllerProvider.notifier).clear();
        await ref.read(petsControllerProvider.notifier).reload();
        return null;
      }
      rethrow;
    }
    if (pet.status == 'ARCHIVED') {
      await ref.read(activePetControllerProvider.notifier).clear();
      await ref.read(petsControllerProvider.notifier).reload();
      return null;
    }
    return ActivePetDetailsState(
      pet: pet,
      speciesName: _speciesNameWithoutCatalog(pet),
      isUploadingPhoto: false,
    );
  }

  bool _isInactiveAccessError(ApiException error) {
    return error.error.type == ApiErrorType.forbidden ||
        error.error.type == ApiErrorType.notFound;
  }

  String _speciesNameWithoutCatalog(Pet pet) {
    final customSpeciesName = pet.customSpeciesName?.trim();
    if (customSpeciesName != null && customSpeciesName.isNotEmpty) {
      return customSpeciesName;
    }

    final speciesName = pet.speciesName?.trim();
    if (speciesName != null && speciesName.isNotEmpty) {
      return speciesName;
    }

    return 'Неизвестный вид';
  }
}
