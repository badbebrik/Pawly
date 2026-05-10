import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/health_models.dart';
import '../../../../../design_system/design_system.dart';
import '../../../controllers/home/health_home_controller.dart';
import '../../../controllers/medical_records/medical_records_controller.dart';
import '../../../models/medical_records/medical_record_inputs.dart';
import '../../../shared/utils/health_error_messages.dart';
import '../../../states/medical_records/medical_records_state.dart';
import '../../widgets/medical_records/medical_record_composer_page.dart';
import '../../widgets/medical_records/medical_record_details_view.dart';
import '../../widgets/medical_records/medical_records_content.dart';
import '../../widgets/shared/health_common_widgets.dart';

class PetMedicalRecordsPage extends ConsumerStatefulWidget {
  const PetMedicalRecordsPage({
    required this.petId,
    super.key,
  });

  final String petId;

  @override
  ConsumerState<PetMedicalRecordsPage> createState() =>
      _PetMedicalRecordsPageState();
}

class _PetMedicalRecordsPageState extends ConsumerState<PetMedicalRecordsPage> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  MedicalRecordBucket _selectedBucket = MedicalRecordBucket.active;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(
      petMedicalRecordsControllerProvider(widget.petId),
    );

    return PawlyScreenScaffold(
      title: 'Медкарта',
      floatingActionButton: stateAsync.asData?.value.canWrite == true
          ? PawlyAddActionButton(
              label: 'Новая запись',
              tooltip: 'Добавить запись медкарты',
              onTap: _openCreateSheet,
            )
          : null,
      body: stateAsync.when(
        data: (state) => MedicalRecordsContent(
          petId: widget.petId,
          state: state,
          searchController: _searchController,
          selectedBucket: _selectedBucket,
          onSearchChanged: _onSearchChanged,
          onBucketChanged: (bucket) => setState(() => _selectedBucket = bucket),
          onRetry: () => ref
              .read(petMedicalRecordsControllerProvider(widget.petId).notifier)
              .reload(),
          onLoadMore: () => ref
              .read(petMedicalRecordsControllerProvider(widget.petId).notifier)
              .loadMore(_selectedBucket),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => HealthStateMessageView(
          title: 'Не удалось загрузить медкарту',
          message: 'Попробуйте обновить экран через несколько секунд.',
          onRetry: () => ref
              .read(petMedicalRecordsControllerProvider(widget.petId).notifier)
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
          .read(petMedicalRecordsControllerProvider(widget.petId).notifier)
          .setSearchQuery(value);
    });
  }

  Future<void> _openCreateSheet() async {
    final state = ref
        .read(petMedicalRecordsControllerProvider(widget.petId))
        .asData
        ?.value;
    if (state == null) {
      return;
    }

    final input = await Navigator.of(context).push<UpsertMedicalRecordInput>(
      MaterialPageRoute<UpsertMedicalRecordInput>(
        builder: (context) => MedicalRecordComposerPage(
          petId: widget.petId,
          allowedStatuses: state.bootstrap.enums.medicalRecordStatuses,
          allowedTypeItems: state.bootstrap.enums.medicalRecordTypeItems,
        ),
      ),
    );
    if (input == null || !mounted) {
      return;
    }

    try {
      await ref
          .read(petMedicalRecordsControllerProvider(widget.petId).notifier)
          .createMedicalRecord(input: input);
      if (!mounted) return;
      ref.invalidate(petHealthHomeProvider(widget.petId));
      showPawlySnackBar(
        context,
        message: 'Запись медкарты сохранена.',
        tone: PawlySnackBarTone.success,
      );
      setState(
        () => _selectedBucket = input.status == 'ACTIVE'
            ? MedicalRecordBucket.active
            : MedicalRecordBucket.archive,
      );
    } catch (error) {
      if (!mounted) return;
      showPawlySnackBar(
        context,
        message: healthMutationErrorMessage(
          error,
          'Не удалось сохранить запись медкарты.',
        ),
        tone: PawlySnackBarTone.error,
      );
    }
  }
}

class PetMedicalRecordDetailsPage extends ConsumerWidget {
  const PetMedicalRecordDetailsPage({
    required this.petId,
    required this.recordId,
    super.key,
  });

  final String petId;
  final String recordId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordRef = PetMedicalRecordRef(petId: petId, recordId: recordId);
    final recordAsync = ref.watch(petMedicalRecordDetailsProvider(recordRef));

    return PawlyScreenScaffold(
      title: 'Запись медкарты',
      actions: recordAsync.maybeWhen(
        data: (record) => <Widget>[
          if (record.canEdit)
            IconButton(
              onPressed: () => _editRecord(context, ref, record),
              icon: const Icon(Icons.edit_rounded),
              tooltip: 'Редактировать',
            ),
          if (record.canDelete)
            IconButton(
              onPressed: () => _deleteRecord(context, ref, record),
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Удалить',
            ),
        ],
        orElse: () => const <Widget>[],
      ),
      body: recordAsync.when(
        data: (record) => MedicalRecordDetailsView(
          record: record,
          onRefresh: () async {
            ref.invalidate(petMedicalRecordDetailsProvider(recordRef));
            try {
              await ref.read(petMedicalRecordDetailsProvider(recordRef).future);
            } catch (_) {}
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => HealthStateMessageView(
          title: 'Не удалось загрузить медкарту',
          message: 'Попробуйте обновить экран через несколько секунд.',
          onRetry: () =>
              ref.invalidate(petMedicalRecordDetailsProvider(recordRef)),
        ),
      ),
    );
  }

  Future<void> _editRecord(
    BuildContext context,
    WidgetRef ref,
    MedicalRecord record,
  ) async {
    final state =
        ref.read(petMedicalRecordsControllerProvider(petId)).asData?.value;
    final input = await Navigator.of(context).push<UpsertMedicalRecordInput>(
      MaterialPageRoute<UpsertMedicalRecordInput>(
        builder: (context) => MedicalRecordComposerPage(
          petId: petId,
          allowedStatuses: state?.bootstrap.enums.medicalRecordStatuses ??
              const <String>['ACTIVE', 'RESOLVED'],
          allowedTypeItems: state?.bootstrap.enums.medicalRecordTypeItems ??
              const <HealthDictionaryItem>[],
          initialRecord: record,
          title: 'Редактировать запись',
          submitLabel: 'Сохранить изменения',
        ),
      ),
    );
    if (input == null || !context.mounted) return;

    try {
      await ref
          .read(petMedicalRecordsControllerProvider(petId).notifier)
          .updateMedicalRecord(
            recordId: recordId,
            input: input,
          );
      if (!context.mounted) return;
      ref.invalidate(
        petMedicalRecordDetailsProvider(
          PetMedicalRecordRef(petId: petId, recordId: recordId),
        ),
      );
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
          'Не удалось обновить запись медкарты.',
        ),
        tone: PawlySnackBarTone.error,
      );
    }
  }

  Future<void> _deleteRecord(
    BuildContext context,
    WidgetRef ref,
    MedicalRecord record,
  ) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Удалить запись?'),
            content: const Text(
              'Запись медкарты будет удалена. Это действие нельзя отменить.',
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
          .read(petMedicalRecordsControllerProvider(petId).notifier)
          .deleteMedicalRecord(
            recordId: record.id,
            rowVersion: record.rowVersion,
          );
      if (!context.mounted) return;
      ref.invalidate(
        petMedicalRecordDetailsProvider(
          PetMedicalRecordRef(petId: petId, recordId: recordId),
        ),
      );
      ref.invalidate(petHealthHomeProvider(petId));
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!context.mounted) return;
      showPawlySnackBar(
        context,
        message: healthMutationErrorMessage(
          error,
          'Не удалось удалить запись медкарты.',
        ),
        tone: PawlySnackBarTone.error,
      );
    }
  }
}
