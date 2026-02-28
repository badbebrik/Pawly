import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../design_system/design_system.dart';
import '../providers/auth_providers.dart';
import '../utils/auth_error_message.dart';
import '../utils/auth_validators.dart';

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

  bool _isSubmitting = false;
  bool _isResending = false;
  int _canResendInSeconds = 60;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _startResendCountdown(_canResendInSeconds);
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.email.trim().isEmpty) {
      return _MissingResetContext(
        title: 'Не удалось открыть экран',
        description: 'Сначала укажите email для восстановления пароля.',
        buttonLabel: 'К вводу email',
        onPressed: () => context.go(AppRoutes.passwordResetRequest),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;

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
                  label: _isSubmitting ? 'Проверяем код...' : 'Продолжить',
                  onPressed: _isSubmitting || _isResending ? null : _submit,
                ),
                const SizedBox(height: PawlySpacing.sm),
                PawlyButton(
                  label: _isResending
                      ? 'Отправляем заново...'
                      : _canResendInSeconds > 0
                          ? 'Отправить код заново через $_canResendInSeconds сек.'
                          : 'Отправить код заново',
                  variant: PawlyButtonVariant.secondary,
                  onPressed:
                      _isSubmitting || _isResending || _canResendInSeconds > 0
                          ? null
                          : _resendCode,
                ),
                const SizedBox(height: PawlySpacing.xs),
                PawlyButton(
                  label: 'Изменить email',
                  variant: PawlyButtonVariant.ghost,
                  onPressed: _isSubmitting || _isResending
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
    if (_isSubmitting || _isResending) {
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
      final response =
          await ref.read(authRepositoryProvider).verifyPasswordResetCode(
                email: widget.email,
                code: _codeController.text.trim(),
              );

      if (!mounted) {
        return;
      }

      context.push(
        Uri(
          path: AppRoutes.passwordResetConfirm,
          queryParameters: <String, String>{
            'reset_token': response.resetToken,
            'email': widget.email,
          },
        ).toString(),
      );
    } catch (error) {
      _syncCooldownFromError(error);
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

  Future<void> _resendCode() async {
    if (_isSubmitting || _isResending) {
      return;
    }

    setState(() {
      _isResending = true;
    });

    try {
      await ref
          .read(authRepositoryProvider)
          .requestPasswordReset(email: widget.email);

      _codeController.clear();
      _startResendCountdown(60);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Новый код отправлен на email.')),
      );
    } catch (error) {
      _syncCooldownFromError(error);
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
          _isResending = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _startResendCountdown(int seconds) {
    _resendTimer?.cancel();

    if (!mounted) {
      return;
    }

    setState(() {
      _canResendInSeconds = seconds > 0 ? seconds : 0;
    });

    if (_canResendInSeconds == 0) {
      return;
    }

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_canResendInSeconds <= 1) {
        timer.cancel();
        setState(() {
          _canResendInSeconds = 0;
        });
        return;
      }

      setState(() {
        _canResendInSeconds -= 1;
      });
    });
  }

  void _syncCooldownFromError(Object error) {
    final seconds = _extractCanResendInSeconds(error);
    if (seconds != null && seconds > 0) {
      _startResendCountdown(seconds);
    }
  }

  int? _extractCanResendInSeconds(Object error) {
    if (error is! ApiException || error.error.code != 'cannot_resend_yet') {
      return null;
    }

    final details = error.error.details;
    if (details == null) {
      return null;
    }

    final value = details['can_resend_in'] ?? details['can_resend_in_seconds'];
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '');
  }
}

class _MissingResetContext extends StatelessWidget {
  const _MissingResetContext({
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
