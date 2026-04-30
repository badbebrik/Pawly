import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/design_system.dart';
import '../../controllers/pets_controller.dart';

class JoinPetByCodeDialog extends ConsumerStatefulWidget {
  const JoinPetByCodeDialog({super.key});

  @override
  ConsumerState<JoinPetByCodeDialog> createState() =>
      _JoinPetByCodeDialogState();
}

class _JoinPetByCodeDialogState extends ConsumerState<JoinPetByCodeDialog> {
  late final TextEditingController _controller;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Присоединиться по коду'),
      content: TextField(
        controller: _controller,
        textCapitalization: TextCapitalization.characters,
        maxLength: 6,
        decoration: const InputDecoration(
          hintText: 'Введите код',
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: Text(_isSubmitting ? 'Подключаем...' : 'Подключиться'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final code = _controller.text.trim().toUpperCase();
    if (code.length != 6) {
      showPawlySnackBar(
        context,
        message: 'Код должен содержать 6 символов.',
        tone: PawlySnackBarTone.error,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final petId = await ref
          .read(petsControllerProvider.notifier)
          .acceptInviteByCode(code);
      await ref.read(petsControllerProvider.notifier).reload();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(petId);
    } catch (error) {
      if (!mounted) {
        return;
      }
      showPawlySnackBar(
        context,
        message: acceptInviteByCodeErrorMessage(error),
        tone: PawlySnackBarTone.error,
      );
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}

String acceptInviteByCodeErrorMessage(Object error) {
  if (error is StateError) {
    return error.message.toString();
  }
  return 'Не удалось присоединиться по коду.';
}
