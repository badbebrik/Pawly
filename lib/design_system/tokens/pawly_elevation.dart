import 'package:flutter/material.dart';

class PawlyElevation {
  const PawlyElevation._();

  static const double level0 = 0;
  static const double level1 = 1;
  static const double level2 = 3;
  static const double level3 = 6;

  static List<BoxShadow> soft(Color shadowColor) {
    return <BoxShadow>[
      BoxShadow(
        color: shadowColor.withValues(alpha: 0.08),
        offset: const Offset(0, 4),
        blurRadius: 12,
      ),
      BoxShadow(
        color: shadowColor.withValues(alpha: 0.04),
        offset: const Offset(0, 1),
        blurRadius: 2,
      ),
    ];
  }
}
