import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../data/chat_repository.dart';
import '../data/chat_socket_service.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final chatApiClient = ref.watch(chatApiClientProvider);
  return ChatRepository(chatApiClient: chatApiClient);
});

final chatSocketServiceProvider = Provider<ChatSocketService>((ref) {
  final authSessionStore = ref.watch(authSessionStoreProvider);
  final service = ChatSocketService(
    authSessionStore: authSessionStore,
  );
  ref.onDispose(service.dispose);
  return service;
});
