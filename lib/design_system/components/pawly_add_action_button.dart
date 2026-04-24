import 'package:flutter/material.dart';

import '../tokens/pawly_spacing.dart';

class PawlyAddActionButton extends StatelessWidget {
  const PawlyAddActionButton({
    super.key,
    required this.label,
    required this.onTap,
    this.tooltip,
    this.icon = Icons.add_rounded,
  });

  final String label;
  final VoidCallback onTap;
  final String? tooltip;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final button = Material(
      color: colorScheme.surface,
      elevation: 4,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.18),
      surfaceTintColor: Colors.transparent,
      shape: StadiumBorder(
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.8),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: SizedBox(
          height: 52,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(width: PawlySpacing.sm),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: colorScheme.onPrimary,
                  size: 22,
                ),
              ),
              const SizedBox(width: PawlySpacing.xs),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: PawlySpacing.md),
            ],
          ),
        ),
      ),
    );

    if (tooltip == null || tooltip!.isEmpty) {
      return button;
    }

    return Tooltip(message: tooltip!, child: button);
  }
}
