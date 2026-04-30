import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../design_system/design_system.dart';
import '../../shared/validators/auth_validators.dart';
import '../../states/register_state.dart';

class RegisterNameStep extends StatelessWidget {
  const RegisterNameStep({
    required this.state,
    required this.firstNameController,
    required this.lastNameController,
    required this.onNext,
    super.key,
  });

  final RegisterState state;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
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
          controller: firstNameController,
          label: 'Имя',
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          autofillHints: const <String>[AutofillHints.givenName],
        ),
        const SizedBox(height: PawlySpacing.sm),
        PawlyTextField(
          controller: lastNameController,
          label: 'Фамилия',
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.words,
          autofillHints: const <String>[AutofillHints.familyName],
          onFieldSubmitted: (_) => onNext(),
        ),
        const SizedBox(height: PawlySpacing.lg),
        PawlyButton(
          label: 'Продолжить',
          onPressed: state.isSubmitting ? null : onNext,
        ),
      ],
    );
  }
}

class RegisterEmailStep extends StatelessWidget {
  const RegisterEmailStep({
    required this.formKey,
    required this.state,
    required this.emailController,
    required this.onSubmit,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final RegisterState state;
  final TextEditingController emailController;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
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
            controller: emailController,
            label: 'Email',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            validator: AuthValidators.email,
            autofillHints: const <String>[AutofillHints.email],
            onFieldSubmitted: (_) => onSubmit(),
          ),
          const SizedBox(height: PawlySpacing.lg),
          PawlyButton(
            label: 'Продолжить',
            onPressed: state.isSubmitting ? null : onSubmit,
          ),
        ],
      ),
    );
  }
}

class RegisterPasswordStep extends StatelessWidget {
  const RegisterPasswordStep({
    required this.formKey,
    required this.state,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.onSubmit,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final RegisterState state;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
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
            controller: passwordController,
            label: 'Пароль',
            obscureText: true,
            textInputAction: TextInputAction.next,
            validator: AuthValidators.password,
            autofillHints: const <String>[AutofillHints.newPassword],
          ),
          const SizedBox(height: PawlySpacing.sm),
          PawlyTextField(
            controller: confirmPasswordController,
            label: 'Повторите пароль',
            obscureText: true,
            textInputAction: TextInputAction.done,
            validator: (value) => AuthValidators.confirmPassword(
              value,
              passwordController.text,
            ),
            onFieldSubmitted: (_) => onSubmit(),
          ),
          const SizedBox(height: PawlySpacing.lg),
          PawlyButton(
            label: state.isSubmitting ? 'Отправляем...' : 'Создать аккаунт',
            onPressed: state.isSubmitting ? null : onSubmit,
          ),
        ],
      ),
    );
  }
}

class RegisterVerificationStep extends StatelessWidget {
  const RegisterVerificationStep({
    required this.formKey,
    required this.state,
    required this.email,
    required this.codeController,
    required this.onSubmit,
    required this.onResend,
    required this.onChangeEmail,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final RegisterState state;
  final String email;
  final TextEditingController codeController;
  final VoidCallback onSubmit;
  final VoidCallback onResend;
  final VoidCallback onChangeEmail;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
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
            'Мы отправили 6-значный код на $email',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (state.canResendInSeconds > 0) ...<Widget>[
            const SizedBox(height: PawlySpacing.xs),
            Text(
              'Повторная отправка доступна через ${state.canResendInSeconds} сек.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: PawlySpacing.lg),
          PawlyTextField(
            controller: codeController,
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
            onFieldSubmitted: (_) => onSubmit(),
          ),
          const SizedBox(height: PawlySpacing.lg),
          PawlyButton(
            label: state.isSubmitting ? 'Проверяем...' : 'Подтвердить',
            onPressed: state.isSubmitting ? null : onSubmit,
          ),
          const SizedBox(height: PawlySpacing.sm),
          PawlyButton(
            label: state.canResendInSeconds > 0
                ? 'Отправить код повторно через ${state.canResendInSeconds} сек.'
                : 'Отправить код повторно',
            variant: PawlyButtonVariant.secondary,
            onPressed: state.canResend ? onResend : null,
          ),
          const SizedBox(height: PawlySpacing.sm),
          PawlyButton(
            label: 'Изменить email',
            variant: PawlyButtonVariant.ghost,
            onPressed: state.isSubmitting ? null : onChangeEmail,
          ),
        ],
      ),
    );
  }
}
