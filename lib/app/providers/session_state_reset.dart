import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/pets/presentation/providers/active_pet_controller.dart';
import '../../features/pets/presentation/providers/active_pet_details_controller.dart';
import '../../features/pets/presentation/providers/pets_controller.dart';

void resetSessionState(WidgetRef ref) {
  ref.invalidate(appLaunchProvider);
  ref.invalidate(currentUserIdProvider);
  ref.invalidate(activePetControllerProvider);
  ref.invalidate(activePetDetailsControllerProvider);
  ref.invalidate(petsControllerProvider);
}
