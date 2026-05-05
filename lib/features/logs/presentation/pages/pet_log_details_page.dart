import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/design_system.dart';
import '../../controllers/log_details_controller.dart';
import '../../models/log_models.dart';
import '../../models/log_refs.dart';
import '../widgets/log_details_blocks.dart';

class PetLogDetailsPage extends ConsumerWidget {
  const PetLogDetailsPage({
    required this.petId,
    required this.logId,
    super.key,
  });

  final String petId;
  final String logId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logRef = PetLogRef(petId: petId, logId: logId);
    final logAsync = ref.watch(
      petLogDetailsControllerProvider(logRef),
    );

    return PawlyScreenScaffold(
      title: 'Запись',
      actions: logAsync.maybeWhen(
        data: (log) => <Widget>[
          if (log.canEdit)
            IconButton(
              onPressed: () async {
                final updated = await context.pushNamed<bool>(
                  'petLogEdit',
                  pathParameters: <String, String>{
                    'petId': petId,
                    'logId': logId,
                  },
                );
                if (updated == true && context.mounted) {
                  await ref
                      .read(petLogDetailsControllerProvider(logRef).notifier)
                      .reload();
                }
              },
              icon: const Icon(Icons.edit_rounded),
              tooltip: 'Редактировать',
            ),
          if (log.canDelete)
            IconButton(
              onPressed: () => _deleteLog(context, ref, log),
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Удалить',
            ),
        ],
        orElse: () => const <Widget>[],
      ),
      body: logAsync.when(
        data: (log) => LogDetailsContentView(
          log: log,
          onRefresh: () => ref
              .read(petLogDetailsControllerProvider(logRef).notifier)
              .reload(),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => LogDetailsErrorView(
          onRetry: () => ref
              .read(petLogDetailsControllerProvider(logRef).notifier)
              .reload(),
        ),
      ),
    );
  }

  Future<void> _deleteLog(
    BuildContext context,
    WidgetRef ref,
    LogDetails log,
  ) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Удалить запись?'),
              content: const Text(
                'Запись будет удалена из журнала питомца. Это действие нельзя отменить.',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Отмена'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Удалить'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed || !context.mounted) {
      return;
    }

    try {
      await ref
          .read(
            petLogDetailsControllerProvider(
              PetLogRef(petId: petId, logId: logId),
            ).notifier,
          )
          .delete(rowVersion: log.rowVersion);
      if (!context.mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      showPawlySnackBar(
        context,
        message: error is StateError
            ? error.message.toString()
            : 'Не удалось удалить запись.',
        tone: PawlySnackBarTone.error,
      );
    }
  }
}
