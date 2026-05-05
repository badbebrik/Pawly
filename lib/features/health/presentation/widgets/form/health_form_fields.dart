import 'package:flutter/material.dart';

import '../../../../../design_system/design_system.dart';

class HealthFormTextField extends StatelessWidget {
  const HealthFormTextField({
    super.key,
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.validator,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final int maxLines;
  final FormFieldValidator<String>? validator;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      textCapitalization: textCapitalization,
      decoration: healthFormRowDecoration(label: label),
    );
  }
}

InputDecoration healthFormRowDecoration({required String label}) {
  return InputDecoration(
    labelText: label,
    filled: false,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: PawlySpacing.md,
      vertical: PawlySpacing.sm,
    ),
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
    errorBorder: InputBorder.none,
    focusedErrorBorder: InputBorder.none,
  );
}
