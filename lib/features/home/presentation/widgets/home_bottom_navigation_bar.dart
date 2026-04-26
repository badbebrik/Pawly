import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';

class HomeBottomNavigationBar extends StatelessWidget {
  const HomeBottomNavigationBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  static const List<_HomeNavigationItem> _items = <_HomeNavigationItem>[
    _HomeNavigationItem(
      icon: Icons.calendar_today_outlined,
      selectedIcon: Icons.calendar_today_rounded,
      label: 'Календарь',
    ),
    _HomeNavigationItem(
      icon: Icons.pets_outlined,
      selectedIcon: Icons.pets_rounded,
      label: 'Питомцы',
    ),
    _HomeNavigationItem(
      icon: Icons.tune_rounded,
      selectedIcon: Icons.tune_rounded,
      label: 'Настройки',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(
          PawlySpacing.md,
          PawlySpacing.xs,
          PawlySpacing.md,
          PawlySpacing.sm,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(PawlyRadius.xl),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(PawlyRadius.xl),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.64),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(PawlySpacing.xxs),
                child: Row(
                  children: List<Widget>.generate(_items.length, (index) {
                    return Expanded(
                      child: _HomeNavigationTile(
                        item: _items[index],
                        isSelected: index == selectedIndex,
                        onTap: () => onDestinationSelected(index),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeNavigationTile extends StatelessWidget {
  const _HomeNavigationTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final _HomeNavigationItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final foregroundColor =
        isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant;

    return Semantics(
      selected: isSelected,
      button: true,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PawlyRadius.lg),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          height: 58,
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary.withValues(alpha: 0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(PawlyRadius.lg),
          ),
          padding: const EdgeInsets.symmetric(horizontal: PawlySpacing.xs),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                isSelected ? item.selectedIcon : item.icon,
                size: 23,
                color: foregroundColor,
              ),
              const SizedBox(height: PawlySpacing.xxs),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: foregroundColor,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeNavigationItem {
  const _HomeNavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
