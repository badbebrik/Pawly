import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';

class SettingsGroup extends StatelessWidget {
  const SettingsGroup({
    required this.children,
    super.key,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return PawlyListSection(children: children);
  }
}

class SettingsTile extends StatelessWidget {
  const SettingsTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PawlyListTile(
      title: title,
      subtitle: subtitle,
      onTap: onTap,
    );
  }
}
