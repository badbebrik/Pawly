import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/health_models.dart';
import '../../../../../design_system/design_system.dart';
import '../../../../logs/controllers/analytics_controller.dart';
import '../../../../logs/controllers/logs_controller.dart';
import '../../../controllers/home/health_home_controller.dart';
import '../../../controllers/vaccinations/vaccinations_controller.dart';
import '../../../models/vaccinations/vaccination_inputs.dart';
import '../../../shared/formatters/health_display_formatters.dart';
import '../../../shared/utils/health_error_messages.dart';
import '../../../states/vaccinations/vaccinations_state.dart';
import '../../widgets/shared/health_date_pickers.dart';
import '../../widgets/shared/health_common_widgets.dart';
import '../../widgets/vaccinations/vaccination_composer_page.dart';
import '../../widgets/vaccinations/vaccination_details_view.dart';
import '../../widgets/vaccinations/vaccinations_content.dart';

class PetVaccinationsPage extends ConsumerStatefulWidget {
  const PetVaccinationsPage({
    required this.petId,
    super.key,
  });

  final String petId;

  @override
  ConsumerState<PetVaccinationsPage> createState() =>
      _PetVaccinationsPageState();
}

class _PetVaccinationsPageState extends ConsumerState<PetVaccinationsPage> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  VaccinationBucket _selectedBucket = VaccinationBucket.planned;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(
      petVaccinationsControllerProvider(widget.petId),
    );

    return PawlyScreenScaffold(
      title: 'Вакцинации',
      floatingActionButton: stateAsync.asData?.value.canWrite == true
          ? PawlyAddActionButton(
              label: 'Новая вакцина',
              tooltip: 'Добавить вакцинацию',
              onTap: _openCreateSheet,
            )
          : null,
      body: stateAsync.when(
        data: (state) => VaccinationsContent(
          petId: widget.petId,
          state: state,
          searchController: _searchController,
          selectedBucket: _selectedBucket,
          onSearchChanged: _onSearchChanged,
          onBucketChanged: (bucket) => setState(() => _selectedBucket = bucket),
          onRetry: () => ref
              .read(petVaccinationsControllerProvider(widget.petId).notifier)
              .reload(),
          onLoadMore: () => ref
              .read(petVaccinationsControllerProvider(widget.petId).notifier)
              .loadMore(_selectedBucket),
          onMarkDone: _handleMarkDone,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => HealthStateMessageView(
          title: 'Не удалось загрузить вакцинации',
          message: 'Попробуйте обновить экран через несколько секунд.',
          onRetry: () => ref
              .read(petVaccinationsControllerProvider(widget.petId).notifier)
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
          .read(petVaccinationsControllerProvider(widget.petId).notifier)
          .setSearchQuery(value);
    });
  }

  Future<void> _openCreateSheet() async {
    final state =
        ref.read(petVaccinationsControllerProvider(widget.petId)).value;
    if (state == null) {
      return;
    }

    final input = await Navigator.of(context).push<UpsertVaccinationInput>(
      MaterialPageRoute<UpsertVaccinationInput>(
        builder: (context) => VaccinationComposerPage(
          petId: widget.petId,
          allowedStatuses: state.bootstrap.enums.vaccinationStatuses,
          vaccinationTargets: state.bootstrap.enums.vaccinationTargets,
        ),
      ),
    );
    if (input == null || !mounted) {
      return;
    }

    try {
      await ref
          .read(petVaccinationsControllerProvider(widget.petId).notifier)
          .createVaccination(input: input);
      if (!mounted) {
        return;
      }
      _invalidateHealthDerivedData(ref, widget.petId);
      showPawlySnackBar(
        context,
        message: 'Вакцинация сохранена.',
        tone: PawlySnackBarTone.success,
      );
      setState(
        () => _selectedBucket = input.status == 'PLANNED'
            ? VaccinationBucket.planned
            : VaccinationBucket.history,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      showPawlySnackBar(
        context,
        message: _errorMessage(error),
        tone: PawlySnackBarTone.error,
      );
    }
  }

  Future<void> _handleMarkDone(VaccinationCard card) async {
    final administeredAt = await showDialog<DateTime>(
      context: context,
      builder: (context) => HealthRequiredDateTimeDialog(
        title: 'Отметить выполненной',
        description: 'Укажите дату и время, когда вакцинация была выполнена.',
        initialDate: card.scheduledAt ?? DateTime.now(),
      ),
    );
    if (administeredAt == null || !mounted) {
      return;
    }

    try {
      final updated = await ref
          .read(petVaccinationsControllerProvider(widget.petId).notifier)
          .markVaccinationDone(
            vaccinationId: card.id,
            administeredAt: administeredAt,
          );
      if (!mounted) {
        return;
      }
      _invalidateHealthDerivedData(ref, widget.petId);

      showPawlySnackBar(
        context,
        message: 'Вакцина "${card.vaccineName}" отмечена выполненной.',
        tone: PawlySnackBarTone.success,
      );

      final nextDueAt = await showDialog<DateTime>(
        context: context,
        builder: (context) => HealthOptionalDateTimeDialog(
          title: 'Дата и время ревакцинации',
          description:
              'Следующую прививку можно запланировать сразу. Если дата пока неизвестна, пропустите шаг.',
          initialDate: _defaultRevaccinationDate(administeredAt),
        ),
      );
      if (nextDueAt == null) {
        if (!mounted) {
          return;
        }
        setState(() => _selectedBucket = VaccinationBucket.history);
        return;
      }
      if (!mounted) {
        return;
      }

      await ref
          .read(petVaccinationsControllerProvider(widget.petId).notifier)
          .setRevaccinationDate(
            vaccination: updated,
            nextDueAt: nextDueAt,
          );
      if (!mounted) {
        return;
      }
      _invalidateHealthDerivedData(ref, widget.petId);

      showPawlySnackBar(
        context,
        message:
            'Дата и время ревакцинации сохранены: ${formatHealthDateTime(nextDueAt)}.',
        tone: PawlySnackBarTone.success,
      );
      setState(() => _selectedBucket = VaccinationBucket.planned);
    } catch (error) {
      if (!mounted) {
        return;
      }
      showPawlySnackBar(
        context,
        message: _errorMessage(error),
        tone: PawlySnackBarTone.error,
      );
    }
  }

  DateTime _defaultRevaccinationDate(DateTime value) {
    return DateTime(
      value.year + 1,
      value.month,
      value.day,
      value.hour,
      value.minute,
    );
  }

  String _errorMessage(Object error) {
    if (error is StateError) {
      return error.message.toString();
    }

    return 'Не удалось выполнить действие с вакцинацией.';
  }
}

class PetVaccinationDetailsPage extends ConsumerWidget {
  const PetVaccinationDetailsPage({
    required this.petId,
    required this.vaccinationId,
    super.key,
  });

  final String petId;
  final String vaccinationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaccinationRef = PetVaccinationRef(
      petId: petId,
      vaccinationId: vaccinationId,
    );
    final vaccinationAsync = ref.watch(
      petVaccinationDetailsProvider(vaccinationRef),
    );

    return PawlyScreenScaffold(
      title: 'Вакцина',
      actions: vaccinationAsync.maybeWhen(
        data: (vaccination) => <Widget>[
          if (vaccination.canEdit)
            IconButton(
              onPressed: () => _editVaccination(context, ref, vaccination),
              icon: const Icon(Icons.edit_rounded),
              tooltip: 'Редактировать',
            ),
          if (vaccination.canDelete)
            IconButton(
              onPressed: () => _deleteVaccination(context, ref, vaccination),
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Удалить',
            ),
        ],
        orElse: () => const <Widget>[],
      ),
      body: vaccinationAsync.when(
        data: (vaccination) => VaccinationDetailsView(
          vaccination: vaccination,
          onRefresh: () async {
            ref.invalidate(petVaccinationDetailsProvider(vaccinationRef));
            try {
              await ref
                  .read(petVaccinationDetailsProvider(vaccinationRef).future);
            } catch (_) {}
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => HealthStateMessageView(
          title: 'Не удалось загрузить вакцинации',
          message: 'Попробуйте обновить экран через несколько секунд.',
          onRetry: () => ref.invalidate(
            petVaccinationDetailsProvider(vaccinationRef),
          ),
        ),
      ),
    );
  }

  Future<void> _editVaccination(
    BuildContext context,
    WidgetRef ref,
    Vaccination vaccination,
  ) async {
    final enums = ref
        .read(petVaccinationsControllerProvider(petId))
        .asData
        ?.value
        .bootstrap
        .enums;
    final statuses =
        enums?.vaccinationStatuses ?? const <String>['PLANNED', 'COMPLETED'];
    final targets = enums?.vaccinationTargets ?? const <HealthDictionaryItem>[];

    final input = await Navigator.of(context).push<UpsertVaccinationInput>(
      MaterialPageRoute<UpsertVaccinationInput>(
        builder: (context) => VaccinationComposerPage(
          petId: petId,
          allowedStatuses: statuses,
          vaccinationTargets: targets,
          initialVaccination: vaccination,
          title: 'Редактировать вакцинацию',
          submitLabel: 'Сохранить изменения',
        ),
      ),
    );
    if (input == null || !context.mounted) {
      return;
    }

    try {
      await ref
          .read(petVaccinationsControllerProvider(petId).notifier)
          .updateVaccination(
            vaccinationId: vaccinationId,
            input: input,
          );
      if (!context.mounted) {
        return;
      }
      ref.invalidate(
        petVaccinationDetailsProvider(
          PetVaccinationRef(petId: petId, vaccinationId: vaccinationId),
        ),
      );
      _invalidateHealthDerivedData(ref, petId);
      showPawlySnackBar(
        context,
        message: 'Изменения сохранены.',
        tone: PawlySnackBarTone.success,
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      showPawlySnackBar(
        context,
        message: healthMutationErrorMessage(
          error,
          'Не удалось обновить вакцинацию.',
        ),
        tone: PawlySnackBarTone.error,
      );
    }
  }

  Future<void> _deleteVaccination(
    BuildContext context,
    WidgetRef ref,
    Vaccination vaccination,
  ) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Удалить вакцинацию?'),
              content: const Text(
                'Запись о вакцинации будет удалена. Это действие нельзя отменить.',
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
          .read(petVaccinationsControllerProvider(petId).notifier)
          .deleteVaccination(
            vaccinationId: vaccination.id,
            rowVersion: vaccination.rowVersion,
          );
      if (!context.mounted) {
        return;
      }
      ref.invalidate(
        petVaccinationDetailsProvider(
          PetVaccinationRef(petId: petId, vaccinationId: vaccinationId),
        ),
      );
      _invalidateHealthDerivedData(ref, petId);
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      showPawlySnackBar(
        context,
        message: healthMutationErrorMessage(
          error,
          'Не удалось удалить вакцинацию.',
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
