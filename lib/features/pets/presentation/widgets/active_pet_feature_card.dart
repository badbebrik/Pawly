import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';

class ActivePetFeatureCard extends StatelessWidget {
  const ActivePetFeatureCard({
    required this.title,
    required this.icon,
    this.tint,
    this.onTap,
    this.statusLabel,
    super.key,
  });

  final String title;
  final IconData icon;
  final Color? tint;
  final VoidCallback? onTap;
  final String? statusLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = tint ?? colorScheme.primary;
    final isEnabled = onTap != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PawlyRadius.xl),
        child: Ink(
          padding: const EdgeInsets.all(PawlySpacing.md),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(PawlyRadius.xl),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.72),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(PawlyRadius.md),
                    ),
                    child: Icon(
                      icon,
                      size: 24,
                      color: isEnabled
                          ? accent
                          : colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.54),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    isEnabled
                        ? Icons.arrow_outward_rounded
                        : Icons.lock_outline_rounded,
                    size: 20,
                    color: colorScheme.onSurfaceVariant.withValues(
                      alpha: isEnabled ? 1 : 0.54,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isEnabled
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              if (statusLabel != null && statusLabel!.isNotEmpty) ...<Widget>[
                const SizedBox(height: PawlySpacing.xxxs),
                Text(
                  statusLabel!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ActivePetWideFeatureCard extends StatelessWidget {
  const ActivePetWideFeatureCard({
    required this.title,
    required this.icon,
    this.subtitle,
    this.tint,
    this.onTap,
    super.key,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Color? tint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = tint ?? colorScheme.primary;
    final isEnabled = onTap != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PawlyRadius.xl),
        child: Ink(
          padding: const EdgeInsets.all(PawlySpacing.md),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(PawlyRadius.xl),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.72),
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(PawlyRadius.md),
                ),
                child: Icon(
                  icon,
                  color: isEnabled
                      ? accent
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.54),
                ),
              ),
              const SizedBox(width: PawlySpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isEnabled
                            ? colorScheme.onSurface
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...<Widget>[
                      const SizedBox(height: PawlySpacing.xxxs),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: PawlySpacing.sm),
              Icon(
                isEnabled
                    ? Icons.arrow_outward_rounded
                    : Icons.lock_outline_rounded,
                size: 20,
                color: colorScheme.onSurfaceVariant.withValues(
                  alpha: isEnabled ? 1 : 0.54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
