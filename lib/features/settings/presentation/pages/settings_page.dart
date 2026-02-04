import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../design_system/design_system.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        padding: const EdgeInsets.all(PawlySpacing.lg),
        children: <Widget>[
          PawlyCard(
            title: Text('Аккаунт', style: theme.textTheme.titleLarge),
            child: Text(
              'В этой вкладке можно разместить профиль, параметры уведомлений и служебные действия.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: PawlySpacing.md),
          PawlyCard(
            child: Column(
              children: const <Widget>[
                _SettingsRow(
                  icon: Icons.notifications_outlined,
                  title: 'Напоминания',
                  subtitle: 'Ветеринар, лекарства, груминг',
                ),
                Divider(),
                _SettingsRow(
                  icon: Icons.palette_outlined,
                  title: 'Оформление',
                  subtitle: 'Светлая и темная тема приложения',
                ),
                Divider(),
                _SettingsRow(
                  icon: Icons.shield_outlined,
                  title: 'Безопасность',
                  subtitle: 'Пароль, сессии и вход через провайдеров',
                ),
              ],
            ),
          ),
          const SizedBox(height: PawlySpacing.md),
          PawlyButton(
            label: 'Выйти из аккаунта',
            onPressed: () async {
              await ref.read(authRepositoryProvider).logout();
              if (context.mounted) {
                context.go(AppRoutes.login);
              }
            },
            variant: PawlyButtonVariant.secondary,
            icon: Icons.logout_rounded,
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: PawlySpacing.sm),
      child: Row(
        children: <Widget>[
          Icon(icon),
          const SizedBox(width: PawlySpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: PawlySpacing.xxxs),
                Text(subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}
