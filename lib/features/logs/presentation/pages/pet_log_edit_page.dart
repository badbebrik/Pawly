import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/design_system.dart';
import '../../../shared/attachments/models/attachment_draft_item.dart';
import '../../controllers/log_details_controller.dart';
import '../../controllers/log_edit_controller.dart';
import '../../controllers/logs_controller.dart';
import '../../models/log_models.dart';
import '../../models/log_refs.dart';
import '../../shared/utils/log_date_picker.dart';
import '../../shared/utils/log_type_utils.dart';
import '../widgets/form/log_form_widgets.dart';

class PetLogEditPage extends ConsumerStatefulWidget {
  const PetLogEditPage({required this.petId, required this.logId, super.key});

  final String petId;
  final String logId;

  @override
  ConsumerState<PetLogEditPage> createState() => _PetLogEditPageState();
}

class _PetLogEditPageState extends ConsumerState<PetLogEditPage> {
  late final LogFormDraft _draft;

  @override
  void initState() {
    super.initState();
    _draft = LogFormDraft();
  }

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logRef = PetLogRef(petId: widget.petId, logId: widget.logId);
    final bootstrapAsync = ref.watch(
      petLogComposerBootstrapProvider(widget.petId),
    );
    final logAsync = ref.watch(petLogDetailsControllerProvider(logRef));
    final isSubmitting = ref.watch(
      logEditControllerProvider(logRef).select(
        (value) => value.asData?.value.isSubmitting ?? false,
      ),
    );
    final bootstrap = bootstrapAsync.asData?.value;
    final entry = logAsync.asData?.value;

    return PawlyScreenScaffold(
      title: 'Редактировать запись',
      body: bootstrap != null && entry != null
          ? _buildContent(
              context,
              bootstrap,
              entry,
              isSubmitting: isSubmitting,
            )
          : (bootstrapAsync.hasError || logAsync.hasError)
              ? LogFormErrorView(
                  title: 'Не удалось подготовить редактирование',
                  message:
                      'Попробуйте открыть запись снова через несколько секунд.',
                  onRetry: () {
                    ref.invalidate(
                        petLogComposerBootstrapProvider(widget.petId));
                    ref
                        .read(
                          petLogDetailsControllerProvider(
                            logRef,
                          ).notifier,
                        )
                        .reload();
                  },
                )
              : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildContent(
    BuildContext context,
    LogsBootstrap bootstrap,
    LogDetails log, {
    required bool isSubmitting,
  }) {
    _draft.populateFromLogOnce(log);
    final allTypes = allBootstrapLogTypes(bootstrap);
    final selectedType = findLogTypeById(allTypes, _draft.selectedTypeId);
    final canEdit = bootstrap.canWrite &&
        log.canEdit &&
        !isSubmitting &&
        !_draft.isUploadingAttachments;

    return LogFormView(
      petId: widget.petId,
      canSubmit: canEdit,
      canManageAttachments: bootstrap.canWrite && log.canEdit && !isSubmitting,
      selectedType: selectedType,
      occurredAt: _draft.occurredAt,
      descriptionController: _draft.descriptionController,
      attachments: _draft.attachments,
      isUploadingAttachments: _draft.isUploadingAttachments,
      submitLabel: isSubmitting ? 'Сохраняем...' : 'Сохранить изменения',
      onPickType: canEdit ? _openTypePicker : null,
      onPickOccurredAt: canEdit ? _pickOccurredAt : null,
      onSubmit: canEdit ? () => _submit(log, bootstrap) : null,
      controllerForMetric: _draft.controllerForMetric,
      booleanValueForMetric: _draft.booleanValueForMetric,
      onSetBooleanMetric: (metricId, value) {
        setState(() {
          _draft.setBooleanMetric(metricId, value);
        });
      },
      onAttachmentsChanged: _setAttachments,
      onUploadingAttachmentsChanged: _setUploadingAttachments,
      topMessage: log.canEdit
          ? null
          : const LogFormInlineMessage(
              title: 'Редактирование недоступно',
              message: 'Эту запись нельзя редактировать.',
            ),
    );
  }

  Future<void> _pickOccurredAt() async {
    final value = await pickLogDateTime(
      context,
      initialValue: _draft.occurredAt,
    );
    if (value == null || !mounted) {
      return;
    }

    setState(() {
      _draft.occurredAt = value;
    });
  }

  Future<void> _openTypePicker() async {
    final selectedTypeId = await context.pushNamed<String>(
      'petLogTypePicker',
      pathParameters: <String, String>{'petId': widget.petId},
    );
    if (selectedTypeId == null || !mounted) {
      return;
    }

    ref.invalidate(petLogComposerBootstrapProvider(widget.petId));
    try {
      await ref.read(petLogComposerBootstrapProvider(widget.petId).future);
    } catch (_) {}
    if (!mounted) {
      return;
    }
    setState(() {
      _draft.setTypePickerResult(selectedTypeId);
    });
  }

  Future<void> _submit(
    LogDetails log,
    LogsBootstrap bootstrap,
  ) async {
    if (_draft.isUploadingAttachments) {
      _showError('Дождитесь окончания загрузки файлов.');
      return;
    }

    final selectedType = findLogTypeById(
      allBootstrapLogTypes(bootstrap),
      _draft.selectedTypeId,
    );
    final validation = _draft.validate(selectedType);
    if (!validation.isValid) {
      _showError(validation.errorMessage!);
      return;
    }
    final form = validation.form;
    if (form == null) {
      return;
    }
    try {
      final logRef = PetLogRef(petId: widget.petId, logId: widget.logId);
      final saved =
          await ref.read(logEditControllerProvider(logRef).notifier).submit(
                form: form,
                attachments: _draft.attachmentInputs(),
                rowVersion: log.rowVersion,
              );
      if (!saved || !mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showError(
        error is StateError
            ? error.message.toString()
            : 'Не удалось сохранить изменения.',
      );
    }
  }

  void _setAttachments(List<AttachmentDraftItem> attachments) {
    if (!mounted) {
      return;
    }
    setState(() {
      _draft.setAttachments(attachments);
    });
  }

  void _setUploadingAttachments(bool value) {
    if (!mounted || _draft.isUploadingAttachments == value) {
      return;
    }
    setState(() {
      _draft.setUploadingAttachments(value);
    });
  }

  void _showError(String message) {
    showPawlySnackBar(
      context,
      message: message,
      tone: PawlySnackBarTone.error,
    );
  }
}
