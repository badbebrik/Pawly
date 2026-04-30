import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/controllers/auth_dependencies.dart';
import '../../features/pets/controllers/active_pet_controller.dart';
import '../../features/pets/controllers/active_pet_details_controller.dart';
import '../../features/pets/controllers/pets_controller.dart';

void resetSessionState(WidgetRef ref) {
  ref.invalidate(appLaunchProvider);
  ref.invalidate(currentUserIdProvider);
  ref.invalidate(activePetControllerProvider);
  ref.invalidate(activePetDetailsControllerProvider);
  ref.invalidate(petsControllerProvider);
}
