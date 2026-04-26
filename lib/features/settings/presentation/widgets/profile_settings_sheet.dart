import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/design_system.dart';
import '../../controllers/settings_profile_controller.dart';
import '../../models/settings_profile.dart';

Future<void> showProfileSettingsSheet(
  BuildContext context,
  SettingsProfile profile,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _ProfileSettingsSheet(profile: profile),
  );
}

class _ProfileSettingsSheet extends ConsumerStatefulWidget {
  const _ProfileSettingsSheet({
    required this.profile,
  });

  final SettingsProfile profile;

  @override
  ConsumerState<_ProfileSettingsSheet> createState() =>
      _ProfileSettingsSheetState();
}

class _ProfileSettingsSheetState extends ConsumerState<_ProfileSettingsSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(
      text: widget.profile.firstName ?? '',
    );
    _lastNameController = TextEditingController(
      text: widget.profile.lastName ?? '',
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final profileState = ref.watch(settingsProfileControllerProvider);
    final isSaving = profileState.asData?.value.isUpdatingProfile ?? false;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          PawlySpacing.lg,
          PawlySpacing.sm,
          PawlySpacing.lg,
          PawlySpacing.lg + viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Профиль',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: PawlySpacing.md),
                PawlyTextField(
                  controller: _firstNameController,
                  label: 'Имя',
                  textCapitalization: TextCapitalization.words,
                  enabled: !isSaving,
                ),
                const SizedBox(height: PawlySpacing.md),
                PawlyTextField(
                  controller: _lastNameController,
                  label: 'Фамилия',
                  textCapitalization: TextCapitalization.words,
                  enabled: !isSaving,
                ),
                const SizedBox(height: PawlySpacing.lg),
                PawlyButton(
                  label: isSaving ? 'Сохраняем...' : 'Сохранить',
                  onPressed: isSaving ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();

    final isNameChanged =
        firstName != (widget.profile.firstName ?? '').trim() ||
            lastName != (widget.profile.lastName ?? '').trim();

    if (!isNameChanged) {
      Navigator.of(context).pop();
      return;
    }

    try {
      final controller = ref.read(settingsProfileControllerProvider.notifier);
      await controller.updateName(
        firstName: firstName,
        lastName: lastName,
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось сохранить настройки профиля.'),
        ),
      );
    }
  }
}
