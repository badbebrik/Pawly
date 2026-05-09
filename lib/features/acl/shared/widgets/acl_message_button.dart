import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';

class AclMessageButton extends StatelessWidget {
  const AclMessageButton({
    required this.onTap,
    this.size = 40,
    this.iconSize = 20,
    super.key,
  });

  final VoidCallback onTap;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(PawlyRadius.pill),
      child: Ink(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.48),
          shape: BoxShape.circle,
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.64),
          ),
        ),
        child: Icon(
          CupertinoIcons.chat_bubble_text,
          size: iconSize,
          color: colorScheme.primary,
        ),
      ),
    );
  }
}
