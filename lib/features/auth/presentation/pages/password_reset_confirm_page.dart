import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../design_system/design_system.dart';
import '../../controllers/password_reset_controller.dart';
import '../../shared/validators/auth_validators.dart';
import '../widgets/password_reset_missing_context.dart';

class PasswordResetConfirmPage extends ConsumerStatefulWidget {
  const PasswordResetConfirmPage({
    required this.resetToken,
    this.email,
    super.key,
  });

  final String resetToken;
  final String? email;

  @override
  ConsumerState<PasswordResetConfirmPage> createState() =>
      _PasswordResetConfirmPageState();
}

class _PasswordResetConfirmPageState
    extends ConsumerState<PasswordResetConfirmPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.resetToken.trim().isEmpty) {
      return PasswordResetMissingContext(
        title: 'Не удалось открыть экран',
        description: 'Сначала подтвердите код из письма.',
        buttonLabel: 'К вводу кода',
        onPressed: () => context.go(
          Uri(
            path: AppRoutes.passwordResetVerify,
            queryParameters: <String, String>{
              if (widget.email != null && widget.email!.trim().isNotEmpty)
                'email': widget.email!,
            },
          ).toString(),
        ),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    final resetState = ref.watch(passwordResetControllerProvider);
    final isSubmitting = resetState.isConfirmingPassword;

    ref.listen(passwordResetControllerProvider, (previous, next) {
      final error = next.error;
      if (error == null || error == previous?.error) {
        return;
      }
      _showError(error);
      ref.read(passwordResetControllerProvider.notifier).clearError();
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Новый пароль')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(PawlySpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Задайте новый пароль',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: PawlySpacing.xs),
                Text(
                  'После сохранения нужно будет войти в аккаунт заново.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: PawlySpacing.lg),
                PawlyTextField(
                  controller: _passwordController,
                  label: 'Новый пароль',
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  validator: AuthValidators.password,
                  autofillHints: const <String>[AutofillHints.newPassword],
                ),
                const SizedBox(height: PawlySpacing.sm),
                PawlyTextField(
                  controller: _confirmPasswordController,
                  label: 'Повторите пароль',
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  validator: (value) => AuthValidators.confirmPassword(
                    value,
                    _passwordController.text,
                  ),
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: PawlySpacing.lg),
                PawlyButton(
                  label:
                      isSubmitting ? 'Сохраняем пароль...' : 'Сменить пароль',
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
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      return;
    }

    final success = await ref
        .read(passwordResetControllerProvider.notifier)
        .confirmPassword(
          resetToken: widget.resetToken,
          newPassword: _passwordController.text,
        );
    if (success && mounted) {
      showPawlySnackBar(
        context,
        message: 'Пароль изменен. Теперь войдите с новым паролем.',
        tone: PawlySnackBarTone.success,
      );
      context.go(AppRoutes.login);
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
