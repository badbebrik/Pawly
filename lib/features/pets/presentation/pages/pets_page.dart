import 'dart:async';

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
import '../../states/pets_state.dart';
import '../widgets/active_pet_view.dart';
import '../widgets/add_pet_actions_sheet.dart';
import '../widgets/join_pet_by_code_dialog.dart';
import '../widgets/pets_list_view.dart';

class PetsPage extends ConsumerStatefulWidget {
  const PetsPage({super.key});

  @override
  ConsumerState<PetsPage> createState() => _PetsPageState();
}

class _PetsPageState extends ConsumerState<PetsPage> {
  String? _pendingActivePetIdSync;
  bool _showPetList = false;

  @override
  Widget build(BuildContext context) {
    final petsStateAsync = ref.watch(petsControllerProvider);
    final activePetIdAsync = ref.watch(activePetControllerProvider);

    return petsStateAsync.when(
      data: (petsState) => activePetIdAsync.when(
        data: (activePetId) => _buildLoaded(context, petsState, activePetId),
        loading: () => _buildLoadingScaffold(),
        error: (_, __) => _buildErrorScaffold(
          message: 'Не удалось определить активного питомца.',
          onRetry: () =>
              ref.read(activePetControllerProvider.notifier).reload(),
        ),
      ),
      loading: _buildLoadingScaffold,
      error: (error, _) => _buildErrorScaffold(
        message: 'Не удалось загрузить питомцев.',
        onRetry: () => ref.read(petsControllerProvider.notifier).reload(),
      ),
    );
  }

  Widget _buildLoaded(
    BuildContext context,
    PetsState petsState,
    String? activePetId,
  ) {
    final activeEntries = _activePetEntries(petsState.items);
    final activeEntry = _entryById(activeEntries, activePetId);

    if (activeEntries.isEmpty) {
      if (activePetId != null && activePetId.isNotEmpty) {
        _scheduleActivePetClear();
      }
      return _buildPetsListScaffold(context, petsState);
    }

    if (activeEntry == null) {
      if (activePetId != null && activePetId.isNotEmpty) {
        _scheduleActivePetClear();
      }
      return _buildPetsListScaffold(context, petsState);
    }

    if (_showPetList) {
      return _buildPetsListScaffold(context, petsState);
    }

    return PawlyScreenScaffold(
      title: 'Питомец',
      automaticallyImplyLeading: false,
      actions: <Widget>[
        if (PawlyFeatureFlags.chatEnabled)
          ChatAppBarAction(petId: activeEntry.id),
      ],
      body: ActivePetView(
        petId: activeEntry.id,
        entry: activeEntry,
        onSwitchPet: _openPetList,
      ),
    );
  }

  Widget _buildPetsListScaffold(
    BuildContext context,
    PetsState petsState,
  ) {
    return PawlyScreenScaffold(
      title: 'Питомцы',
      actions: const <Widget>[
        if (PawlyFeatureFlags.chatEnabled) ChatAppBarAction(),
      ],
      floatingActionButton: _buildAddPetButton(context),
      body: PetsListView(
        state: petsState,
        onSearchChanged:
            ref.read(petsControllerProvider.notifier).setSearchQuery,
        onStatusBucketChanged:
            ref.read(petsControllerProvider.notifier).setStatusBucket,
        onOwnershipFilterChanged:
            ref.read(petsControllerProvider.notifier).setOwnershipFilter,
        onPetSelected: (entry) => _selectActivePet(context, entry),
        onRestorePet: (entry) => _restorePetFromArchive(context, ref, entry),
      ),
    );
  }

  Widget _buildLoadingScaffold() {
    return const PawlyScreenScaffold(
      title: 'Питомец',
      automaticallyImplyLeading: false,
      body: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorScaffold({
    required String message,
    required VoidCallback onRetry,
  }) {
    return PawlyScreenScaffold(
      title: 'Питомцы',
      actions: const <Widget>[
        if (PawlyFeatureFlags.chatEnabled) ChatAppBarAction(),
      ],
      floatingActionButton: _buildAddPetButton(context),
      body: PetsErrorView(
        message: message,
        onRetry: onRetry,
      ),
    );
  }

  Widget _buildAddPetButton(BuildContext context) {
    return PawlyAddActionButton(
      label: 'Добавить',
      tooltip: 'Добавить питомца',
      onTap: () => showAddPetActionsSheet(
        context: context,
        onCreatePet: () => context.push(AppRoutes.petCreate),
        onJoinByCode: () => _showJoinByCodeDialog(context, ref),
      ),
    );
  }

  void _openPetList() {
    setState(() {
      _showPetList = true;
    });
  }

  Future<void> _selectActivePet(
    BuildContext context,
    PetListEntry entry,
  ) async {
    try {
      await ref.read(activePetControllerProvider.notifier).selectPet(entry.id);
      ref.invalidate(activePetDetailsControllerProvider(entry.id));
      if (context.mounted) {
        setState(() {
          _showPetList = false;
        });
        context.goNamed('pets');
      }
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      showPawlySnackBar(
        context,
        message: 'Не удалось выбрать питомца.',
        tone: PawlySnackBarTone.error,
      );
    }
  }

  void _scheduleActivePetClear() {
    const clearMarker = '__clear__';
    if (_pendingActivePetIdSync == clearMarker) {
      return;
    }

    _pendingActivePetIdSync = clearMarker;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _pendingActivePetIdSync != clearMarker) {
        return;
      }
      unawaited(_clearActivePet());
    });
  }

  Future<void> _clearActivePet() async {
    try {
      await ref.read(activePetControllerProvider.notifier).clear();
    } finally {
      if (mounted && _pendingActivePetIdSync == '__clear__') {
        _pendingActivePetIdSync = null;
      }
    }
  }

  List<PetListEntry> _activePetEntries(List<PetListEntry> items) {
    return items
        .where((item) => item.pet.status != 'ARCHIVED')
        .toList(growable: false);
  }

  PetListEntry? _entryById(List<PetListEntry> entries, String? petId) {
    if (petId == null || petId.isEmpty) {
      return null;
    }

    for (final entry in entries) {
      if (entry.id == petId) {
        return entry;
      }
    }
    return null;
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
    context.goNamed('pets');
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
