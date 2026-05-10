import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/design_system.dart';
import '../../controllers/settings_notification_controller.dart';
import '../../shared/formatters/settings_notification_formatters.dart';

Future<void> showNotificationSettingsSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => const _NotificationSettingsSheet(),
  );
  if (!context.mounted) {
    return;
  }
  try {
    await ref.read(settingsNotificationControllerProvider.notifier).reload();
  } catch (_) {}
}

class _NotificationSettingsSheet extends ConsumerWidget {
  const _NotificationSettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationState = ref.watch(settingsNotificationControllerProvider);
    final state = notificationState.asData?.value;
    final canRequest = state?.canRequest ?? false;
    final isGranted = state?.isGranted ?? false;
    final isRequesting = state?.isRequesting ?? false;
    final isOpeningSettings = state?.isOpeningSettings ?? false;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          PawlySpacing.lg,
          PawlySpacing.sm,
          PawlySpacing.lg,
          PawlySpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Уведомления',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: PawlySpacing.sm),
            Text(
              notificationState.when(
                data: (state) =>
                    settingsNotificationStatusLabel(state.notification),
                loading: () => 'Проверяем статус уведомлений на устройстве.',
                error: (_, __) => 'Не удалось получить статус уведомлений.',
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: PawlySpacing.lg),
            if (state != null && canRequest)
              PawlyButton(
                label:
                    isRequesting ? 'Запрашиваем...' : 'Разрешить уведомления',
                onPressed: isRequesting
                    ? null
                    : () => ref
                        .read(settingsNotificationControllerProvider.notifier)
                        .requestNotifications(),
                icon: Icons.notifications_active_rounded,
              ),
            if (state != null && !canRequest)
              PawlyButton(
                label: isOpeningSettings
                    ? 'Открываем...'
                    : 'Открыть настройки устройства',
                onPressed: isOpeningSettings
                    ? null
                    : () => _openDeviceSettings(context, ref),
                icon: Icons.open_in_new_rounded,
              ),
            if (isGranted) ...<Widget>[
              const SizedBox(height: PawlySpacing.sm),
              Text(
                'Уведомления на устройстве включены.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openDeviceSettings(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final opened = await ref
        .read(settingsNotificationControllerProvider.notifier)
        .openDeviceSettings();
    if (!opened && context.mounted) {
      showPawlySnackBar(
        context,
        message: 'Не удалось открыть настройки устройства',
        tone: PawlySnackBarTone.error,
      );
    }
  }
}
