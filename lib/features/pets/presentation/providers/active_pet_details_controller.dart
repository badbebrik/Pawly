import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_error.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/models/pet_models.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../catalog/data/catalog_cache_models.dart';
import '../../../catalog/presentation/providers/catalog_providers.dart';
import 'active_pet_controller.dart';
import 'pets_controller.dart';

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

final activePetDetailsControllerProvider =
    AsyncNotifierProvider<ActivePetDetailsController, ActivePetDetailsState?>(
  ActivePetDetailsController.new,
);

class ActivePetDetailsController extends AsyncNotifier<ActivePetDetailsState?> {
  @override
  Future<ActivePetDetailsState?> build() async {
    return _load();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = AsyncData(await _load());
  }

  Future<void> uploadPhoto(ImageSource source) async {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }

    final file = await ref.read(mediaPickerServiceProvider).pickImage(
          source: source,
        );
    if (file == null) {
      return;
    }

    state = AsyncData(current.copyWith(isUploadingPhoto: true));

    try {
      final updatedPet = await ref.read(petsRepositoryProvider).uploadPetPhoto(
            pet: current.pet,
            file: file,
          );
      final catalog = await ref.read(catalogSyncProvider.future);

      state = AsyncData(
        current.copyWith(
          pet: updatedPet,
          speciesName: _speciesName(catalog, updatedPet.speciesId),
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
    final activePetId = await ref.watch(activePetControllerProvider.future);
    if (activePetId == null || activePetId.isEmpty) {
      return null;
    }

    final Pet pet;
    try {
      pet = await ref.read(petsRepositoryProvider).getPetById(activePetId);
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
    final catalog = await ref.read(catalogSyncProvider.future);

    return ActivePetDetailsState(
      pet: pet,
      speciesName: _speciesName(catalog, pet.speciesId),
      isUploadingPhoto: false,
    );
  }

  String _speciesName(CatalogSnapshot catalog, String speciesId) {
    for (final species in catalog.species) {
      if (species.id == speciesId) {
        return species.name;
      }
    }

    return 'Неизвестный вид';
  }

  bool _isInactiveAccessError(ApiException error) {
    return error.error.type == ApiErrorType.forbidden ||
        error.error.type == ApiErrorType.notFound;
  }
}
