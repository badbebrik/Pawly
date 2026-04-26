import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../../../../../design_system/design_system.dart';
import 'pet_form_models.dart';

class PetFormCatalogColorChip extends StatelessWidget {
  const PetFormCatalogColorChip({
    required this.label,
    required this.hex,
    required this.selected,
    this.onTap,
    super.key,
  });

  final String label;
  final String hex;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final swatch = petFormColorFromHex(hex) ?? colorScheme.primary;
    final lightSwatch = petFormIsLightColor(swatch);
    final background = selected
        ? lightSwatch
            ? colorScheme.onSurface.withValues(alpha: 0.06)
            : swatch.withValues(alpha: 0.16)
        : Color.alphaBlend(
            swatch.withValues(alpha: lightSwatch ? 0.03 : 0.07),
            colorScheme.surface,
          );
    final chipBorderColor = lightSwatch
        ? colorScheme.outline.withValues(alpha: selected ? 0.74 : 0.42)
        : selected
            ? swatch.withValues(alpha: 0.55)
            : swatch.withValues(alpha: 0.18);
    final swatchBorderColor = lightSwatch
        ? colorScheme.outline.withValues(alpha: 0.82)
        : colorScheme.surface.withValues(alpha: 0.82);
    final markerColor = lightSwatch ? colorScheme.onSurfaceVariant : swatch;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PawlyRadius.pill),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: PawlySpacing.sm,
            vertical: PawlySpacing.xs,
          ),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(PawlyRadius.pill),
            border: Border.all(
              color: chipBorderColor,
              width: selected ? 1.2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: swatch,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: swatchBorderColor,
                    width: lightSwatch ? 1.4 : 1.2,
                  ),
                ),
              ),
              const SizedBox(width: PawlySpacing.xxs),
              if (selected) ...<Widget>[
                Icon(Icons.check_rounded, size: 16, color: markerColor),
                const SizedBox(width: PawlySpacing.xxs),
              ],
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PetFormCustomColorChip extends StatelessWidget {
  const PetFormCustomColorChip({
    required this.color,
    required this.onDeleted,
    super.key,
  });

  final PetFormCustomColor color;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final swatch = petFormColorFromHex(color.hex) ?? colorScheme.outline;
    final lightSwatch = petFormIsLightColor(swatch);
    final displayName =
        color.name.trim().isEmpty ? color.hex : color.name.trim();
    final borderColor = lightSwatch
        ? colorScheme.outline.withValues(alpha: 0.66)
        : swatch.withValues(alpha: 0.28);
    final swatchBorderColor = lightSwatch
        ? colorScheme.outline.withValues(alpha: 0.82)
        : colorScheme.outlineVariant;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: PawlySpacing.sm,
        vertical: PawlySpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          swatch.withValues(alpha: lightSwatch ? 0.04 : 0.10),
          colorScheme.surface,
        ),
        borderRadius: BorderRadius.circular(PawlyRadius.pill),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: swatch,
              shape: BoxShape.circle,
              border: Border.all(color: swatchBorderColor, width: 1.4),
            ),
          ),
          const SizedBox(width: PawlySpacing.xs),
          Text(displayName, style: theme.textTheme.labelLarge),
          if (onDeleted != null) ...<Widget>[
            const SizedBox(width: PawlySpacing.xs),
            GestureDetector(
              onTap: onDeleted,
              child: Icon(
                Icons.close_rounded,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class PetFormCustomColorPickerDialog extends StatefulWidget {
  const PetFormCustomColorPickerDialog({super.key});

  @override
  State<PetFormCustomColorPickerDialog> createState() =>
      _PetFormCustomColorPickerDialogState();
}

class _PetFormCustomColorPickerDialogState
    extends State<PetFormCustomColorPickerDialog> {
  final _nameController = TextEditingController();
  Color _current = const Color(0xFFE6A86A);

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final argb = _current.toARGB32().toRadixString(16).padLeft(8, '0');
    final hex = '#${argb.substring(2).toUpperCase()}';
    Navigator.of(context).pop(
      PetFormCustomColor(
        hex: hex,
        name: _nameController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Свой цвет'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ColorPicker(
              pickerColor: _current,
              onColorChanged: (color) {
                setState(() {
                  _current = color;
                });
              },
              enableAlpha: false,
              displayThumbColor: true,
              paletteType: PaletteType.hueWheel,
              pickerAreaHeightPercent: 0.82,
              labelTypes: const <ColorLabelType>[],
            ),
            const SizedBox(height: PawlySpacing.sm),
            TextField(
              controller: _nameController,
              maxLength: 24,
              decoration: const InputDecoration(
                labelText: 'Название цвета',
                hintText: 'Например: карамельный',
              ),
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Добавить'),
        ),
      ],
    );
  }
}

Color? petFormColorFromHex(String hex) {
  final normalized = hex.trim().replaceFirst('#', '');
  if (normalized.length != 6) return null;
  final value = int.tryParse(normalized, radix: 16);
  if (value == null) return null;
  return Color(0xFF000000 | value);
}

bool petFormIsLightColor(Color color) => color.computeLuminance() > 0.82;
