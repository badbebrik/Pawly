import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../../../../design_system/design_system.dart';
import '../../../catalog/data/catalog_cache_models.dart';

class PetFormCustomColor {
  const PetFormCustomColor({
    required this.hex,
    required this.name,
  });

  final String hex;
  final String name;
}

class PetFormSectionCard extends StatelessWidget {
  const PetFormSectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(PawlySpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(PawlyRadius.xl),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.82),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _PetFormSectionTitle(title: title, subtitle: subtitle),
          const SizedBox(height: PawlySpacing.md),
          child,
        ],
      ),
    );
  }
}

class _PetFormSectionTitle extends StatelessWidget {
  const _PetFormSectionTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style:
              theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: PawlySpacing.xxs),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class PetFormStepTabs<T> extends StatelessWidget {
  const PetFormStepTabs({
    required this.steps,
    required this.value,
    required this.labelBuilder,
    required this.onChanged,
    super.key,
  });

  final List<T> steps;
  final T value;
  final String Function(T step) labelBuilder;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(PawlySpacing.xxs),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(PawlyRadius.xl),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: steps.map((entry) {
            final selected = entry == value;
            return Padding(
              padding: const EdgeInsets.only(right: PawlySpacing.xxs),
              child: _PetFormStepTabButton(
                label: labelBuilder(entry),
                selected: selected,
                onTap: () => onChanged(entry),
              ),
            );
          }).toList(growable: false),
        ),
      ),
    );
  }
}

class _PetFormStepTabButton extends StatelessWidget {
  const _PetFormStepTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PawlyRadius.lg),
        child: AnimatedContainer(
          duration: PawlyMotion.quick,
          height: 40,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: PawlySpacing.sm),
          decoration: BoxDecoration(
            color: selected
                ? colorScheme.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(PawlyRadius.lg),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: selected ? colorScheme.primary : colorScheme.onSurface,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class PetFormCardPickerOption<T> {
  const PetFormCardPickerOption({
    required this.value,
    required this.label,
    required this.icon,
    this.accent,
  });

  final T value;
  final String label;
  final IconData icon;
  final Color? accent;
}

class PetFormTwoOptionCardPicker<T> extends StatelessWidget {
  const PetFormTwoOptionCardPicker({
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
    super.key,
  }) : assert(options.length == 2);

  final String title;
  final T value;
  final List<PetFormCardPickerOption<T>> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: PawlySpacing.xs),
        Row(
          children: <Widget>[
            Expanded(
              child: _PetFormOptionCard<T>(
                option: options[0],
                selected: value == options[0].value,
                onTap: () => onChanged(options[0].value),
              ),
            ),
            const SizedBox(width: PawlySpacing.sm),
            Expanded(
              child: _PetFormOptionCard<T>(
                option: options[1],
                selected: value == options[1].value,
                onTap: () => onChanged(options[1].value),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PetFormOptionCard<T> extends StatelessWidget {
  const _PetFormOptionCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final PetFormCardPickerOption<T> option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = option.accent ?? colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PawlyRadius.lg),
        child: Ink(
          height: 92,
          padding: const EdgeInsets.all(PawlySpacing.md),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.12)
                : colorScheme.onSurface.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(PawlyRadius.lg),
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: 0.40)
                  : colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                option.icon,
                color: selected ? accent : colorScheme.onSurfaceVariant,
                size: 28,
              ),
              const Spacer(),
              Text(
                option.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: selected ? accent : colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PetFormModeToggle<T> extends StatelessWidget {
  const PetFormModeToggle({
    required this.title,
    required this.value,
    required this.catalogValue,
    required this.customValue,
    required this.onChanged,
    super.key,
  });

  final String title;
  final T value;
  final T catalogValue;
  final T customValue;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: PawlySpacing.xs),
        Container(
          padding: const EdgeInsets.all(PawlySpacing.xxs),
          decoration: BoxDecoration(
            color: colorScheme.onSurface.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(PawlyRadius.lg),
          ),
          child: Row(
            children: <Widget>[
              PetFormSegmentButton(
                label: 'Из каталога',
                selected: value == catalogValue,
                onTap: () => onChanged(catalogValue),
              ),
              PetFormSegmentButton(
                label: 'Свой вариант',
                selected: value == customValue,
                onTap: () => onChanged(customValue),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class PetFormSegmentButton extends StatelessWidget {
  const PetFormSegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(PawlySpacing.xxxs),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(PawlyRadius.md),
            child: AnimatedContainer(
              duration: PawlyMotion.quick,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? colorScheme.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(PawlyRadius.md),
                boxShadow: selected
                    ? <BoxShadow>[
                        BoxShadow(
                          color: colorScheme.shadow.withValues(alpha: 0.07),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: selected
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PetFormSpeciesGridPicker extends StatelessWidget {
  const PetFormSpeciesGridPicker({
    required this.species,
    required this.selectedId,
    required this.onChanged,
    super.key,
  });

  final List<CatalogOption> species;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 520 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: species.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: PawlySpacing.sm,
            crossAxisSpacing: PawlySpacing.sm,
            childAspectRatio: 1.38,
          ),
          itemBuilder: (context, index) {
            final item = species[index];
            return _PetFormSpeciesCard(
              option: item,
              selected: selectedId == item.id,
              onTap: () => onChanged(item.id),
            );
          },
        );
      },
    );
  }
}

class _PetFormSpeciesCard extends StatelessWidget {
  const _PetFormSpeciesCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final CatalogOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PawlyRadius.lg),
        child: Ink(
          padding: const EdgeInsets.all(PawlySpacing.md),
          decoration: BoxDecoration(
            color: selected
                ? colorScheme.primary.withValues(alpha: 0.10)
                : colorScheme.onSurface.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(PawlyRadius.lg),
            border: Border.all(
              color: selected
                  ? colorScheme.primary.withValues(alpha: 0.36)
                  : colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                petFormSpeciesEmoji(option),
                style: const TextStyle(fontSize: 30, height: 1),
              ),
              const Spacer(),
              Text(
                option.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: selected ? colorScheme.primary : colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PetFormBreedSearchPicker extends StatelessWidget {
  const PetFormBreedSearchPicker({
    required this.controller,
    required this.query,
    required this.breeds,
    required this.totalCount,
    required this.selectedId,
    required this.onQueryChanged,
    required this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final String query;
  final List<CatalogBreedOption> breeds;
  final int totalCount;
  final String? selectedId;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final trimmedQuery = query.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        TextField(
          controller: controller,
          onChanged: onQueryChanged,
          decoration: InputDecoration(
            hintText: 'Поиск породы',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: trimmedQuery.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      controller.clear();
                      onQueryChanged('');
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
        ),
        const SizedBox(height: PawlySpacing.sm),
        if (breeds.isEmpty)
          Text(
            totalCount == 0
                ? 'Для выбранного вида пород нет.'
                : 'Ничего не найдено.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: breeds.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: PawlySpacing.xs),
            itemBuilder: (context, index) {
              final breed = breeds[index];
              return _PetFormBreedSearchResultTile(
                breed: breed,
                selected: selectedId == breed.id,
                onTap: () => onChanged(breed.id),
              );
            },
          ),
      ],
    );
  }
}

class _PetFormBreedSearchResultTile extends StatelessWidget {
  const _PetFormBreedSearchResultTile({
    required this.breed,
    required this.selected,
    required this.onTap,
  });

  final CatalogBreedOption breed;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PawlyRadius.md),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: PawlySpacing.md,
            vertical: PawlySpacing.sm,
          ),
          decoration: BoxDecoration(
            color: selected
                ? colorScheme.primary.withValues(alpha: 0.10)
                : colorScheme.onSurface.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(PawlyRadius.md),
            border: Border.all(
              color: selected
                  ? colorScheme.primary.withValues(alpha: 0.28)
                  : colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  breed.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (selected)
                Icon(
                  Icons.check_circle_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

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

class PetFormDateButton extends StatelessWidget {
  const PetFormDateButton({
    required this.label,
    required this.value,
    required this.onPressed,
    super.key,
  });

  final String label;
  final String value;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(PawlyRadius.md),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: PawlySpacing.md,
            vertical: PawlySpacing.sm,
          ),
          decoration: BoxDecoration(
            color: colorScheme.onSurface.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(PawlyRadius.md),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.calendar_today_rounded,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: PawlySpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(label, style: theme.textTheme.labelLarge),
                    const SizedBox(height: PawlySpacing.xxxs),
                    Text(
                      value,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
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

String petFormSpeciesEmoji(CatalogOption option) {
  final iconKey = option.iconName.trim().toLowerCase().replaceAll('-', '_');

  switch (iconKey) {
    case 'dog':
      return '🐕';
    case 'cat':
      return '🐈';
    case 'parrot':
      return '🦜';
    case 'rabbit':
      return '🐇';
    case 'hamster':
      return '🐹';
    case 'rat':
      return '🐀';
    case 'mouse':
      return '🐁';
    case 'lizard':
      return '🦎';
    case 'snake':
      return '🐍';
    case 'horse':
      return '🐎';
  }

  final normalized =
      '${option.id} ${option.name} ${option.iconName}'.trim().toLowerCase();
  if (normalized.contains('собак') || normalized.contains('dog')) {
    return '🐕';
  }
  if (normalized.contains('кош') ||
      normalized.contains('кот') ||
      normalized.contains('cat')) {
    return '🐈';
  }
  if (normalized.contains('попуг') ||
      normalized.contains('parrot') ||
      normalized.contains('птиц') ||
      normalized.contains('bird')) {
    return '🦜';
  }
  if (normalized.contains('птиц') || normalized.contains('bird')) {
    return '🐦';
  }
  if (normalized.contains('крол') || normalized.contains('rabbit')) {
    return '🐇';
  }
  if (normalized.contains('хом') || normalized.contains('hamster')) {
    return '🐹';
  }
  if (normalized.contains('крыс') || normalized.contains('rat')) {
    return '🐀';
  }
  if (normalized.contains('мыш') || normalized.contains('mouse')) {
    return '🐁';
  }
  if (normalized.contains('грыз') || normalized.contains('rodent')) {
    return '🐹';
  }
  if (normalized.contains('репт') ||
      normalized.contains('ящер') ||
      normalized.contains('reptile') ||
      normalized.contains('turtle')) {
    return '🦎';
  }
  if (normalized.contains('лошад') || normalized.contains('horse')) {
    return '🐎';
  }
  if (normalized.contains('зме') || normalized.contains('snake')) {
    return '🐍';
  }
  return '🐾';
}
