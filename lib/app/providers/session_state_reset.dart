import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/controllers/auth_dependencies.dart';
import '../../features/chat/controllers/chat_connection_controller.dart';
import '../../features/chat/controllers/chat_dependencies.dart';
import '../../features/chat/controllers/chat_unread_controller.dart';
import '../../features/pets/controllers/active_pet_controller.dart';
import '../../features/pets/controllers/active_pet_details_controller.dart';
import '../../features/pets/controllers/pets_controller.dart';

void resetSessionState(WidgetRef ref) {
  ref.invalidate(appLaunchProvider);
  ref.invalidate(currentUserIdProvider);
  ref.invalidate(chatUnreadSummaryControllerProvider);
  ref.invalidate(chatSocketConnectionControllerProvider);
  ref.invalidate(chatSocketServiceProvider);
  ref.invalidate(activePetControllerProvider);
  ref.invalidate(activePetDetailsControllerProvider);
  ref.invalidate(petsControllerProvider);
}
