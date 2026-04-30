import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/design_system.dart';
import '../../controllers/active_pet_controller.dart';
import '../../controllers/active_pet_details_controller.dart';
import '../../models/pet.dart';

Future<void> showActivePetActionsSheet(
  BuildContext context,
  WidgetRef ref, {
  required String petName,
  required bool canArchive,
}) async {
  await showPawlyBottomSheet<void>(
    context: context,
    builder: (sheetContext) {
      final colorScheme = Theme.of(sheetContext).colorScheme;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.swap_horiz_rounded),
            title: const Text('Сменить питомца'),
            onTap: () async {
              Navigator.of(sheetContext).pop();
              await ref.read(activePetControllerProvider.notifier).clear();
            },
          ),
          ListTile(
            leading: const Icon(Icons.archive_outlined),
            iconColor: colorScheme.error,
            textColor: colorScheme.error,
            title: const Text('Архивировать питомца'),
            enabled: canArchive,
            subtitle:
                canArchive ? null : const Text('Редактирование недоступно'),
            onTap: canArchive
                ? () async {
                    Navigator.of(sheetContext).pop();
                    await _archiveActivePet(context, ref, petName);
                  }
                : null,
          ),
        ],
      );
    },
  );
}

Future<void> showPetPhotoActionsSheet(
  BuildContext context,
  WidgetRef ref,
  Pet pet,
) async {
  final hasPhoto = (pet.profilePhotoFileId ?? '').isNotEmpty ||
      (pet.profilePhotoDownloadUrl ?? '').isNotEmpty;
  final pageContext = context;

  await showPawlyBottomSheet<void>(
    context: context,
    builder: (sheetContext) {
      final colorScheme = Theme.of(sheetContext).colorScheme;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.photo_library_rounded),
            title: const Text('Выбрать из галереи'),
            onTap: () async {
              Navigator.of(sheetContext).pop();
              await _uploadPetPhotoFromGallery(pageContext, ref);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_rounded),
            title: const Text('Сделать фото'),
            onTap: () async {
              Navigator.of(sheetContext).pop();
              await _uploadPetPhotoFromCamera(pageContext, ref);
            },
          ),
          if (hasPhoto) ...<Widget>[
            const Divider(height: 1),
            ListTile(
              leading: Icon(
                Icons.delete_outline_rounded,
                color: colorScheme.error,
              ),
              title: Text(
                'Удалить фото',
                style: TextStyle(color: colorScheme.error),
              ),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                await _deletePetPhoto(pageContext, ref);
              },
            ),
          ],
        ],
      );
    },
  );
}

Future<void> _archiveActivePet(
  BuildContext context,
  WidgetRef ref,
  String petName,
) async {
  final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Архивировать питомца?'),
          content: Text(
            '$petName исчезнет из списка активных питомцев и будет доступен в архиве.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Архивировать'),
            ),
          ],
        ),
      ) ??
      false;
  if (!confirmed || !context.mounted) {
    return;
  }

  try {
    await ref.read(activePetDetailsControllerProvider.notifier).archivePet();
    if (context.mounted) {
      showPawlySnackBar(
        context,
        message: '$petName перемещен в архив.',
        tone: PawlySnackBarTone.success,
      );
    }
  } catch (error) {
    if (context.mounted) {
      showPawlySnackBar(
        context,
        message: error is StateError
            ? error.message.toString()
            : 'Не удалось архивировать питомца.',
        tone: PawlySnackBarTone.error,
      );
    }
  }
}

Future<void> _uploadPetPhotoFromGallery(
  BuildContext context,
  WidgetRef ref,
) async {
  try {
    await ref
        .read(activePetDetailsControllerProvider.notifier)
        .uploadPhotoFromGallery();
  } catch (error) {
    if (context.mounted) {
      showPawlySnackBar(
        context,
        message: error is StateError
            ? error.message.toString()
            : 'Не удалось установить фото питомца.',
        tone: PawlySnackBarTone.error,
      );
    }
  }
}

Future<void> _uploadPetPhotoFromCamera(
  BuildContext context,
  WidgetRef ref,
) async {
  try {
    await ref
        .read(activePetDetailsControllerProvider.notifier)
        .uploadPhotoFromCamera();
  } catch (error) {
    if (context.mounted) {
      showPawlySnackBar(
        context,
        message: error is StateError
            ? error.message.toString()
            : 'Не удалось установить фото питомца.',
        tone: PawlySnackBarTone.error,
      );
    }
  }
}

Future<void> _deletePetPhoto(
  BuildContext context,
  WidgetRef ref,
) async {
  try {
    await ref.read(activePetDetailsControllerProvider.notifier).deletePhoto();
  } catch (error) {
    if (context.mounted) {
      showPawlySnackBar(
        context,
        message: error is StateError
            ? error.message.toString()
            : 'Не удалось удалить фото питомца.',
        tone: PawlySnackBarTone.error,
      );
    }
  }
}
