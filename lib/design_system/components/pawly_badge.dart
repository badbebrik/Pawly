import 'package:flutter/material.dart';

import '../tokens/pawly_colors.dart';
import '../tokens/pawly_radius.dart';
import '../tokens/pawly_spacing.dart';

enum PawlyBadgeTone { neutral, success, warning, error, info }

class PawlyBadge extends StatelessWidget {
  const PawlyBadge({
    super.key,
    required this.label,
    this.tone = PawlyBadgeTone.neutral,
  });

  final String label;
  final PawlyBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final _BadgePalette palette = _paletteForTone(tone);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: PawlySpacing.sm,
        vertical: PawlySpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(PawlyRadius.pill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: palette.foreground,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  _BadgePalette _paletteForTone(PawlyBadgeTone tone) {
    switch (tone) {
      case PawlyBadgeTone.neutral:
        return const _BadgePalette(
          background: PawlyColors.gray100,
          foreground: PawlyColors.gray700,
        );
      case PawlyBadgeTone.success:
        return const _BadgePalette(
          background: Color(0xFFE4F5EE),
          foreground: PawlyColors.success,
        );
      case PawlyBadgeTone.warning:
        return const _BadgePalette(
          background: Color(0xFFFFF1DD),
          foreground: PawlyColors.warning,
        );
      case PawlyBadgeTone.error:
        return const _BadgePalette(
          background: Color(0xFFFEE7E7),
          foreground: PawlyColors.error,
        );
      case PawlyBadgeTone.info:
        return const _BadgePalette(
          background: Color(0xFFE5F1FD),
          foreground: PawlyColors.info,
        );
    }
  }
}

class _BadgePalette {
  const _BadgePalette({
    required this.background,
    required this.foreground,
  });

  final Color background;
  final Color foreground;
}
