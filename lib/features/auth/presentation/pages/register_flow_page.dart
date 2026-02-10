import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/providers/session_state_reset.dart';
import '../../../../design_system/design_system.dart';
import '../providers/auth_providers.dart';
import '../utils/auth_error_message.dart';
import '../utils/auth_validators.dart';

enum _RegisterStep { name, email, password, verification }

class RegisterFlowPage extends ConsumerStatefulWidget {
  const RegisterFlowPage({super.key});

  @override
  ConsumerState<RegisterFlowPage> createState() => _RegisterFlowPageState();
}

class _RegisterFlowPageState extends ConsumerState<RegisterFlowPage> {
  final _emailFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();
  final _verifyFormKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _codeController = TextEditingController();

  _RegisterStep _step = _RegisterStep.name;
  bool _isSubmitting = false;
  int _canResendInSeconds = 0;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Регистрация'),
        leading: IconButton(
          onPressed: _isSubmitting ? null : _handleBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(PawlySpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _StepIndicator(currentStep: _step),
              const SizedBox(height: PawlySpacing.lg),
              AnimatedSwitcher(
                duration: PawlyMotion.standard,
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: switch (_step) {
                  _RegisterStep.name => _buildNameStep(),
                  _RegisterStep.email => _buildEmailStep(),
                  _RegisterStep.password => _buildPasswordStep(),
                  _RegisterStep.verification => _buildVerificationStep(),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameStep() {
    return Column(
      key: const ValueKey<String>('name-step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Как к вам обращаться?',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: PawlySpacing.xs),
        Text(
          'Имя и фамилия необязательны, их можно добавить позже.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: PawlySpacing.lg),
        PawlyTextField(
          controller: _firstNameController,
          label: 'Имя (опционально)',
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          autofillHints: const <String>[AutofillHints.givenName],
        ),
        const SizedBox(height: PawlySpacing.sm),
        PawlyTextField(
          controller: _lastNameController,
          label: 'Фамилия (опционально)',
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.words,
          autofillHints: const <String>[AutofillHints.familyName],
          onFieldSubmitted: (_) => _goTo(_RegisterStep.email),
        ),
        const SizedBox(height: PawlySpacing.lg),
        PawlyButton(
          label: 'Продолжить',
          onPressed: _isSubmitting ? null : () => _goTo(_RegisterStep.email),
        ),
      ],
    );
  }

  Widget _buildEmailStep() {
    return Form(
      key: _emailFormKey,
      child: Column(
        key: const ValueKey<String>('email-step'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Укажите email',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: PawlySpacing.xs),
          Text(
            'На этот адрес придет код подтверждения.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: PawlySpacing.lg),
          PawlyTextField(
            controller: _emailController,
            label: 'Email',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            validator: AuthValidators.email,
            autofillHints: const <String>[AutofillHints.email],
            onFieldSubmitted: (_) => _submitEmailStep(),
          ),
          const SizedBox(height: PawlySpacing.lg),
          PawlyButton(
            label: 'Продолжить',
            onPressed: _isSubmitting ? null : _submitEmailStep,
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordStep() {
    return Form(
      key: _passwordFormKey,
      child: Column(
        key: const ValueKey<String>('password-step'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Придумайте пароль',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: PawlySpacing.xs),
          Text(
            'Минимум 8 символов для защиты аккаунта.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: PawlySpacing.lg),
          PawlyTextField(
            controller: _passwordController,
            label: 'Пароль',
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
            onFieldSubmitted: (_) => _submitRegistrationRequest(),
          ),
          const SizedBox(height: PawlySpacing.lg),
          PawlyButton(
            label: _isSubmitting ? 'Отправляем...' : 'Создать аккаунт',
            onPressed: _isSubmitting ? null : _submitRegistrationRequest,
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationStep() {
    return Form(
      key: _verifyFormKey,
      child: Column(
        key: const ValueKey<String>('verify-step'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Подтвердите email',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: PawlySpacing.xs),
          Text(
            'Мы отправили 6-значный код на ${_emailController.text.trim()}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (_canResendInSeconds > 0) ...<Widget>[
            const SizedBox(height: PawlySpacing.xs),
            Text(
              'Повторная отправка доступна через $_canResendInSeconds сек.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
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
            onFieldSubmitted: (_) => _submitVerificationStep(),
          ),
          const SizedBox(height: PawlySpacing.lg),
          PawlyButton(
            label: _isSubmitting ? 'Проверяем...' : 'Подтвердить',
            onPressed: _isSubmitting ? null : _submitVerificationStep,
          ),
          const SizedBox(height: PawlySpacing.sm),
          PawlyButton(
            label: 'Изменить email',
            variant: PawlyButtonVariant.ghost,
            onPressed: _isSubmitting ? null : () => _goTo(_RegisterStep.email),
          ),
        ],
      ),
    );
  }

  void _submitEmailStep() {
    if (_isSubmitting) {
      return;
    }

    final valid = _emailFormKey.currentState?.validate() ?? false;
    if (!valid) {
      return;
    }

    _goTo(_RegisterStep.password);
  }

  Future<void> _submitRegistrationRequest() async {
    if (_isSubmitting) {
      return;
    }

    final valid = _passwordFormKey.currentState?.validate() ?? false;
    if (!valid) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await ref.read(authRepositoryProvider).registerWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            firstName: _firstNameController.text.trim().isEmpty
                ? null
                : _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim().isEmpty
                ? null
                : _lastNameController.text.trim(),
          );

      if (!mounted) {
        return;
      }

      setState(() {
        _canResendInSeconds = response.canResendInSeconds;
        _step = _RegisterStep.verification;
      });
    } catch (error) {
      if (mounted) {
        final message = authErrorMessage(error);
        if (message != null) {
          _showError(message);
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _submitVerificationStep() async {
    if (_isSubmitting) {
      return;
    }

    final valid = _verifyFormKey.currentState?.validate() ?? false;
    if (!valid) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref.read(authRepositoryProvider).verifyEmailCode(
            email: _emailController.text.trim(),
            code: _codeController.text.trim(),
          );
      resetSessionState(ref);

      if (!mounted) {
        return;
      }

      context.go(AppRoutes.postRegisterChoice);
    } catch (error) {
      if (mounted) {
        final message = authErrorMessage(error);
        if (message != null) {
          _showError(message);
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _handleBack() {
    if (_step == _RegisterStep.name) {
      context.go(AppRoutes.login);
      return;
    }

    if (_step == _RegisterStep.email) {
      _goTo(_RegisterStep.name);
      return;
    }

    if (_step == _RegisterStep.password) {
      _goTo(_RegisterStep.email);
      return;
    }

    _goTo(_RegisterStep.password);
  }

  void _goTo(_RegisterStep nextStep) {
    setState(() {
      _step = nextStep;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep});

  final _RegisterStep currentStep;

  @override
  Widget build(BuildContext context) {
    final currentIndex = currentStep.index;

    const labels = <String>['Имя', 'Email', 'Пароль', 'Код'];

    return Wrap(
      spacing: PawlySpacing.sm,
      runSpacing: PawlySpacing.xs,
      children: List<Widget>.generate(labels.length, (index) {
        final done = index < currentIndex;
        final active = index == currentIndex;

        return _DotStep(
          index: index + 1,
          active: active,
          done: done,
          label: labels[index],
        );
      }),
    );
  }
}

class _DotStep extends StatelessWidget {
  const _DotStep({
    required this.index,
    required this.active,
    required this.done,
    required this.label,
  });

  final int index;
  final bool active;
  final bool done;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final background =
        done || active ? colorScheme.primary : colorScheme.primaryContainer;

    final foreground =
        done || active ? colorScheme.onPrimary : colorScheme.onPrimaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: PawlySpacing.xs,
        vertical: PawlySpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(PawlyRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            done ? '✓' : '$index',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: foreground,
                ),
          ),
          const SizedBox(width: PawlySpacing.xxs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: foreground,
                ),
          ),
        ],
      ),
    );
  }
}
