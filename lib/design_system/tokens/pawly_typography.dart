import 'package:flutter/material.dart';

class PawlyTypography {
  const PawlyTypography._();

  static const String primaryFontFamily = 'SF Pro Text';
  static const String fallbackFontFamily = 'Roboto';

  static TextTheme textTheme(ColorScheme colorScheme) {
    const TextTheme base = TextTheme(
      displayLarge: TextStyle(
        fontSize: 40,
        height: 1.1,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
      ),
      displayMedium: TextStyle(
        fontSize: 34,
        height: 1.15,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      headlineLarge: TextStyle(
        fontSize: 30,
        height: 1.2,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        height: 1.25,
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: TextStyle(
        fontSize: 20,
        height: 1.25,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        height: 1.3,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        height: 1.35,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        height: 1.35,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        height: 1.45,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.45,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        height: 1.4,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        height: 1.2,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        height: 1.2,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        height: 1.2,
        fontWeight: FontWeight.w600,
      ),
    );

    return base
        .apply(
          bodyColor: colorScheme.onSurface,
          displayColor: colorScheme.onSurface,
        )
        .copyWith(
          displayLarge: base.displayLarge?.copyWith(
            fontFamily: primaryFontFamily,
            fontFamilyFallback: const <String>[fallbackFontFamily],
          ),
          displayMedium: base.displayMedium?.copyWith(
            fontFamily: primaryFontFamily,
            fontFamilyFallback: const <String>[fallbackFontFamily],
          ),
          headlineLarge: base.headlineLarge?.copyWith(
            fontFamily: primaryFontFamily,
            fontFamilyFallback: const <String>[fallbackFontFamily],
          ),
          headlineMedium: base.headlineMedium?.copyWith(
            fontFamily: primaryFontFamily,
            fontFamilyFallback: const <String>[fallbackFontFamily],
          ),
          headlineSmall: base.headlineSmall?.copyWith(
            fontFamily: primaryFontFamily,
            fontFamilyFallback: const <String>[fallbackFontFamily],
          ),
          titleLarge: base.titleLarge?.copyWith(
            fontFamily: primaryFontFamily,
            fontFamilyFallback: const <String>[fallbackFontFamily],
          ),
          titleMedium: base.titleMedium?.copyWith(
            fontFamily: primaryFontFamily,
            fontFamilyFallback: const <String>[fallbackFontFamily],
          ),
          titleSmall: base.titleSmall?.copyWith(
            fontFamily: primaryFontFamily,
            fontFamilyFallback: const <String>[fallbackFontFamily],
          ),
          bodyLarge: base.bodyLarge?.copyWith(
            fontFamily: primaryFontFamily,
            fontFamilyFallback: const <String>[fallbackFontFamily],
          ),
          bodyMedium: base.bodyMedium?.copyWith(
            fontFamily: primaryFontFamily,
            fontFamilyFallback: const <String>[fallbackFontFamily],
          ),
          bodySmall: base.bodySmall?.copyWith(
            fontFamily: primaryFontFamily,
            fontFamilyFallback: const <String>[fallbackFontFamily],
          ),
          labelLarge: base.labelLarge?.copyWith(
            fontFamily: primaryFontFamily,
            fontFamilyFallback: const <String>[fallbackFontFamily],
          ),
          labelMedium: base.labelMedium?.copyWith(
            fontFamily: primaryFontFamily,
            fontFamilyFallback: const <String>[fallbackFontFamily],
          ),
          labelSmall: base.labelSmall?.copyWith(
            fontFamily: primaryFontFamily,
            fontFamilyFallback: const <String>[fallbackFontFamily],
          ),
        );
  }
}
