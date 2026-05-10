import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/design_system.dart';
import '../../controllers/chat_inbox_controller.dart';
import '../../controllers/chat_unread_controller.dart';
import '../../models/chat_models.dart';
import '../widgets/chat_inbox_list.dart';

class ChatInboxPage extends ConsumerStatefulWidget {
  const ChatInboxPage({super.key});

  @override
  ConsumerState<ChatInboxPage> createState() => _ChatInboxPageState();
}

class _ChatInboxPageState extends ConsumerState<ChatInboxPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inboxState = ref.watch(chatInboxControllerProvider(null));

    return PawlyScreenScaffold(
      title: 'Сообщения',
      body: inboxState.when(
        data: (state) => RefreshIndicator(
          onRefresh: _refresh,
          child: ChatInboxList(
            items: state.items,
            isLoadingMore: state.isLoadingMore,
            scrollController: _scrollController,
            onConversationTap: _openConversation,
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Padding(
            padding: const EdgeInsets.all(PawlySpacing.lg),
            child: PawlyCard(
              title: const Text('Не удалось загрузить чаты'),
              footer: PawlyButton(
                label: 'Повторить',
                onPressed: _refresh,
                variant: PawlyButtonVariant.secondary,
              ),
              child: const Text(
                'Попробуйте обновить экран или вернуться позже.',
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    try {
      await Future.wait<void>(<Future<void>>[
        ref.read(chatInboxControllerProvider(null).notifier).reload(),
        ref.read(chatUnreadSummaryControllerProvider.notifier).reload(),
      ]);
    } catch (_) {}
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;
    if (position.pixels < position.maxScrollExtent - 240) {
      return;
    }

    unawaited(
      ref
          .read(chatInboxControllerProvider(null).notifier)
          .loadMore()
          .catchError((_) {}),
    );
  }

  void _openConversation(ChatListItem item) {
    context.pushNamed(
      'chatConversation',
      pathParameters: <String, String>{
        'conversationId': item.conversationId,
      },
    );
  }
}
