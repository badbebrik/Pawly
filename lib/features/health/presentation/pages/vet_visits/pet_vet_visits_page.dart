import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/health_models.dart';
import '../../../../../design_system/design_system.dart';
import '../../../controllers/home/health_home_controller.dart';
import '../../../controllers/vet_visits/vet_visits_controller.dart';
import '../../../models/vet_visits/vet_visit_inputs.dart';
import '../../../shared/utils/health_error_messages.dart';
import '../../../states/vet_visits/vet_visits_state.dart';
import '../../widgets/shared/health_common_widgets.dart';
import '../../widgets/vet_visits/vet_visit_composer_page.dart';
import '../../widgets/vet_visits/vet_visit_details_view.dart';
import '../../widgets/vet_visits/vet_visits_content.dart';

class PetVetVisitsPage extends ConsumerStatefulWidget {
  const PetVetVisitsPage({
    required this.petId,
    super.key,
  });

  final String petId;

  @override
  ConsumerState<PetVetVisitsPage> createState() => _PetVetVisitsPageState();
}

class _PetVetVisitsPageState extends ConsumerState<PetVetVisitsPage> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  VetVisitBucket _selectedBucket = VetVisitBucket.upcoming;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(petVetVisitsControllerProvider(widget.petId));

    return PawlyScreenScaffold(
      title: 'Ветеринарные визиты',
      floatingActionButton: stateAsync.asData?.value.canWrite == true
          ? PawlyAddActionButton(
              label: 'Новый визит',
              tooltip: 'Добавить ветеринарный визит',
              onTap: _openCreateSheet,
            )
          : null,
      body: stateAsync.when(
        data: (state) => VetVisitsContent(
          petId: widget.petId,
          state: state,
          searchController: _searchController,
          selectedBucket: _selectedBucket,
          onSearchChanged: _onSearchChanged,
          onBucketChanged: (bucket) => setState(() => _selectedBucket = bucket),
          onRetry: () => ref
              .read(petVetVisitsControllerProvider(widget.petId).notifier)
              .reload(),
          onLoadMore: () => ref
              .read(petVetVisitsControllerProvider(widget.petId).notifier)
              .loadMore(_selectedBucket),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => HealthStateMessageView(
          title: 'Не удалось загрузить визиты',
          message: 'Попробуйте обновить экран через несколько секунд.',
          onRetry: () => ref
              .read(petVetVisitsControllerProvider(widget.petId).notifier)
              .reload(),
        ),
      ),
    );
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) {
        return;
      }
      ref
          .read(petVetVisitsControllerProvider(widget.petId).notifier)
          .setSearchQuery(value);
    });
  }

  Future<void> _openCreateSheet() async {
    final state =
        ref.read(petVetVisitsControllerProvider(widget.petId)).asData?.value;
    if (state == null) {
      return;
    }

    final input = await Navigator.of(context).push<UpsertVetVisitInput>(
      MaterialPageRoute<UpsertVetVisitInput>(
        builder: (context) => VetVisitComposerPage(
          petId: widget.petId,
          allowedStatuses: state.bootstrap.enums.vetVisitStatuses,
          allowedTypes: state.bootstrap.enums.vetVisitTypes,
        ),
      ),
    );
    if (input == null || !mounted) {
      return;
    }

    try {
      final result = await ref
          .read(petVetVisitsControllerProvider(widget.petId).notifier)
          .createVetVisit(
            input: input,
          );
      if (!mounted) return;
      ref.invalidate(petHealthHomeProvider(widget.petId));
      showPawlySnackBar(
        context,
        message: _visitCreateSuccessMessage(result),
        tone: result.relatedLogsLinked && result.listReloaded
            ? PawlySnackBarTone.success
            : PawlySnackBarTone.warning,
      );
      setState(
        () => _selectedBucket = input.status == 'PLANNED'
            ? VetVisitBucket.upcoming
            : VetVisitBucket.history,
      );
    } catch (error) {
      if (!mounted) return;
      showPawlySnackBar(
        context,
        message: healthMutationErrorMessage(
          error,
          'Не удалось сохранить визит.',
        ),
        tone: PawlySnackBarTone.error,
      );
    }
  }
}

class PetVetVisitDetailsPage extends ConsumerWidget {
  const PetVetVisitDetailsPage({
    required this.petId,
    required this.visitId,
    super.key,
  });

  final String petId;
  final String visitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitRef = PetVetVisitRef(petId: petId, visitId: visitId);
    final visitAsync = ref.watch(petVetVisitDetailsProvider(visitRef));

    return PawlyScreenScaffold(
      title: 'Визит',
      actions: visitAsync.maybeWhen(
        data: (visit) => <Widget>[
          if (visit.canEdit)
            IconButton(
              onPressed: () => _editVisit(context, ref, visit),
              icon: const Icon(Icons.edit_rounded),
              tooltip: 'Редактировать',
            ),
          if (visit.canDelete)
            IconButton(
              onPressed: () => _deleteVisit(context, ref, visit),
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Удалить',
            ),
        ],
        orElse: () => const <Widget>[],
      ),
      body: visitAsync.when(
        data: (visit) => VetVisitDetailsView(
          petId: petId,
          visit: visit,
          onRefresh: () async {
            ref.invalidate(petVetVisitDetailsProvider(visitRef));
            try {
              await ref.read(petVetVisitDetailsProvider(visitRef).future);
            } catch (_) {}
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => HealthStateMessageView(
          title: 'Не удалось загрузить визиты',
          message: 'Попробуйте обновить экран через несколько секунд.',
          onRetry: () => ref.invalidate(petVetVisitDetailsProvider(visitRef)),
        ),
      ),
    );
  }

  Future<void> _editVisit(
    BuildContext context,
    WidgetRef ref,
    VetVisit visit,
  ) async {
    final state = ref.read(petVetVisitsControllerProvider(petId)).asData?.value;
    final input = await Navigator.of(context).push<UpsertVetVisitInput>(
      MaterialPageRoute<UpsertVetVisitInput>(
        builder: (context) => VetVisitComposerPage(
          petId: petId,
          allowedStatuses: state?.bootstrap.enums.vetVisitStatuses ??
              const <String>['PLANNED', 'COMPLETED'],
          allowedTypes:
              state?.bootstrap.enums.vetVisitTypes ?? const <String>['CHECKUP'],
          initialVisit: visit,
          title: 'Редактировать визит',
          submitLabel: 'Сохранить изменения',
        ),
      ),
    );
    if (input == null || !context.mounted) return;

    try {
      await ref
          .read(petVetVisitsControllerProvider(petId).notifier)
          .updateVetVisit(
            visitId: visitId,
            input: input,
          );
      if (!context.mounted) return;
      ref.invalidate(petVetVisitDetailsProvider(
          PetVetVisitRef(petId: petId, visitId: visitId)));
      ref.invalidate(petHealthHomeProvider(petId));
      showPawlySnackBar(
        context,
        message: 'Изменения сохранены.',
        tone: PawlySnackBarTone.success,
      );
    } catch (error) {
      if (!context.mounted) return;
      showPawlySnackBar(
        context,
        message: healthMutationErrorMessage(
          error,
          'Не удалось обновить визит.',
        ),
        tone: PawlySnackBarTone.error,
      );
    }
  }

  Future<void> _deleteVisit(
    BuildContext context,
    WidgetRef ref,
    VetVisit visit,
  ) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Удалить визит?'),
            content: const Text(
              'Запись о визите будет удалена. Это действие нельзя отменить.',
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
          ),
        ) ??
        false;
    if (!confirmed || !context.mounted) return;

    try {
      await ref
          .read(petVetVisitsControllerProvider(petId).notifier)
          .deleteVetVisit(
            visitId: visit.id,
            rowVersion: visit.rowVersion,
          );
      if (!context.mounted) return;
      ref.invalidate(petVetVisitDetailsProvider(
          PetVetVisitRef(petId: petId, visitId: visitId)));
      ref.invalidate(petHealthHomeProvider(petId));
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!context.mounted) return;
      showPawlySnackBar(
        context,
        message: healthMutationErrorMessage(
          error,
          'Не удалось удалить визит.',
        ),
        tone: PawlySnackBarTone.error,
      );
    }
  }
}

String _visitCreateSuccessMessage(VetVisitCreateResult result) {
  if (!result.relatedLogsLinked) {
    return 'Визит сохранен, но не все записи прикрепились.';
  }

  if (!result.listReloaded) {
    return 'Визит сохранен. Обновите список, если он не появился.';
  }

  return 'Визит сохранен.';
}
