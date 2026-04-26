import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers/theme_mode_controller.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../design_system/design_system.dart';
import '../../../chat/presentation/widgets/chat_app_bar_action.dart';
import '../../controllers/settings_notification_controller.dart';
import '../../controllers/settings_profile_controller.dart';
import '../../controllers/settings_security_controller.dart';
import '../../shared/formatters/settings_notification_formatters.dart';
import '../../shared/formatters/settings_profile_formatters.dart';
import '../../shared/formatters/settings_theme_formatters.dart';
import '../widgets/settings_list_widgets.dart';
import '../widgets/notification_settings_sheet.dart';
import '../widgets/profile_photo_actions_sheet.dart';
import '../widgets/profile_settings_sheet.dart';
import '../widgets/security_settings_sheet.dart';
import '../widgets/settings_profile_header.dart';
import '../widgets/settings_theme_mode_sheet.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(settingsProfileControllerProvider);
    final profile = profileState.whenOrNull(data: (state) => state.profile);
    final themeMode = ref.watch(themeModeControllerProvider).asData?.value ??
        ThemeMode.system;
    final notificationState = ref.watch(settingsNotificationControllerProvider);
    final securityState = ref.watch(settingsSecurityControllerProvider);

    return PawlyScreenScaffold(
      title: 'Настройки',
      actions: const <Widget>[
        ChatAppBarAction(),
      ],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          PawlySpacing.md,
          PawlySpacing.sm,
          PawlySpacing.md,
          PawlySpacing.xl,
        ),
        children: <Widget>[
          profileState.when(
            data: (state) => SettingsProfileHeader(
              profile: state.profile,
              isUploadingPhoto: state.isUploadingPhoto,
              onAvatarTap: () => showProfilePhotoActionsSheet(
                context,
                ref,
                state.profile,
              ),
            ),
            loading: SettingsProfileHeader.loading,
            error: (_, __) => SettingsProfileHeader.error(
              onRetry: () =>
                  ref.read(settingsProfileControllerProvider.notifier).reload(),
            ),
          ),
          const SizedBox(height: PawlySpacing.md),
          SettingsGroup(
            children: <Widget>[
              SettingsTile(
                title: 'Профиль',
                subtitle: profile == null
                    ? 'Имя и фамилия'
                    : settingsProfileFullName(
                        profile.firstName,
                        profile.lastName,
                      ),
                onTap: profile == null
                    ? null
                    : () => showProfileSettingsSheet(context, profile),
              ),
              SettingsTile(
                title: 'Тема',
                subtitle: settingsThemeModeLabel(themeMode),
                onTap: () async {
                  final selectedMode = await showSettingsThemeModeSheet(
                    context: context,
                    currentMode: themeMode,
                  );
                  if (selectedMode == null) {
                    return;
                  }

                  await ref
                      .read(themeModeControllerProvider.notifier)
                      .setThemeMode(selectedMode);
                },
              ),
              SettingsTile(
                title: 'Уведомления',
                subtitle: notificationState.when(
                  data: (state) =>
                      settingsNotificationStatusLabel(state.notification),
                  loading: () => 'Проверяем статус устройства',
                  error: (_, __) => 'Не удалось определить статус',
                ),
                onTap: () => showNotificationSettingsSheet(context, ref),
              ),
              SettingsTile(
                title: 'Безопасность',
                subtitle: 'Смена пароля',
                onTap: () => showSecuritySettingsSheet(context),
              ),
            ],
          ),
          const SizedBox(height: PawlySpacing.md),
          PawlyButton(
            label:
                securityState.isLoggingOut ? 'Выходим...' : 'Выйти из аккаунта',
            onPressed: securityState.isLoggingOut
                ? null
                : () async {
                    await ref
                        .read(settingsSecurityControllerProvider.notifier)
                        .logout();
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
