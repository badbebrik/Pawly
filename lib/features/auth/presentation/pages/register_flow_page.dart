import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers/session_state_reset.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../design_system/design_system.dart';
import '../../controllers/register_controller.dart';
import '../../models/register_step.dart';
import '../widgets/register_step_indicator.dart';
import '../widgets/register_steps.dart';

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
    final registerState = ref.watch(registerControllerProvider);
    final step = registerState.step;
    final isSubmitting = registerState.isSubmitting;

    ref.listen(registerControllerProvider, (previous, next) {
      final error = next.error;
      if (error == null || error == previous?.error) {
        return;
      }
      _showError(error);
      ref.read(registerControllerProvider.notifier).clearError();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Регистрация'),
        leading: IconButton(
          onPressed: isSubmitting ? null : _handleBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(PawlySpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              RegisterStepIndicator(currentStep: step),
              const SizedBox(height: PawlySpacing.lg),
              AnimatedSwitcher(
                duration: PawlyMotion.standard,
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: switch (step) {
                  RegisterStep.name => RegisterNameStep(
                      state: registerState,
                      firstNameController: _firstNameController,
                      lastNameController: _lastNameController,
                      onNext: () => _goTo(RegisterStep.email),
                    ),
                  RegisterStep.email => RegisterEmailStep(
                      formKey: _emailFormKey,
                      state: registerState,
                      emailController: _emailController,
                      onSubmit: _submitEmailStep,
                    ),
                  RegisterStep.password => RegisterPasswordStep(
                      formKey: _passwordFormKey,
                      state: registerState,
                      passwordController: _passwordController,
                      confirmPasswordController: _confirmPasswordController,
                      onSubmit: _submitRegistrationRequest,
                    ),
                  RegisterStep.verification => RegisterVerificationStep(
                      formKey: _verifyFormKey,
                      state: registerState,
                      email: _emailController.text.trim(),
                      codeController: _codeController,
                      onSubmit: _submitVerificationStep,
                      onResend: _resendVerificationCode,
                      onChangeEmail: () => _goTo(RegisterStep.email),
                    ),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitEmailStep() {
    final valid = _emailFormKey.currentState?.validate() ?? false;
    if (!valid) {
      return;
    }

    _goTo(RegisterStep.password);
  }

  Future<void> _submitRegistrationRequest() async {
    final valid = _passwordFormKey.currentState?.validate() ?? false;
    if (!valid) {
      return;
    }

    await ref.read(registerControllerProvider.notifier).submitRegistration(
          email: _emailController.text,
          password: _passwordController.text,
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
        );
  }

  Future<void> _submitVerificationStep() async {
    final valid = _verifyFormKey.currentState?.validate() ?? false;
    if (!valid) {
      return;
    }

    final success =
        await ref.read(registerControllerProvider.notifier).submitVerification(
              email: _emailController.text,
              code: _codeController.text,
            );
    if (success && mounted) {
      resetSessionState(ref);
      context.go(AppRoutes.postRegisterChoice);
    }
  }

  void _handleBack() {
    final state = ref.read(registerControllerProvider);
    if (state.step == RegisterStep.name) {
      context.go(AppRoutes.login);
      return;
    }

    ref.read(registerControllerProvider.notifier).goBack();
  }

  void _goTo(RegisterStep nextStep) {
    ref.read(registerControllerProvider.notifier).goTo(nextStep);
  }

  Future<void> _resendVerificationCode() async {
    final success = await ref
        .read(registerControllerProvider.notifier)
        .resendVerificationCode(email: _emailController.text);
    if (success && mounted) {
      _codeController.clear();
      showPawlySnackBar(
        context,
        message: 'Код отправлен повторно.',
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
