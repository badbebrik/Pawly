import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';

class ReminderAddButton extends StatelessWidget {
  const ReminderAddButton({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(PawlyRadius.pill),
      child: Ink(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.72),
          ),
        ),
        width: 42,
        height: 42,
        child: Icon(Icons.add_rounded, color: colorScheme.primary),
      ),
    );
  }
}
