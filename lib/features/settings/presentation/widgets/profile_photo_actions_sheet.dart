import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/design_system.dart';
import '../../controllers/settings_profile_controller.dart';
import '../../models/settings_profile.dart';

Future<void> showProfilePhotoActionsSheet(
  BuildContext context,
  WidgetRef ref,
  SettingsProfile profile,
) async {
  final hasPhoto = profile.hasAvatar;
  final pageContext = context;

  await showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(PawlyRadius.xl)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            PawlySpacing.md,
            PawlySpacing.md,
            PawlySpacing.md,
            PawlySpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Выбрать из галереи'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _runProfilePhotoAction(
                    context: pageContext,
                    fallbackMessage: 'Не удалось установить фото профиля.',
                    action: () => ref
                        .read(settingsProfileControllerProvider.notifier)
                        .uploadPhotoFromGallery(),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded),
                title: const Text('Сделать фото'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _runProfilePhotoAction(
                    context: pageContext,
                    fallbackMessage: 'Не удалось установить фото профиля.',
                    action: () => ref
                        .read(settingsProfileControllerProvider.notifier)
                        .uploadPhotoFromCamera(),
                  );
                },
              ),
              if (hasPhoto) ...<Widget>[
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.delete_outline_rounded,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    'Удалить фото',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await _runProfilePhotoAction(
                      context: pageContext,
                      fallbackMessage: 'Не удалось удалить фото профиля.',
                      action: () => ref
                          .read(settingsProfileControllerProvider.notifier)
                          .deletePhoto(),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _runProfilePhotoAction({
  required BuildContext context,
  required String fallbackMessage,
  required Future<void> Function() action,
}) async {
  try {
    await action();
  } catch (error) {
    if (context.mounted) {
      showPawlySnackBar(
        context,
        message:
            error is StateError ? error.message.toString() : fallbackMessage,
        tone: PawlySnackBarTone.error,
      );
    }
  }
}
