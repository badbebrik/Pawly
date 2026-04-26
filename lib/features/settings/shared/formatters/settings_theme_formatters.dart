import 'package:flutter/material.dart';

String settingsThemeModeLabel(ThemeMode mode) {
  return switch (mode) {
    ThemeMode.system => 'Как в системе',
    ThemeMode.light => 'Светлая',
    ThemeMode.dark => 'Темная',
  };
}
