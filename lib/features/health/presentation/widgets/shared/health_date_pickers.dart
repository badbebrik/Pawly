import 'package:flutter/material.dart';

import '../../../../../design_system/design_system.dart';
import '../../../shared/formatters/health_display_formatters.dart';

Future<DateTime?> pickHealthDate(
  BuildContext context, {
  required DateTime initialDate,
  DateTime? firstDate,
}) {
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate ?? DateTime(2000),
    lastDate: DateTime.now().add(const Duration(days: 3650)),
  );
}

Future<DateTime?> pickHealthDateTime(
  BuildContext context, {
  required DateTime initialDate,
  DateTime? firstDate,
}) async {
  final date = await pickHealthDate(
    context,
    initialDate: initialDate,
    firstDate: firstDate,
  );
  if (date == null || !context.mounted) {
    return null;
  }

  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initialDate),
  );
  if (time == null) {
    return null;
  }

  return DateTime(
    date.year,
    date.month,
    date.day,
    time.hour,
    time.minute,
  );
}

class HealthRequiredDateTimeDialog extends StatefulWidget {
  const HealthRequiredDateTimeDialog({
    required this.title,
    required this.description,
    required this.initialDate,
    this.firstDate,
    this.changeLabel = 'Изменить дату и время',
    this.cancelLabel = 'Отмена',
    this.submitLabel = 'Сохранить',
    this.icon = Icons.event_rounded,
    super.key,
  });

  final String title;
  final String description;
  final DateTime initialDate;
  final DateTime? firstDate;
  final String changeLabel;
  final String cancelLabel;
  final String submitLabel;
  final IconData icon;

  @override
  State<HealthRequiredDateTimeDialog> createState() =>
      _HealthRequiredDateTimeDialogState();
}

class _HealthRequiredDateTimeDialogState
    extends State<HealthRequiredDateTimeDialog> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: _HealthDateTimeDialogContent(
        description: widget.description,
        selectedDate: _selectedDate,
        buttonLabel: widget.changeLabel,
        icon: widget.icon,
        onPick: _pickDate,
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selectedDate),
          child: Text(widget.submitLabel),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked = await pickHealthDateTime(
      context,
      initialDate: _selectedDate,
      firstDate: widget.firstDate,
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }
}

class HealthOptionalDateTimeDialog extends StatefulWidget {
  const HealthOptionalDateTimeDialog({
    required this.title,
    required this.description,
    required this.initialDate,
    this.firstDate,
    this.changeLabel = 'Выбрать дату и время',
    this.cancelLabel = 'Пропустить',
    this.submitLabel = 'Сохранить',
    this.icon = Icons.refresh_rounded,
    super.key,
  });

  final String title;
  final String description;
  final DateTime initialDate;
  final DateTime? firstDate;
  final String changeLabel;
  final String cancelLabel;
  final String submitLabel;
  final IconData icon;

  @override
  State<HealthOptionalDateTimeDialog> createState() =>
      _HealthOptionalDateTimeDialogState();
}

class _HealthOptionalDateTimeDialogState
    extends State<HealthOptionalDateTimeDialog> {
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: _HealthDateTimeDialogContent(
        description: widget.description,
        selectedDate: _selectedDate,
        buttonLabel: widget.changeLabel,
        icon: widget.icon,
        onPick: _pickDate,
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.cancelLabel),
        ),
        FilledButton(
          onPressed: _selectedDate == null
              ? null
              : () => Navigator.of(context).pop(_selectedDate),
          child: Text(widget.submitLabel),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked = await pickHealthDateTime(
      context,
      initialDate: _selectedDate ?? widget.initialDate,
      firstDate: widget.firstDate ?? widget.initialDate,
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }
}

class _HealthDateTimeDialogContent extends StatelessWidget {
  const _HealthDateTimeDialogContent({
    required this.description,
    required this.selectedDate,
    required this.buttonLabel,
    required this.icon,
    required this.onPick,
  });

  final String description;
  final DateTime? selectedDate;
  final String buttonLabel;
  final IconData icon;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(description),
        const SizedBox(height: PawlySpacing.md),
        if (selectedDate != null)
          Text(
            formatHealthDateTime(selectedDate!),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        const SizedBox(height: PawlySpacing.sm),
        TextButton.icon(
          onPressed: onPick,
          icon: Icon(icon),
          label: Text(buttonLabel),
        ),
      ],
    );
  }
}
