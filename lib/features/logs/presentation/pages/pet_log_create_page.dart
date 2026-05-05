import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/design_system.dart';
import '../../../shared/attachments/models/attachment_draft_item.dart';
import '../../controllers/log_create_controller.dart';
import '../../controllers/logs_controller.dart';
import '../../models/log_models.dart';
import '../../shared/utils/log_date_picker.dart';
import '../../shared/utils/log_type_utils.dart';
import '../widgets/form/log_form_widgets.dart';

class PetLogCreatePage extends ConsumerStatefulWidget {
  const PetLogCreatePage({
    required this.petId,
    this.initialLogTypeId,
    super.key,
  });

  final String petId;
  final String? initialLogTypeId;

  @override
  ConsumerState<PetLogCreatePage> createState() => _PetLogCreatePageState();
}

class _PetLogCreatePageState extends ConsumerState<PetLogCreatePage> {
  late final LogFormDraft _draft;

  @override
  void initState() {
    super.initState();
    _draft = LogFormDraft(initialLogTypeId: widget.initialLogTypeId);
  }

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bootstrapAsync = ref.watch(
      petLogComposerBootstrapProvider(widget.petId),
    );
    final isSubmitting = ref.watch(
      logCreateControllerProvider(widget.petId).select(
        (value) => value.asData?.value.isSubmitting ?? false,
      ),
    );

    return PawlyScreenScaffold(
      title: 'Новая запись',
      body: bootstrapAsync.when(
        data: (bootstrap) => _buildContent(
          context,
          bootstrap,
          isSubmitting: isSubmitting,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => LogFormErrorView(
          title: 'Не удалось подготовить форму записи',
          message: 'Попробуйте открыть форму снова через несколько секунд.',
          onRetry: () =>
              ref.invalidate(petLogComposerBootstrapProvider(widget.petId)),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    LogsBootstrap bootstrap, {
    required bool isSubmitting,
  }) {
    final allTypes = allBootstrapLogTypes(bootstrap);
    final selectedType = findLogTypeById(allTypes, _draft.selectedTypeId);
    final canCreate =
        bootstrap.canWrite && !isSubmitting && !_draft.isUploadingAttachments;

    return LogFormView(
      petId: widget.petId,
      canSubmit: canCreate,
      canManageAttachments: bootstrap.canWrite && !isSubmitting,
      selectedType: selectedType,
      occurredAt: _draft.occurredAt,
      descriptionController: _draft.descriptionController,
      attachments: _draft.attachments,
      isUploadingAttachments: _draft.isUploadingAttachments,
      submitLabel: isSubmitting ? 'Сохраняем...' : 'Сохранить запись',
      onPickType: canCreate ? _openTypePicker : null,
      onPickOccurredAt: canCreate ? _pickOccurredAt : null,
      onSubmit: canCreate ? () => _submit(bootstrap) : null,
      controllerForMetric: _draft.controllerForMetric,
      booleanValueForMetric: _draft.booleanValueForMetric,
      onSetBooleanMetric: (metricId, value) {
        setState(() {
          _draft.setBooleanMetric(metricId, value);
        });
      },
      onAttachmentsChanged: _setAttachments,
      onUploadingAttachmentsChanged: _setUploadingAttachments,
      topMessage: bootstrap.canWrite
          ? null
          : const LogFormInlineMessage(
              title: 'Нет доступа',
              message: 'У вас нет прав на создание записей для этого питомца.',
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
    await ref.read(petLogComposerBootstrapProvider(widget.petId).future);
    if (!mounted) {
      return;
    }
    setState(() {
      _draft.setTypePickerResult(selectedTypeId);
    });
  }

  Future<void> _submit(LogsBootstrap bootstrap) async {
    if (_draft.isUploadingAttachments) {
      _showError('Дождитесь окончания загрузки файлов.');
      return;
    }

    final allTypes = allBootstrapLogTypes(bootstrap);
    final selectedType = findLogTypeById(allTypes, _draft.selectedTypeId);
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
      final saved = await ref
          .read(logCreateControllerProvider(widget.petId).notifier)
          .submit(
            form: form,
            attachments: _draft.attachmentInputs(),
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
            : 'Не удалось сохранить запись.',
      );
    }
  }

  void _setAttachments(List<AttachmentDraftItem> attachments) {
    setState(() {
      _draft.setAttachments(attachments);
    });
  }

  void _setUploadingAttachments(bool value) {
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
