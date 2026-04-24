import 'package:flutter/material.dart';

import '../tokens/pawly_radius.dart';
import '../tokens/pawly_spacing.dart';

class PawlyPickerRow extends StatelessWidget {
  const PawlyPickerRow({
    super.key,
    required this.title,
    required this.value,
    this.actionLabel,
    this.leadingIcon,
    this.onTap,
    this.enabled = true,
  });

  final String title;
  final String value;
  final String? actionLabel;
  final IconData? leadingIcon;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final secondaryColor = enabled
        ? colorScheme.onSurfaceVariant
        : colorScheme.onSurface.withValues(alpha: 0.38);

    final content = Container(
      padding: const EdgeInsets.all(PawlySpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(PawlyRadius.lg),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: <Widget>[
          if (leadingIcon != null) ...<Widget>[
            Icon(leadingIcon, color: secondaryColor),
            const SizedBox(width: PawlySpacing.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: secondaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: PawlySpacing.xxs),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: enabled
                        ? colorScheme.onSurface
                        : colorScheme.onSurface.withValues(alpha: 0.38),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (actionLabel != null) ...<Widget>[
            const SizedBox(width: PawlySpacing.sm),
            Text(
              actionLabel!,
              style: theme.textTheme.labelLarge?.copyWith(
                color: enabled ? colorScheme.primary : secondaryColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap == null || !enabled) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(PawlyRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PawlyRadius.lg),
        child: content,
      ),
    );
  }
}
