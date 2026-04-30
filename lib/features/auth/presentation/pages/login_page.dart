import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers/session_state_reset.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../design_system/design_system.dart';
import '../../controllers/login_controller.dart';
import '../../shared/validators/auth_validators.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({
    this.redirectLocation,
    super.key,
  });

  final String? redirectLocation;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loginState = ref.watch(loginControllerProvider);
    final isSubmitting = loginState.isSubmitting;

    ref.listen(loginControllerProvider, (previous, next) {
      final error = next.error;
      if (error == null || error == previous?.error) {
        return;
      }
      _showError(error);
      ref.read(loginControllerProvider.notifier).clearError();
    });

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(PawlySpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: PawlySpacing.xl),
                Text('Вход', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: PawlySpacing.xs),
                Text(
                  'Войдите в аккаунт, чтобы продолжить работу с приложением.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: PawlySpacing.xl),
                PawlyTextField(
                  controller: _emailController,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: AuthValidators.email,
                  prefixIcon: const Icon(Icons.alternate_email_rounded),
                  autofillHints: const <String>[AutofillHints.email],
                ),
                const SizedBox(height: PawlySpacing.sm),
                PawlyTextField(
                  controller: _passwordController,
                  label: 'Пароль',
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  validator: AuthValidators.password,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  autofillHints: const <String>[AutofillHints.password],
                  onFieldSubmitted: (_) => _submitEmailLogin(),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: isSubmitting
                        ? null
                        : () => context.push(
                              Uri(
                                path: AppRoutes.passwordResetRequest,
                                queryParameters: <String, String>{
                                  if (_emailController.text.trim().isNotEmpty)
                                    'email': _emailController.text.trim(),
                                },
                              ).toString(),
                            ),
                    child: const Text('Забыли пароль?'),
                  ),
                ),
                const SizedBox(height: PawlySpacing.lg),
                PawlyButton(
                  label: isSubmitting ? 'Выполняем вход...' : 'Войти',
                  onPressed: isSubmitting ? null : _submitEmailLogin,
                ),
                const SizedBox(height: PawlySpacing.sm),
                PawlyButton(
                  label: 'Войти через Google',
                  variant: PawlyButtonVariant.secondary,
                  icon: Icons.g_mobiledata_rounded,
                  onPressed: isSubmitting ? null : _submitGoogleLogin,
                ),
                const SizedBox(height: PawlySpacing.md),
                Center(
                  child: TextButton(
                    onPressed: isSubmitting
                        ? null
                        : () => context.push(AppRoutes.register),
                    child: const Text('Нет аккаунта? Зарегистрироваться'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitEmailLogin() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      return;
    }

    final success =
        await ref.read(loginControllerProvider.notifier).submitEmail(
              email: _emailController.text,
              password: _passwordController.text,
            );
    if (success && mounted) {
      resetSessionState(ref);
      _goAfterLogin();
    }
  }

  Future<void> _submitGoogleLogin() async {
    final success =
        await ref.read(loginControllerProvider.notifier).submitGoogle();
    if (success && mounted) {
      resetSessionState(ref);
      _goAfterLogin();
    }
  }

  void _showError(String message) {
    showPawlySnackBar(
      context,
      message: message,
      tone: PawlySnackBarTone.error,
    );
  }

  void _goAfterLogin() {
    final redirectLocation = widget.redirectLocation;
    if (redirectLocation != null && redirectLocation.isNotEmpty) {
      context.go(redirectLocation);
      return;
    }
    context.go(AppRoutes.home);
  }
}
