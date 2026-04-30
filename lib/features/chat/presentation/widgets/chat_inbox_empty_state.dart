import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';

class ChatInboxEmptyState extends StatelessWidget {
  const ChatInboxEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        PawlySpacing.lg,
        PawlySpacing.xl,
        PawlySpacing.lg,
        PawlySpacing.xl,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(PawlyRadius.xl),
      ),
      child: Column(
        children: <Widget>[
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 38,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.72),
          ),
          const SizedBox(height: PawlySpacing.md),
          Text(
            'У вас пока нет чатов',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: PawlySpacing.xs),
          Text(
            'Откройте диалог из списка участников питомца.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
