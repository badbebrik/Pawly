import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../design_system/design_system.dart';
import '../../controllers/password_reset_controller.dart';
import '../../shared/validators/auth_validators.dart';
import '../widgets/password_reset_missing_context.dart';

class PasswordResetVerifyPage extends ConsumerStatefulWidget {
  const PasswordResetVerifyPage({
    required this.email,
    super.key,
  });

  final String email;

  @override
  ConsumerState<PasswordResetVerifyPage> createState() =>
      _PasswordResetVerifyPageState();
}

class _PasswordResetVerifyPageState
    extends ConsumerState<PasswordResetVerifyPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.email.trim().isEmpty) {
      return PasswordResetMissingContext(
        title: 'Не удалось открыть экран',
        description: 'Сначала укажите email для восстановления пароля.',
        buttonLabel: 'К вводу email',
        onPressed: () => context.go(AppRoutes.passwordResetRequest),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    final resetState = ref.watch(passwordResetControllerProvider);

    ref.listen(passwordResetControllerProvider, (previous, next) {
      final error = next.error;
      if (error == null || error == previous?.error) {
        return;
      }
      _showError(error);
      ref.read(passwordResetControllerProvider.notifier).clearError();
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Код из письма')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(PawlySpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Подтвердите сброс пароля',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: PawlySpacing.xs),
                Text(
                  'Введите 6-значный код, который мы отправили на ${widget.email}.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: PawlySpacing.lg),
                PawlyTextField(
                  controller: _codeController,
                  label: 'Код подтверждения',
                  hintText: '000000',
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  maxLength: 6,
                  validator: AuthValidators.requiredCode,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: PawlySpacing.lg),
                PawlyButton(
                  label: resetState.isVerifyingCode
                      ? 'Проверяем код...'
                      : 'Продолжить',
                  onPressed: resetState.isVerifyingBusy ? null : _submit,
                ),
                const SizedBox(height: PawlySpacing.sm),
                PawlyButton(
                  label: resetState.isResendingCode
                      ? 'Отправляем заново...'
                      : resetState.canResendInSeconds > 0
                          ? 'Отправить код заново через ${resetState.canResendInSeconds} сек.'
                          : 'Отправить код заново',
                  variant: PawlyButtonVariant.secondary,
                  onPressed: resetState.canResendCode ? _resendCode : null,
                ),
                const SizedBox(height: PawlySpacing.xs),
                PawlyButton(
                  label: 'Изменить email',
                  variant: PawlyButtonVariant.ghost,
                  onPressed: resetState.isVerifyingBusy
                      ? null
                      : () => context.go(
                            Uri(
                              path: AppRoutes.passwordResetRequest,
                              queryParameters: <String, String>{
                                'email': widget.email,
                              },
                            ).toString(),
                          ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      return;
    }

    final verification =
        await ref.read(passwordResetControllerProvider.notifier).verifyCode(
              email: widget.email,
              code: _codeController.text,
            );
    if (verification != null && mounted) {
      context.push(
        Uri(
          path: AppRoutes.passwordResetConfirm,
          queryParameters: <String, String>{
            'reset_token': verification.resetToken,
            'email': widget.email,
          },
        ).toString(),
      );
    }
  }

  Future<void> _resendCode() async {
    final success = await ref
        .read(passwordResetControllerProvider.notifier)
        .resendCode(email: widget.email);
    if (success && mounted) {
      _codeController.clear();
      showPawlySnackBar(
        context,
        message: 'Новый код отправлен на email.',
        tone: PawlySnackBarTone.success,
      );
    }
  }

  void _showError(String message) {
    showPawlySnackBar(
      context,
      message: message,
      tone: PawlySnackBarTone.error,
    );
  }
}
