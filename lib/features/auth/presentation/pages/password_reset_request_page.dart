import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../design_system/design_system.dart';
import '../providers/auth_providers.dart';
import '../utils/auth_error_message.dart';
import '../utils/auth_validators.dart';

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

  bool _isSubmitting = false;

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
                  label: _isSubmitting ? 'Отправляем код...' : 'Продолжить',
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

    final email = _emailController.text.trim();

    try {
      await ref.read(authRepositoryProvider).requestPasswordReset(email: email);

      if (!mounted) {
        return;
      }

      context.go(
        Uri(
          path: AppRoutes.passwordResetVerify,
          queryParameters: <String, String>{'email': email},
        ).toString(),
      );
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
