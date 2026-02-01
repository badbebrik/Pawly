import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../design_system/design_system.dart';
import '../providers/auth_providers.dart';
import '../utils/auth_error_message.dart';
import '../utils/auth_validators.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
                const SizedBox(height: PawlySpacing.lg),
                PawlyButton(
                  label: _isSubmitting ? 'Выполняем вход...' : 'Войти',
                  onPressed: _isSubmitting ? null : _submitEmailLogin,
                ),
                const SizedBox(height: PawlySpacing.sm),
                PawlyButton(
                  label: 'Войти через Google',
                  variant: PawlyButtonVariant.secondary,
                  icon: Icons.g_mobiledata_rounded,
                  onPressed: _isSubmitting ? null : _submitGoogleLogin,
                ),
                const SizedBox(height: PawlySpacing.md),
                Center(
                  child: TextButton(
                    onPressed: _isSubmitting
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

    final authRepository = ref.read(authRepositoryProvider);

    try {
      await authRepository.loginWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      context.go(AppRoutes.home);
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showError(authErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _submitGoogleLogin() async {
    if (_isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final googleService = ref.read(googleSignInServiceProvider);

    try {
      final idToken = await googleService.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        throw StateError('Google Sign-In не настроен в этой сборке.');
      }

      await ref.read(authRepositoryProvider).loginWithGoogle(idToken: idToken);

      if (!mounted) {
        return;
      }

      context.go(AppRoutes.home);
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showError(authErrorMessage(error));
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
