import 'package:flutter/material.dart';

enum PawlyButtonVariant { primary, secondary, ghost }

class PawlyButton extends StatelessWidget {
  const PawlyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = PawlyButtonVariant.primary,
    this.icon,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final PawlyButtonVariant variant;
  final IconData? icon;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    Widget button = _buildButton();

    if (!fullWidth) {
      return button;
    }

    return SizedBox(width: double.infinity, child: button);
  }

  Widget _buildButton() {
    switch (variant) {
      case PawlyButtonVariant.primary:
        return icon == null
            ? FilledButton(onPressed: onPressed, child: Text(label))
            : FilledButton.icon(
                onPressed: onPressed,
                icon: Icon(icon),
                label: Text(label),
              );
      case PawlyButtonVariant.secondary:
        return icon == null
            ? OutlinedButton(onPressed: onPressed, child: Text(label))
            : OutlinedButton.icon(
                onPressed: onPressed,
                icon: Icon(icon),
                label: Text(label),
              );
      case PawlyButtonVariant.ghost:
        return icon == null
            ? TextButton(onPressed: onPressed, child: Text(label))
            : TextButton.icon(
                onPressed: onPressed,
                icon: Icon(icon),
                label: Text(label),
              );
    }
  }
}
