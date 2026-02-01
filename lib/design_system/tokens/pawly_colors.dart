import 'package:flutter/material.dart';

class PawlyColors {
  const PawlyColors._();

  static const Color mint500 = Color(0xFF2E8B7D);
  static const Color mint300 = Color(0xFF76C8B9);
  static const Color mint100 = Color(0xFFD9F2ED);

  static const Color sand500 = Color(0xFFE6A86A);
  static const Color sand300 = Color(0xFFF2C698);
  static const Color sand100 = Color(0xFFFBEBDD);

  static const Color sky500 = Color(0xFF57A3D9);
  static const Color sky100 = Color(0xFFE2F2FD);

  static const Color gray900 = Color(0xFF1F2933);
  static const Color gray700 = Color(0xFF52606D);
  static const Color gray500 = Color(0xFF9AA5B1);
  static const Color gray300 = Color(0xFFD9E2EC);
  static const Color gray100 = Color(0xFFF6F9FC);
  static const Color white = Color(0xFFFFFFFF);

  static const Color success = Color(0xFF2D9D78);
  static const Color warning = Color(0xFFF3A53C);
  static const Color error = Color(0xFFD64545);
  static const Color info = Color(0xFF3D87D8);

  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: mint500,
    onPrimary: white,
    primaryContainer: mint100,
    onPrimaryContainer: Color(0xFF053931),
    secondary: sand500,
    onSecondary: Color(0xFF3D240A),
    secondaryContainer: sand100,
    onSecondaryContainer: Color(0xFF593610),
    tertiary: sky500,
    onTertiary: white,
    tertiaryContainer: sky100,
    onTertiaryContainer: Color(0xFF113956),
    error: error,
    onError: white,
    errorContainer: Color(0xFFFFDAD5),
    onErrorContainer: Color(0xFF410001),
    surface: white,
    onSurface: gray900,
    onSurfaceVariant: gray700,
    outline: gray300,
    outlineVariant: Color(0xFFE8EDF3),
    shadow: Color(0x1A000000),
    scrim: Color(0x66000000),
    inverseSurface: gray900,
    onInverseSurface: gray100,
    inversePrimary: mint300,
    surfaceTint: mint500,
  );

  static const ColorScheme darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: mint300,
    onPrimary: Color(0xFF0A3E36),
    primaryContainer: Color(0xFF1C6458),
    onPrimaryContainer: mint100,
    secondary: sand300,
    onSecondary: Color(0xFF4A2C0E),
    secondaryContainer: Color(0xFF65411E),
    onSecondaryContainer: Color(0xFFFFE1C5),
    tertiary: Color(0xFF98CFF4),
    onTertiary: Color(0xFF123A57),
    tertiaryContainer: Color(0xFF2C5B7A),
    onTertiaryContainer: sky100,
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: Color(0xFF101B22),
    onSurface: Color(0xFFE7EDF3),
    onSurfaceVariant: Color(0xFFC4CFDA),
    outline: Color(0xFF6E7B87),
    outlineVariant: Color(0xFF3A4752),
    shadow: Color(0x40000000),
    scrim: Color(0x99000000),
    inverseSurface: Color(0xFFE7EDF3),
    onInverseSurface: Color(0xFF101B22),
    inversePrimary: mint500,
    surfaceTint: mint300,
  );
}
