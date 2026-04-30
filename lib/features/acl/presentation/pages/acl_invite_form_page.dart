import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/design_system.dart';
import '../../controllers/acl_invite_form_controller.dart';
import '../../models/acl_invite_form_params.dart';
import '../../shared/formatters/acl_error_formatters.dart';
import '../../shared/widgets/acl_error_view.dart';
import '../widgets/acl_invite_form_content.dart';

class AclInviteFormPage extends ConsumerStatefulWidget {
  const AclInviteFormPage({
    required this.petId,
    this.inviteId,
    super.key,
  });

  final String petId;
  final String? inviteId;

  bool get isEditMode => inviteId != null && inviteId!.isNotEmpty;

  @override
  ConsumerState<AclInviteFormPage> createState() => _AclInviteFormPageState();
}

class _AclInviteFormPageState extends ConsumerState<AclInviteFormPage> {
  late final TextEditingController _customRoleController;

  @override
  void initState() {
    super.initState();
    _customRoleController = TextEditingController();
  }

  @override
  void dispose() {
    _customRoleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final params = AclInviteFormParams(
      petId: widget.petId,
      inviteId: widget.inviteId,
    );
    final state = ref.watch(aclInviteFormControllerProvider(params));
    final title =
        widget.isEditMode ? 'Редактирование приглашения' : 'Новое приглашение';

    return PawlyScreenScaffold(
      title: title,
      body: state.when(
        data: (value) {
          _syncCustomRoleController(value.customRoleTitle);

          return AclInviteFormContent(
            title: widget.isEditMode
                ? 'Сохранить приглашение'
                : 'Создать приглашение',
            submittingTitle: widget.isEditMode ? 'Сохраняем...' : 'Создаём...',
            systemRoles: value.systemRoles
                .where((role) => !role.isOwner)
                .toList(growable: false),
            customRoles: value.customRoles,
            selectedRoleId: value.selectedRoleId,
            customRoleTitle: value.customRoleTitle,
            customRoleController: _customRoleController,
            permissions: value.permissions,
            isSubmitting: value.isSubmitting,
            onRoleSelected: (roleId) => ref
                .read(aclInviteFormControllerProvider(params).notifier)
                .selectRole(roleId),
            onCustomRoleChanged: (text) => ref
                .read(aclInviteFormControllerProvider(params).notifier)
                .setCustomRoleTitle(text),
            onReadChanged: (domain, allowed) => ref
                .read(aclInviteFormControllerProvider(params).notifier)
                .setReadPermission(domain, allowed),
            onWriteChanged: (domain, allowed) => ref
                .read(aclInviteFormControllerProvider(params).notifier)
                .setWritePermission(domain, allowed),
            onSubmit: () => _submit(params),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => AclErrorView(
          title: widget.isEditMode
              ? 'Не удалось открыть приглашение'
              : 'Не удалось открыть экран приглашения',
          message: widget.isEditMode
              ? 'Попробуйте обновить экран.'
              : 'Попробуйте перезагрузить экран и снова выбрать роль и права.',
          onRetry: () => ref
              .read(aclInviteFormControllerProvider(params).notifier)
              .reload(),
        ),
      ),
    );
  }

  void _syncCustomRoleController(String value) {
    if (_customRoleController.text == value) {
      return;
    }
    _customRoleController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  Future<void> _submit(AclInviteFormParams params) async {
    try {
      final result = await ref
          .read(aclInviteFormControllerProvider(params).notifier)
          .submit();
      if (!mounted) {
        return;
      }
      if (widget.isEditMode) {
        Navigator.of(context).pop(result.inviteId);
        return;
      }

      context.pushReplacementNamed(
        'aclInviteDetails',
        pathParameters: <String, String>{
          'petId': widget.petId,
          'inviteId': result.inviteId,
        },
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      showPawlySnackBar(
        context,
        message: aclErrorMessage(
          error,
          widget.isEditMode
              ? 'Не удалось обновить приглашение.'
              : 'Не удалось создать приглашение.',
        ),
        tone: PawlySnackBarTone.error,
      );
    }
  }
}
