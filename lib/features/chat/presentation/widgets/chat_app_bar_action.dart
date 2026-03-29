import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../chat/presentation/providers/chat_providers.dart';

class ChatAppBarAction extends ConsumerWidget {
  const ChatAppBarAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadState = ref.watch(chatUnreadSummaryControllerProvider);
    final unreadCount = unreadState.asData?.value.unreadConversations ?? 0;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: IconButton(
        onPressed: () => context.pushNamed('chatInbox'),
        tooltip: 'Сообщения',
        icon: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Icon(
              Icons.chat_bubble_rounded,
              color: colorScheme.onSurface,
            ),
            if (unreadCount > 0)
              Positioned(
                right: -8,
                top: -6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  constraints: const BoxConstraints(minWidth: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.error,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onError,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
