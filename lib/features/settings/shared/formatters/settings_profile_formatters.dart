import 'package:flutter/material.dart';

String settingsProfileFullName(String? firstName, String? lastName) {
  final parts = <String>[
    if (firstName != null && firstName.trim().isNotEmpty) firstName.trim(),
    if (lastName != null && lastName.trim().isNotEmpty) lastName.trim(),
  ];

  return parts.isEmpty ? 'Профиль Pawly' : parts.join(' ');
}

String settingsProfileInitials(String? firstName, String? lastName) {
  final buffer = StringBuffer();
  if (firstName != null && firstName.trim().isNotEmpty) {
    buffer.write(firstName.trim().characters.first.toUpperCase());
  }
  if (lastName != null && lastName.trim().isNotEmpty) {
    buffer.write(lastName.trim().characters.first.toUpperCase());
  }

  return buffer.isEmpty ? 'P' : buffer.toString();
}
