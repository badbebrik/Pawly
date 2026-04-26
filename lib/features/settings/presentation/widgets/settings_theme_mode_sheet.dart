import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';

Future<ThemeMode?> showSettingsThemeModeSheet({
  required BuildContext context,
  required ThemeMode currentMode,
}) {
  return showPawlyBottomSheet<ThemeMode>(
    context: context,
    title: 'Тема приложения',
    builder: (context) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _ThemeModeOption(
            icon: Icons.brightness_auto_rounded,
            title: 'Как в системе',
            mode: ThemeMode.system,
            currentMode: currentMode,
          ),
          _ThemeModeOption(
            icon: Icons.light_mode_outlined,
            title: 'Светлая',
            mode: ThemeMode.light,
            currentMode: currentMode,
          ),
          _ThemeModeOption(
            icon: Icons.dark_mode_outlined,
            title: 'Темная',
            mode: ThemeMode.dark,
            currentMode: currentMode,
          ),
        ],
      );
    },
  );
}

class _ThemeModeOption extends StatelessWidget {
  const _ThemeModeOption({
    required this.icon,
    required this.title,
    required this.mode,
    required this.currentMode,
  });

  final IconData icon;
  final String title;
  final ThemeMode mode;
  final ThemeMode currentMode;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PawlyListTile(
      leadingIcon: icon,
      title: title,
      trailing: currentMode == mode
          ? Icon(
              Icons.check_rounded,
              color: colorScheme.primary,
            )
          : null,
      onTap: () => Navigator.of(context).pop(mode),
    );
  }
}
