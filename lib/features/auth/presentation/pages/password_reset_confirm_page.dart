import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../design_system/design_system.dart';
import '../providers/auth_providers.dart';
import '../utils/auth_error_message.dart';
import '../utils/auth_validators.dart';

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

  bool _isSubmitting = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.resetToken.trim().isEmpty) {
      return _MissingResetConfirmContext(
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
                      _isSubmitting ? 'Сохраняем пароль...' : 'Сменить пароль',
                  onPressed: _isSubmitting ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }

    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref.read(authRepositoryProvider).confirmPasswordReset(
            resetToken: widget.resetToken,
            newPassword: _passwordController.text,
          );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пароль изменен. Теперь войдите с новым паролем.'),
        ),
      );
      context.go(AppRoutes.login);
    } catch (error) {
      if (!mounted) {
        return;
      }

      final message = authErrorMessage(error);
      if (message != null) {
        _showError(message);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _MissingResetConfirmContext extends StatelessWidget {
  const _MissingResetConfirmContext({
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Восстановление пароля')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(PawlySpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: PawlySpacing.lg),
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: PawlySpacing.sm),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              PawlyButton(label: buttonLabel, onPressed: onPressed),
            ],
          ),
        ),
      ),
    );
  }
}
