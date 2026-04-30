import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../models/chat_models.dart';
import 'chat_conversation_tile.dart';
import 'chat_inbox_empty_state.dart';

class ChatInboxList extends StatelessWidget {
  const ChatInboxList({
    required this.items,
    required this.isLoadingMore,
    required this.scrollController,
    required this.onConversationTap,
    super.key,
  });

  final List<ChatListItem> items;
  final bool isLoadingMore;
  final ScrollController scrollController;
  final ValueChanged<ChatListItem> onConversationTap;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(
          PawlySpacing.md,
          PawlySpacing.lg,
          PawlySpacing.md,
          PawlySpacing.xl,
        ),
        children: const <Widget>[
          SizedBox(height: PawlySpacing.xxl),
          ChatInboxEmptyState(),
        ],
      );
    }

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(
        PawlySpacing.md,
        PawlySpacing.md,
        PawlySpacing.md,
        PawlySpacing.xl,
      ),
      itemCount: items.length + (isLoadingMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: PawlySpacing.sm),
      itemBuilder: (context, index) {
        if (index >= items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: PawlySpacing.md),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final item = items[index];
        return ChatConversationTile(
          item: item,
          onTap: () => onConversationTap(item),
        );
      },
    );
  }
}
