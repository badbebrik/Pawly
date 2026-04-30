import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';

class ChatMessageComposer extends StatelessWidget {
  const ChatMessageComposer({
    required this.controller,
    required this.canSend,
    required this.isSending,
    required this.onSend,
    super.key,
  });

  final TextEditingController controller;
  final bool canSend;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          PawlySpacing.md,
          PawlySpacing.xs,
          PawlySpacing.md,
          PawlySpacing.sm,
        ),
        decoration: BoxDecoration(
          color: pawlyGroupedBackground(context),
          border: Border(
            top: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.72),
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: controller,
                enabled: canSend,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText:
                      canSend ? 'Напишите сообщение' : 'Отправка недоступна',
                  filled: true,
                  fillColor: colorScheme.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: PawlySpacing.md,
                    vertical: PawlySpacing.sm,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(PawlyRadius.xl),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(PawlyRadius.xl),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(PawlyRadius.xl),
                    borderSide: BorderSide(
                      color: colorScheme.primary.withValues(alpha: 0.28),
                    ),
                  ),
                ),
                onSubmitted: canSend && !isSending ? (_) => onSend() : null,
              ),
            ),
            const SizedBox(width: PawlySpacing.sm),
            SizedBox(
              width: 44,
              height: 44,
              child: IconButton(
                onPressed: canSend && !isSending ? onSend : null,
                padding: EdgeInsets.zero,
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  disabledBackgroundColor:
                      colorScheme.onSurface.withValues(alpha: 0.08),
                  foregroundColor: colorScheme.onPrimary,
                  disabledForegroundColor: colorScheme.onSurfaceVariant,
                ),
                icon: isSending
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.onPrimary,
                        ),
                      )
                    : const Icon(Icons.arrow_upward_rounded, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
