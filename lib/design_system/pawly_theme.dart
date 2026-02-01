import 'package:flutter/material.dart';

import 'tokens/pawly_colors.dart';
import 'tokens/pawly_elevation.dart';
import 'tokens/pawly_motion.dart';
import 'tokens/pawly_radius.dart';
import 'tokens/pawly_spacing.dart';
import 'tokens/pawly_typography.dart';

class PawlyTheme {
  const PawlyTheme._();

  static ThemeData light() {
    return _buildTheme(PawlyColors.lightScheme);
  }

  static ThemeData dark() {
    return _buildTheme(PawlyColors.darkScheme);
  }

  static ThemeData _buildTheme(ColorScheme colorScheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: PawlyTypography.textTheme(colorScheme),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: PawlyElevation.level0,
        scrolledUnderElevation: PawlyElevation.level1,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: PawlyElevation.level1,
        shadowColor: colorScheme.shadow,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PawlyRadius.lg),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.primaryContainer,
        selectedColor: colorScheme.primary,
        disabledColor: colorScheme.onSurface.withValues(alpha: 0.12),
        secondarySelectedColor: colorScheme.secondaryContainer,
        padding: const EdgeInsets.symmetric(
          horizontal: PawlySpacing.sm,
          vertical: PawlySpacing.xs,
        ),
        labelStyle: TextStyle(color: colorScheme.onPrimaryContainer),
        secondaryLabelStyle: TextStyle(color: colorScheme.onSecondaryContainer),
        brightness: colorScheme.brightness,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PawlyRadius.pill),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: PawlySpacing.md,
          vertical: PawlySpacing.sm,
        ),
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PawlyRadius.md),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PawlyRadius.md),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PawlyRadius.md),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PawlyRadius.md),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(PawlyRadius.md),
          borderSide: BorderSide(color: colorScheme.error, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: PawlySpacing.md,
            vertical: PawlySpacing.sm,
          ),
          minimumSize: const Size(56, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PawlyRadius.md),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          animationDuration: PawlyMotion.standard,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: PawlySpacing.md,
            vertical: PawlySpacing.sm,
          ),
          minimumSize: const Size(56, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PawlyRadius.md),
          ),
          side: BorderSide(color: colorScheme.outline),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          animationDuration: PawlyMotion.standard,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: PawlySpacing.sm,
            vertical: PawlySpacing.xs,
          ),
          minimumSize: const Size(44, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(PawlyRadius.md),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          animationDuration: PawlyMotion.quick,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PawlyRadius.md),
        ),
      ),
    );
  }
}
