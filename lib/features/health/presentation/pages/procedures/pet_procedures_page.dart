import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/health_models.dart';
import '../../../../../design_system/design_system.dart';
import '../../../../logs/controllers/analytics_controller.dart';
import '../../../../logs/controllers/logs_controller.dart';
import '../../../controllers/home/health_home_controller.dart';
import '../../../controllers/procedures/procedures_controller.dart';
import '../../../models/procedures/procedure_inputs.dart';
import '../../../shared/formatters/health_display_formatters.dart';
import '../../../shared/utils/health_error_messages.dart';
import '../../../states/procedures/procedures_state.dart';
import '../../widgets/procedures/procedure_composer_page.dart';
import '../../widgets/procedures/procedure_details_view.dart';
import '../../widgets/procedures/procedures_content.dart';
import '../../widgets/shared/health_date_pickers.dart';
import '../../widgets/shared/health_common_widgets.dart';

class PetProceduresPage extends ConsumerStatefulWidget {
  const PetProceduresPage({
    required this.petId,
    super.key,
  });

  final String petId;

  @override
  ConsumerState<PetProceduresPage> createState() => _PetProceduresPageState();
}

class _PetProceduresPageState extends ConsumerState<PetProceduresPage> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  ProcedureBucket _selectedBucket = ProcedureBucket.planned;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(petProceduresControllerProvider(widget.petId));

    return PawlyScreenScaffold(
      title: 'Процедуры',
      floatingActionButton: stateAsync.asData?.value.canWrite == true
          ? PawlyAddActionButton(
              label: 'Новая процедура',
              tooltip: 'Добавить процедуру',
              onTap: _openCreateSheet,
            )
          : null,
      body: stateAsync.when(
        data: (state) => ProceduresContent(
          petId: widget.petId,
          state: state,
          searchController: _searchController,
          selectedBucket: _selectedBucket,
          onSearchChanged: _onSearchChanged,
          onBucketChanged: (bucket) => setState(() => _selectedBucket = bucket),
          onRetry: () => ref
              .read(petProceduresControllerProvider(widget.petId).notifier)
              .reload(),
          onLoadMore: () => ref
              .read(petProceduresControllerProvider(widget.petId).notifier)
              .loadMore(_selectedBucket),
          onMarkDone: _handleMarkDone,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => HealthStateMessageView(
          title: 'Не удалось загрузить процедуры',
          message: 'Попробуйте обновить экран через несколько секунд.',
          onRetry: () => ref
              .read(petProceduresControllerProvider(widget.petId).notifier)
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
          .read(petProceduresControllerProvider(widget.petId).notifier)
          .setSearchQuery(value);
    });
  }

  Future<void> _openCreateSheet() async {
    final state =
        ref.read(petProceduresControllerProvider(widget.petId)).asData?.value;
    if (state == null) {
      return;
    }

    final input = await Navigator.of(context).push<UpsertProcedureInput>(
      MaterialPageRoute<UpsertProcedureInput>(
        builder: (context) => ProcedureComposerPage(
          petId: widget.petId,
          allowedStatuses: state.bootstrap.enums.procedureStatuses,
          allowedTypeItems: state.bootstrap.enums.procedureTypeItems,
        ),
      ),
    );
    if (input == null || !mounted) {
      return;
    }

    try {
      await ref
          .read(petProceduresControllerProvider(widget.petId).notifier)
          .createProcedure(input: input);
      if (!mounted) return;
      _invalidateHealthDerivedData(ref, widget.petId);
      showPawlySnackBar(
        context,
        message: 'Процедура сохранена.',
        tone: PawlySnackBarTone.success,
      );
      setState(
        () => _selectedBucket = input.status == 'PLANNED'
            ? ProcedureBucket.planned
            : ProcedureBucket.history,
      );
    } catch (error) {
      if (!mounted) return;
      showPawlySnackBar(
        context,
        message: healthMutationErrorMessage(
          error,
          'Не удалось сохранить процедуру.',
        ),
        tone: PawlySnackBarTone.error,
      );
    }
  }

  Future<void> _handleMarkDone(ProcedureCard card) async {
    final performedAt = await showDialog<DateTime>(
      context: context,
      builder: (context) => HealthRequiredDateTimeDialog(
        title: 'Отметить выполненной',
        description: 'Укажите дату и время, когда процедура была выполнена.',
        initialDate: card.scheduledAt ?? DateTime.now(),
      ),
    );
    if (performedAt == null || !mounted) {
      return;
    }

    try {
      final updated = await ref
          .read(petProceduresControllerProvider(widget.petId).notifier)
          .markProcedureDone(
            procedureId: card.id,
            performedAt: performedAt,
          );
      if (!mounted) {
        return;
      }
      _invalidateHealthDerivedData(ref, widget.petId);

      showPawlySnackBar(
        context,
        message: 'Процедура "${card.title}" отмечена выполненной.',
        tone: PawlySnackBarTone.success,
      );

      final nextDueAt = await showDialog<DateTime>(
        context: context,
        builder: (context) => HealthOptionalDateTimeDialog(
          title: 'Дата и время следующей процедуры',
          description:
              'Следующую процедуру можно запланировать сразу. Если дата пока неизвестна, пропустите шаг.',
          initialDate: _defaultNextProcedureDate(performedAt),
        ),
      );
      if (nextDueAt == null) {
        if (!mounted) {
          return;
        }
        setState(() => _selectedBucket = ProcedureBucket.history);
        return;
      }
      if (!mounted) {
        return;
      }

      await ref
          .read(petProceduresControllerProvider(widget.petId).notifier)
          .setNextProcedureDate(
            procedure: updated,
            nextDueAt: nextDueAt,
          );
      if (!mounted) {
        return;
      }
      _invalidateHealthDerivedData(ref, widget.petId);

      showPawlySnackBar(
        context,
        message:
            'Следующая процедура запланирована: ${formatHealthDateTime(nextDueAt)}.',
        tone: PawlySnackBarTone.success,
      );
      setState(() => _selectedBucket = ProcedureBucket.planned);
    } catch (error) {
      if (!mounted) {
        return;
      }
      showPawlySnackBar(
        context,
        message: healthMutationErrorMessage(
          error,
          'Не удалось завершить процедуру.',
        ),
        tone: PawlySnackBarTone.error,
      );
    }
  }

  DateTime _defaultNextProcedureDate(DateTime value) {
    return DateTime(
      value.year,
      value.month + 1,
      value.day,
      value.hour,
      value.minute,
    );
  }
}

class PetProcedureDetailsPage extends ConsumerWidget {
  const PetProcedureDetailsPage({
    required this.petId,
    required this.procedureId,
    super.key,
  });

  final String petId;
  final String procedureId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final procedureRef = PetProcedureRef(
      petId: petId,
      procedureId: procedureId,
    );
    final procedureAsync = ref.watch(petProcedureDetailsProvider(procedureRef));

    return PawlyScreenScaffold(
      title: 'Процедура',
      actions: procedureAsync.maybeWhen(
        data: (procedure) => <Widget>[
          if (procedure.canEdit)
            IconButton(
              onPressed: () => _editProcedure(context, ref, procedure),
              icon: const Icon(Icons.edit_rounded),
              tooltip: 'Редактировать',
            ),
          if (procedure.canDelete)
            IconButton(
              onPressed: () => _deleteProcedure(context, ref, procedure),
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Удалить',
            ),
        ],
        orElse: () => const <Widget>[],
      ),
      body: procedureAsync.when(
        data: (procedure) => ProcedureDetailsView(
          procedure: procedure,
          onRefresh: () async {
            ref.invalidate(petProcedureDetailsProvider(procedureRef));
            try {
              await ref.read(petProcedureDetailsProvider(procedureRef).future);
            } catch (_) {}
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => HealthStateMessageView(
          title: 'Не удалось загрузить процедуры',
          message: 'Попробуйте обновить экран через несколько секунд.',
          onRetry: () =>
              ref.invalidate(petProcedureDetailsProvider(procedureRef)),
        ),
      ),
    );
  }

  Future<void> _editProcedure(
    BuildContext context,
    WidgetRef ref,
    Procedure procedure,
  ) async {
    final state =
        ref.read(petProceduresControllerProvider(petId)).asData?.value;
    final input = await Navigator.of(context).push<UpsertProcedureInput>(
      MaterialPageRoute<UpsertProcedureInput>(
        builder: (context) => ProcedureComposerPage(
          petId: petId,
          allowedStatuses: state?.bootstrap.enums.procedureStatuses ??
              const <String>['PLANNED', 'COMPLETED'],
          allowedTypeItems: state?.bootstrap.enums.procedureTypeItems ??
              const <HealthDictionaryItem>[],
          initialProcedure: procedure,
          title: 'Редактировать процедуру',
          submitLabel: 'Сохранить изменения',
        ),
      ),
    );
    if (input == null || !context.mounted) return;

    try {
      await ref
          .read(petProceduresControllerProvider(petId).notifier)
          .updateProcedure(
            procedureId: procedureId,
            input: input,
          );
      if (!context.mounted) return;
      ref.invalidate(
        petProcedureDetailsProvider(
          PetProcedureRef(petId: petId, procedureId: procedureId),
        ),
      );
      _invalidateHealthDerivedData(ref, petId);
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
          'Не удалось обновить процедуру.',
        ),
        tone: PawlySnackBarTone.error,
      );
    }
  }

  Future<void> _deleteProcedure(
    BuildContext context,
    WidgetRef ref,
    Procedure procedure,
  ) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Удалить процедуру?'),
            content: const Text(
              'Запись о процедуре будет удалена. Это действие нельзя отменить.',
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
          .read(petProceduresControllerProvider(petId).notifier)
          .deleteProcedure(
            procedureId: procedure.id,
            rowVersion: procedure.rowVersion,
          );
      if (!context.mounted) return;
      ref.invalidate(
        petProcedureDetailsProvider(
          PetProcedureRef(petId: petId, procedureId: procedureId),
        ),
      );
      _invalidateHealthDerivedData(ref, petId);
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!context.mounted) return;
      showPawlySnackBar(
        context,
        message: healthMutationErrorMessage(
          error,
          'Не удалось удалить процедуру.',
        ),
        tone: PawlySnackBarTone.error,
      );
    }
  }
}

void _invalidateHealthDerivedData(WidgetRef ref, String petId) {
  ref.invalidate(petHealthHomeProvider(petId));
  ref.invalidate(petLogsControllerProvider(petId));
  ref.invalidate(petAnalyticsMetricsProvider);
  ref.invalidate(petMetricSeriesProvider);
}
