import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final chatApiClient = ref.watch(chatApiClientProvider);
  return ChatRepository(chatApiClient: chatApiClient);
});
