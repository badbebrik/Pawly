import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

final activePetControllerProvider =
    AsyncNotifierProvider<ActivePetController, String?>(
  ActivePetController.new,
);

class ActivePetController extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    return _readActivePetId();
  }

  Future<void> selectPet(String petId) async {
    final userId = await ref.read(currentUserIdProvider.future);
    if (userId == null || userId.isEmpty) {
      throw StateError('Cannot select active pet without authenticated user.');
    }

    await ref.read(secureStorageServiceProvider).saveActivePetId(
          userId: userId,
          petId: petId,
        );

    state = AsyncData(petId);
  }

  Future<void> clear() async {
    final userId = await ref.read(currentUserIdProvider.future);
    if (userId != null && userId.isNotEmpty) {
      await ref.read(secureStorageServiceProvider).clearActivePetId(userId);
    }

    state = const AsyncData(null);
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = AsyncData(await _readActivePetId());
  }

  Future<String?> _readActivePetId() async {
    final userId = await ref.watch(currentUserIdProvider.future);
    if (userId == null || userId.isEmpty) {
      return null;
    }

    return ref.watch(secureStorageServiceProvider).getActivePetId(userId);
  }
}
