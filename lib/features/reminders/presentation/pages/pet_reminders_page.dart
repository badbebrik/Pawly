import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/design_system.dart';
import '../../../pets/controllers/pets_controller.dart';
import '../../controllers/reminders_controller.dart';
import '../widgets/reminder_add_button.dart';
import '../widgets/reminders_list_view.dart';
import '../widgets/reminders_state_views.dart';

class PetRemindersPage extends ConsumerWidget {
  const PetRemindersPage({required this.petId, super.key});

  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessAsync = ref.watch(petAccessPolicyProvider(petId));

    return accessAsync.when(
      data: (access) {
        if (!access.remindersRead) {
          return const PawlyScreenScaffold(
            title: 'Напоминания',
            body: ReminderNoAccessView(),
          );
        }

        final remindersAsync = ref.watch(
          petRemindersControllerProvider(petId),
        );
        final pushSettingsAsync =
            ref.watch(reminderPushSettingsProvider(petId));

        return PawlyScreenScaffold(
          title: 'Напоминания',
          actions: <Widget>[
            if (access.remindersWrite) ...<Widget>[
              ReminderAddButton(
                onTap: () async {
                  final created = await context.pushNamed<bool>(
                    'petReminderCreate',
                    pathParameters: <String, String>{'petId': petId},
                  );
                  if (created == true) {
                    ref.invalidate(petRemindersControllerProvider(petId));
                  }
                },
              ),
              const SizedBox(width: PawlySpacing.sm),
            ],
          ],
          body: remindersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => ReminderErrorView(
              onRetry: () =>
                  ref.invalidate(petRemindersControllerProvider(petId)),
            ),
            data: (items) => RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(petRemindersControllerProvider(petId));
                await ref.read(petRemindersControllerProvider(petId).future);
              },
              child: RemindersListView(
                petId: petId,
                access: access,
                items: items,
                pushSettingsAsync: pushSettingsAsync,
              ),
            ),
          ),
        );
      },
      loading: () => const PawlyScreenScaffold(
        title: 'Напоминания',
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => PawlyScreenScaffold(
        title: 'Напоминания',
        body: ReminderErrorView(
          onRetry: () => ref.invalidate(petAccessPolicyProvider(petId)),
        ),
      ),
    );
  }
}
