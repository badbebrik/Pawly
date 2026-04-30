import 'package:flutter/material.dart';

import '../tokens/pawly_colors.dart';
import '../tokens/pawly_radius.dart';

enum PawlySnackBarTone { neutral, success, warning, error, info }

void showPawlySnackBar(
  BuildContext context, {
  required String message,
  PawlySnackBarTone tone = PawlySnackBarTone.neutral,
  Duration duration = const Duration(seconds: 4),
  SnackBarAction? action,
}) {
  if (!context.mounted) {
    return;
  }

  final colorScheme = Theme.of(context).colorScheme;
  final colors = _snackBarColors(colorScheme, tone);

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: colors.foreground),
        ),
        action: action,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PawlyRadius.md),
        ),
      ),
    );
}

({Color background, Color foreground}) _snackBarColors(
  ColorScheme colorScheme,
  PawlySnackBarTone tone,
) {
  switch (tone) {
    case PawlySnackBarTone.neutral:
      return (
        background: colorScheme.inverseSurface,
        foreground: colorScheme.onInverseSurface,
      );
    case PawlySnackBarTone.success:
      return (
        background: PawlyColors.success,
        foreground: PawlyColors.white,
      );
    case PawlySnackBarTone.warning:
      return (
        background: PawlyColors.warning,
        foreground: PawlyColors.gray900,
      );
    case PawlySnackBarTone.error:
      return (
        background: colorScheme.error,
        foreground: colorScheme.onError,
      );
    case PawlySnackBarTone.info:
      return (
        background: PawlyColors.info,
        foreground: PawlyColors.white,
      );
  }
}
