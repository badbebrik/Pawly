import 'package:flutter/material.dart';

class PetAvatarFallback extends StatelessWidget {
  const PetAvatarFallback({
    required this.colorScheme,
    this.iconSize = 46,
    super.key,
  });

  final ColorScheme colorScheme;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.pets_rounded,
        size: iconSize,
        color: colorScheme.primary,
      ),
    );
  }
}
