import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/feature_flags.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../design_system/design_system.dart';
import '../../../chat/presentation/widgets/chat_app_bar_action.dart';
import '../../controllers/active_pet_controller.dart';
import '../../controllers/active_pet_details_controller.dart';
import '../../controllers/pets_controller.dart';
import '../../models/pet_list_entry.dart';
import '../../shared/widgets/pets_error_view.dart';
import '../widgets/add_pet_actions_sheet.dart';
import '../widgets/join_pet_by_code_dialog.dart';
import '../widgets/pets_list_view.dart';

class PetsPage extends ConsumerWidget {
  const PetsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petsStateAsync = ref.watch(petsControllerProvider);

    return PawlyScreenScaffold(
      title: 'Питомцы',
      actions: const <Widget>[
        if (PawlyFeatureFlags.chatEnabled) ChatAppBarAction(),
      ],
      floatingActionButton: PawlyAddActionButton(
        label: 'Добавить',
        tooltip: 'Добавить питомца',
        onTap: () => showAddPetActionsSheet(
          context: context,
          onCreatePet: () => context.push(AppRoutes.petCreate),
          onJoinByCode: () => _showJoinByCodeDialog(context, ref),
        ),
      ),
      body: petsStateAsync.when(
        data: (petsState) {
          return PetsListView(
            state: petsState,
            onSearchChanged:
                ref.read(petsControllerProvider.notifier).setSearchQuery,
            onStatusBucketChanged:
                ref.read(petsControllerProvider.notifier).setStatusBucket,
            onOwnershipFilterChanged:
                ref.read(petsControllerProvider.notifier).setOwnershipFilter,
            onPetSelected: (entry) => context.pushNamed(
              'petDetails',
              pathParameters: <String, String>{'petId': entry.id},
            ),
            onRestorePet: (entry) =>
                _restorePetFromArchive(context, ref, entry),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => PetsErrorView(
          message: 'Не удалось загрузить питомцев.',
          onRetry: () => ref.read(petsControllerProvider.notifier).reload(),
        ),
      ),
    );
  }
}

Future<void> _restorePetFromArchive(
  BuildContext context,
  WidgetRef ref,
  PetListEntry entry,
) async {
  try {
    await ref.read(petsControllerProvider.notifier).changePetStatus(
          pet: entry.pet,
          status: 'ACTIVE',
        );
    if (!context.mounted) return;
    showPawlySnackBar(
      context,
      message: '${entry.name} возвращен в активные.',
      tone: PawlySnackBarTone.success,
    );
  } catch (error) {
    if (!context.mounted) return;
    showPawlySnackBar(
      context,
      message: error is StateError
          ? error.message.toString()
          : 'Не удалось вернуть питомца из архива.',
      tone: PawlySnackBarTone.error,
    );
  }
}

Future<void> _showJoinByCodeDialog(BuildContext context, WidgetRef ref) async {
  final acceptedPetId = await showDialog<String>(
    context: context,
    builder: (_) => const JoinPetByCodeDialog(),
  );

  if (acceptedPetId == null || !context.mounted) {
    return;
  }

  try {
    await ref.read(activePetControllerProvider.notifier).selectPet(
          acceptedPetId,
        );
    ref.invalidate(activePetDetailsControllerProvider(acceptedPetId));
    if (!context.mounted) {
      return;
    }
    context.pushNamed(
      'petDetails',
      pathParameters: <String, String>{'petId': acceptedPetId},
    );
  } catch (error) {
    if (context.mounted) {
      showPawlySnackBar(
        context,
        message: acceptInviteByCodeErrorMessage(error),
        tone: PawlySnackBarTone.error,
      );
    }
  }
}
