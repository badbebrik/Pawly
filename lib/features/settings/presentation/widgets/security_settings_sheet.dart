import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../design_system/design_system.dart';
import '../../../auth/presentation/utils/auth_error_message.dart';
import '../../../auth/presentation/utils/auth_validators.dart';
import '../../controllers/settings_security_controller.dart';

Future<void> showSecuritySettingsSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => const _SecuritySettingsSheet(),
  );
}

class _SecuritySettingsSheet extends ConsumerStatefulWidget {
  const _SecuritySettingsSheet();

  @override
  ConsumerState<_SecuritySettingsSheet> createState() =>
      _SecuritySettingsSheetState();
}

class _SecuritySettingsSheetState
    extends ConsumerState<_SecuritySettingsSheet> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _oldPasswordVisible = false;
  bool _newPasswordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final securityState = ref.watch(settingsSecurityControllerProvider);
    final isSubmitting = securityState.isChangingPassword;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          PawlySpacing.lg,
          PawlySpacing.sm,
          PawlySpacing.lg,
          PawlySpacing.lg + viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Безопасность',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: PawlySpacing.xxxs),
                Text(
                  'После смены пароля потребуется войти заново.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: PawlySpacing.md),
                PawlyTextField(
                  controller: _oldPasswordController,
                  label: 'Текущий пароль',
                  obscureText: !_oldPasswordVisible,
                  enabled: !isSubmitting,
                  validator: AuthValidators.password,
                  suffixIcon: IconButton(
                    onPressed: isSubmitting
                        ? null
                        : () => setState(() {
                              _oldPasswordVisible = !_oldPasswordVisible;
                            }),
                    icon: Icon(
                      _oldPasswordVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
                const SizedBox(height: PawlySpacing.md),
                PawlyTextField(
                  controller: _newPasswordController,
                  label: 'Новый пароль',
                  obscureText: !_newPasswordVisible,
                  enabled: !isSubmitting,
                  validator: (value) {
                    final base = AuthValidators.password(value);
                    if (base != null) {
                      return base;
                    }
                    if ((value ?? '') == _oldPasswordController.text) {
                      return 'Новый пароль должен отличаться от текущего.';
                    }
                    return null;
                  },
                  suffixIcon: IconButton(
                    onPressed: isSubmitting
                        ? null
                        : () => setState(() {
                              _newPasswordVisible = !_newPasswordVisible;
                            }),
                    icon: Icon(
                      _newPasswordVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
                const SizedBox(height: PawlySpacing.md),
                PawlyTextField(
                  controller: _confirmPasswordController,
                  label: 'Повторите новый пароль',
                  obscureText: !_confirmPasswordVisible,
                  enabled: !isSubmitting,
                  validator: (value) => AuthValidators.confirmPassword(
                    value,
                    _newPasswordController.text,
                  ),
                  suffixIcon: IconButton(
                    onPressed: isSubmitting
                        ? null
                        : () => setState(() {
                              _confirmPasswordVisible =
                                  !_confirmPasswordVisible;
                            }),
                    icon: Icon(
                      _confirmPasswordVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
                const SizedBox(height: PawlySpacing.lg),
                PawlyButton(
                  label: isSubmitting ? 'Сохраняем...' : 'Сменить пароль',
                  onPressed: isSubmitting ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    try {
      await ref
          .read(settingsSecurityControllerProvider.notifier)
          .changePassword(
            oldPassword: _oldPasswordController.text,
            newPassword: _newPasswordController.text,
          );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пароль изменен. Войдите в аккаунт снова.'),
        ),
      );
      context.go(AppRoutes.login);
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = authErrorMessage(error) ?? 'Не удалось сменить пароль.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
}
