import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../design_system/design_system.dart';
import '../../controllers/password_reset_controller.dart';
import '../../shared/validators/auth_validators.dart';

class PasswordResetRequestPage extends ConsumerStatefulWidget {
  const PasswordResetRequestPage({
    this.initialEmail,
    super.key,
  });

  final String? initialEmail;

  @override
  ConsumerState<PasswordResetRequestPage> createState() =>
      _PasswordResetRequestPageState();
}

class _PasswordResetRequestPageState
    extends ConsumerState<PasswordResetRequestPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final resetState = ref.watch(passwordResetControllerProvider);
    final isSubmitting = resetState.isRequestingCode;

    ref.listen(passwordResetControllerProvider, (previous, next) {
      final error = next.error;
      if (error == null || error == previous?.error) {
        return;
      }
      _showError(error);
      ref.read(passwordResetControllerProvider.notifier).clearError();
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Восстановление пароля')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(PawlySpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Введите email',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: PawlySpacing.xs),
                Text(
                  'Мы отправим 6-значный код для сброса пароля.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: PawlySpacing.lg),
                PawlyTextField(
                  controller: _emailController,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  validator: AuthValidators.email,
                  prefixIcon: const Icon(Icons.alternate_email_rounded),
                  autofillHints: const <String>[AutofillHints.email],
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: PawlySpacing.lg),
                PawlyButton(
                  label: isSubmitting ? 'Отправляем код...' : 'Продолжить',
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

    final email = _emailController.text.trim();

    final success = await ref
        .read(passwordResetControllerProvider.notifier)
        .requestCode(email: email);
    if (success && mounted) {
      context.push(
        Uri(
          path: AppRoutes.passwordResetVerify,
          queryParameters: <String, String>{'email': email},
        ).toString(),
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
