import 'package:flutter/material.dart';

Future<String?> showAttachmentRenameDialog(
  BuildContext context, {
  required String initialName,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _AttachmentRenameDialog(initialName: initialName),
  );
}

class _AttachmentRenameDialog extends StatefulWidget {
  const _AttachmentRenameDialog({required this.initialName});

  final String initialName;

  @override
  State<_AttachmentRenameDialog> createState() =>
      _AttachmentRenameDialogState();
}

class _AttachmentRenameDialogState extends State<_AttachmentRenameDialog> {
  late final TextEditingController _controller;
  late final String _extension;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final parts = _splitFileName(widget.initialName);
    _extension = parts.extension;
    _controller = TextEditingController(text: parts.nameWithoutExtension);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Переименовать файл'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: 'Название файла',
          suffixText: _extension.isEmpty ? null : _extension,
          errorText: _errorText,
        ),
        textInputAction: TextInputAction.done,
        onChanged: (_) {
          if (_errorText != null) {
            setState(() => _errorText = null);
          }
        },
        onSubmitted: (_) => _submit(),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Сохранить'),
        ),
      ],
    );
  }

  void _submit() {
    final nameWithoutExtension = _controller.text.trim();
    if (nameWithoutExtension.isEmpty) {
      setState(() => _errorText = 'Введите название файла.');
      return;
    }
    if (nameWithoutExtension.contains('/') ||
        nameWithoutExtension.contains(r'\')) {
      setState(() => _errorText = 'Название не должно содержать / или \\.');
      return;
    }

    final fileName = '$nameWithoutExtension$_extension';
    if (fileName.length > 255) {
      setState(
        () => _errorText = 'Название не должно быть длиннее 255 символов.',
      );
      return;
    }

    Navigator.of(context).pop(fileName);
  }
}

_FileNameParts _splitFileName(String value) {
  final normalized = value.trim().isEmpty ? 'Файл' : value.trim();
  final slashIndex = _lastPathSeparatorIndex(normalized);
  final fileName =
      slashIndex >= 0 ? normalized.substring(slashIndex + 1) : normalized;
  final lastDotIndex = fileName.lastIndexOf('.');
  if (lastDotIndex <= 0 || lastDotIndex == fileName.length - 1) {
    return _FileNameParts(nameWithoutExtension: fileName, extension: '');
  }
  return _FileNameParts(
    nameWithoutExtension: fileName.substring(0, lastDotIndex),
    extension: fileName.substring(lastDotIndex),
  );
}

int _lastPathSeparatorIndex(String value) {
  final slash = value.lastIndexOf('/');
  final backslash = value.lastIndexOf(r'\');
  return slash > backslash ? slash : backslash;
}

class _FileNameParts {
  const _FileNameParts({
    required this.nameWithoutExtension,
    required this.extension,
  });

  final String nameWithoutExtension;
  final String extension;
}
