import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/models/pet_models.dart';
import '../../../../design_system/design_system.dart';
import '../../../catalog/data/catalog_cache_models.dart';
import '../../../catalog/presentation/providers/pet_dictionaries_providers.dart';
import '../providers/active_pet_details_controller.dart';
import '../providers/pets_controller.dart';

enum _CatalogPickMode { catalog, custom }

final _petEditInitialDataProvider = FutureProvider.autoDispose
    .family<_PetEditInitialData, String>((ref, petId) async {
  final pet = await ref.read(petsRepositoryProvider).getPetById(petId);
  final catalog = await ref.read(petDictionariesSyncProvider.future);
  return _PetEditInitialData(pet: pet, catalog: catalog);
});

class PetEditPage extends ConsumerStatefulWidget {
  const PetEditPage({
    required this.petId,
    super.key,
  });

  final String petId;

  @override
  ConsumerState<PetEditPage> createState() => _PetEditPageState();
}

class _PetEditPageState extends ConsumerState<PetEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _customBreedCtrl = TextEditingController();
  final _customPatternCtrl = TextEditingController();
  final _microchipCtrl = TextEditingController();

  bool _initialized = false;
  bool _isSubmitting = false;

  late String _sex;
  DateTime? _birthDate;
  late String _speciesId;

  late _CatalogPickMode _breedMode;
  String? _breedId;
  String _customBreedName = '';

  late _CatalogPickMode _patternMode;
  String? _patternId;
  String _customPatternName = '';

  Set<String> _colorIds = <String>{};
  List<String> _customColorsHex = <String>[];
  late String _isNeutered;
  late bool _isOutdoor;
  DateTime? _microchipInstalledAt;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _customBreedCtrl.dispose();
    _customPatternCtrl.dispose();
    _microchipCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initialDataAsync =
        ref.watch(_petEditInitialDataProvider(widget.petId));

    return Scaffold(
      appBar: AppBar(title: const Text('Редактирование питомца')),
      body: initialDataAsync.when(
        data: (data) {
          _initializeOnce(data.pet);

          final breedsForSpecies = data.catalog.breeds
              .where((entry) => entry.speciesId == _speciesId)
              .toList(growable: false);

          return SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(PawlySpacing.lg),
                children: <Widget>[
                  _SectionCard(
                    title: 'Основное',
                    subtitle: 'Базовая информация о питомце',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        PawlyTextField(
                          controller: _nameCtrl,
                          label: 'Имя питомца',
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Введите имя питомца';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: PawlySpacing.sm),
                        DropdownButtonFormField<String>(
                          value: _sex,
                          decoration: const InputDecoration(labelText: 'Пол'),
                          items: const <DropdownMenuItem<String>>[
                            DropdownMenuItem(
                                value: 'UNKNOWN', child: Text('Не указан')),
                            DropdownMenuItem(
                                value: 'MALE', child: Text('Самец')),
                            DropdownMenuItem(
                              value: 'FEMALE',
                              child: Text('Самка'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _sex = value);
                          },
                        ),
                        const SizedBox(height: PawlySpacing.sm),
                        DropdownButtonFormField<String>(
                          value: _speciesId,
                          decoration: const InputDecoration(labelText: 'Вид'),
                          items: data.catalog.species
                              .map(
                                (entry) => DropdownMenuItem<String>(
                                  value: entry.id,
                                  child: Text(entry.name),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _speciesId = value;
                              _breedId = null;
                              _breedMode = _CatalogPickMode.catalog;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Выберите вид';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: PawlySpacing.sm),
                        _DateButton(
                          label: _birthDate == null
                              ? 'Дата рождения'
                              : 'Дата рождения: ${_formatDate(_birthDate!)}',
                          onTap: () => _pickDate(
                            initial: _birthDate,
                            lastDate: DateTime.now(),
                            onPicked: (value) =>
                                setState(() => _birthDate = value),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: PawlySpacing.lg),
                  _SectionCard(
                    title: 'Порода и внешность',
                    subtitle: 'Каталожные и пользовательские параметры',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _ModeToggle(
                          title: 'Порода',
                          mode: _breedMode,
                          onChanged: (value) =>
                              setState(() => _breedMode = value),
                        ),
                        const SizedBox(height: PawlySpacing.sm),
                        if (_breedMode == _CatalogPickMode.catalog)
                          DropdownButtonFormField<String>(
                            value: _breedId,
                            decoration:
                                const InputDecoration(labelText: 'Порода'),
                            items: breedsForSpecies
                                .map(
                                  (entry) => DropdownMenuItem<String>(
                                    value: entry.id,
                                    child: Text(entry.name),
                                  ),
                                )
                                .toList(growable: false),
                            onChanged: (value) =>
                                setState(() => _breedId = value),
                            validator: (value) {
                              if (_breedMode == _CatalogPickMode.catalog &&
                                  (value == null || value.isEmpty)) {
                                return 'Выберите породу';
                              }
                              return null;
                            },
                          )
                        else
                          PawlyTextField(
                            controller: _customBreedCtrl,
                            label: 'Своя порода',
                            onChanged: (value) => _customBreedName = value,
                            validator: (value) {
                              if (_breedMode == _CatalogPickMode.custom &&
                                  (value == null || value.trim().isEmpty)) {
                                return 'Введите свою породу';
                              }
                              return null;
                            },
                          ),
                        const SizedBox(height: PawlySpacing.md),
                        _ModeToggle(
                          title: 'Паттерн',
                          mode: _patternMode,
                          onChanged: (value) =>
                              setState(() => _patternMode = value),
                        ),
                        const SizedBox(height: PawlySpacing.sm),
                        if (_patternMode == _CatalogPickMode.catalog)
                          DropdownButtonFormField<String>(
                            value: _patternId,
                            decoration:
                                const InputDecoration(labelText: 'Паттерн'),
                            items: data.catalog.patterns
                                .map(
                                  (entry) => DropdownMenuItem<String>(
                                    value: entry.id,
                                    child: Text(entry.name),
                                  ),
                                )
                                .toList(growable: false),
                            onChanged: (value) =>
                                setState(() => _patternId = value),
                            validator: (value) {
                              if (_patternMode == _CatalogPickMode.catalog &&
                                  (value == null || value.isEmpty)) {
                                return 'Выберите паттерн';
                              }
                              return null;
                            },
                          )
                        else
                          PawlyTextField(
                            controller: _customPatternCtrl,
                            label: 'Свой паттерн',
                            onChanged: (value) => _customPatternName = value,
                            validator: (value) {
                              if (_patternMode == _CatalogPickMode.custom &&
                                  (value == null || value.trim().isEmpty)) {
                                return 'Введите свой паттерн';
                              }
                              return null;
                            },
                          ),
                        const SizedBox(height: PawlySpacing.md),
                        Text(
                          'Цвета',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: PawlySpacing.xs),
                        Wrap(
                          spacing: PawlySpacing.xs,
                          runSpacing: PawlySpacing.xs,
                          children: data.catalog.colors.map((entry) {
                            final selected = _colorIds.contains(entry.id);
                            return FilterChip(
                              label: Text(entry.name),
                              selected: selected,
                              onSelected: (_) => setState(() {
                                if (selected) {
                                  _colorIds.remove(entry.id);
                                } else {
                                  _colorIds.add(entry.id);
                                }
                              }),
                            );
                          }).toList(growable: false),
                        ),
                        const SizedBox(height: PawlySpacing.sm),
                        Wrap(
                          spacing: PawlySpacing.xs,
                          runSpacing: PawlySpacing.xs,
                          children: <Widget>[
                            ..._customColorsHex.asMap().entries.map(
                                  (entry) => InputChip(
                                    label: Text(entry.value),
                                    onDeleted: () => setState(
                                      () =>
                                          _customColorsHex.removeAt(entry.key),
                                    ),
                                  ),
                                ),
                            ActionChip(
                              label: const Text('Свой цвет'),
                              avatar: const Icon(
                                Icons.palette_outlined,
                                size: 18,
                              ),
                              onPressed: _openColorPicker,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: PawlySpacing.lg),
                  _SectionCard(
                    title: 'Дополнительно',
                    subtitle: 'Чип, стерилизация и режим жизни',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        DropdownButtonFormField<String>(
                          value: _isNeutered,
                          decoration:
                              const InputDecoration(labelText: 'Стерилизация'),
                          items: const <DropdownMenuItem<String>>[
                            DropdownMenuItem(
                              value: 'UNKNOWN',
                              child: Text('Неизвестно'),
                            ),
                            DropdownMenuItem(value: 'YES', child: Text('Да')),
                            DropdownMenuItem(value: 'NO', child: Text('Нет')),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _isNeutered = value);
                          },
                        ),
                        const SizedBox(height: PawlySpacing.sm),
                        SwitchListTile.adaptive(
                          title: const Text('Уличный/свободный выгул'),
                          value: _isOutdoor,
                          onChanged: (value) =>
                              setState(() => _isOutdoor = value),
                          contentPadding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: PawlySpacing.sm),
                        PawlyTextField(
                          controller: _microchipCtrl,
                          label: 'ID микрочипа',
                        ),
                        const SizedBox(height: PawlySpacing.sm),
                        _DateButton(
                          label: _microchipInstalledAt == null
                              ? 'Дата установки чипа'
                              : 'Дата установки: ${_formatDate(_microchipInstalledAt!)}',
                          onTap: () => _pickDate(
                            initial: _microchipInstalledAt,
                            lastDate: DateTime.now(),
                            onPicked: (value) => setState(
                              () => _microchipInstalledAt = value,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: PawlySpacing.xl),
                  PawlyButton(
                    label:
                        _isSubmitting ? 'Сохраняем...' : 'Сохранить изменения',
                    onPressed: _isSubmitting ? null : () => _submit(data.pet),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: PawlyButton(
            label: 'Повторить',
            onPressed: () =>
                ref.invalidate(_petEditInitialDataProvider(widget.petId)),
            variant: PawlyButtonVariant.secondary,
            fullWidth: false,
          ),
        ),
      ),
    );
  }

  void _initializeOnce(Pet pet) {
    if (_initialized) {
      return;
    }

    _initialized = true;
    _nameCtrl.text = pet.name;
    _sex = pet.sex;
    _birthDate = pet.birthDate;
    _speciesId = pet.speciesId;

    _breedMode = pet.breed.source == 'CUSTOM'
        ? _CatalogPickMode.custom
        : _CatalogPickMode.catalog;
    _breedId = pet.breed.systemBreedId;
    _customBreedName = pet.breed.customBreedName ?? '';
    _customBreedCtrl.text = _customBreedName;

    _patternMode = pet.coatPattern.source == 'CUSTOM'
        ? _CatalogPickMode.custom
        : _CatalogPickMode.catalog;
    _patternId = pet.coatPattern.systemCoatPatternId;
    _customPatternName = pet.coatPattern.customCoatPatternName ?? '';
    _customPatternCtrl.text = _customPatternName;

    _colorIds = pet.colors
        .where((entry) => entry.presetId != null && entry.presetId!.isNotEmpty)
        .map((entry) => entry.presetId!)
        .toSet();
    _customColorsHex = pet.colors
        .where(
          (entry) => entry.hexOverride != null && entry.hexOverride!.isNotEmpty,
        )
        .map((entry) => entry.hexOverride!)
        .toList(growable: false);

    _isNeutered = pet.isNeutered;
    _isOutdoor = pet.isOutdoor;
    _microchipCtrl.text = pet.microchipId ?? '';
    _microchipInstalledAt = pet.microchipInstalledAt;
  }

  Future<void> _submit(Pet pet) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_colorIds.isEmpty && _customColorsHex.isEmpty) {
      _showMessage('Выберите минимум один цвет.');
      return;
    }

    final payload = UpdatePetPayload(
      rowVersion: pet.rowVersion,
      payload: CreatePetPayload(
        name: _nameCtrl.text.trim(),
        speciesId: _speciesId,
        sex: _sex,
        birthDate: _birthDate,
        breedId: _breedMode == _CatalogPickMode.catalog ? _breedId : null,
        customBreedName: _breedMode == _CatalogPickMode.custom
            ? _customBreedCtrl.text.trim()
            : null,
        colors: _buildColorsPayload(),
        patternId: _patternMode == _CatalogPickMode.catalog ? _patternId : null,
        customPatternName: _patternMode == _CatalogPickMode.custom
            ? _customPatternCtrl.text.trim()
            : null,
        isNeutered: _isNeutered,
        isOutdoor: _isOutdoor,
        profilePhotoFileId: pet.profilePhotoFileId,
        microchipId: _microchipCtrl.text.trim().isEmpty
            ? null
            : _microchipCtrl.text.trim(),
        microchipInstalledAt: _microchipInstalledAt,
      ),
    );

    setState(() => _isSubmitting = true);

    try {
      await ref.read(petsRepositoryProvider).updatePet(
            petId: widget.petId,
            payload: payload,
          );
      ref.invalidate(activePetDetailsControllerProvider);
      await ref.read(petsControllerProvider.notifier).refreshAfterPetMutation();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showMessage('Не удалось сохранить изменения питомца.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  List<PetColor> _buildColorsPayload() {
    final colors = <PetColor>[];
    var sortOrder = 0;

    for (final id in _colorIds) {
      colors.add(PetColor(presetId: id, sortOrder: sortOrder++));
    }

    for (final rawHex in _customColorsHex) {
      final hex = _normalizeHex(rawHex);
      if (hex != null) {
        colors.add(PetColor(hexOverride: hex, sortOrder: sortOrder++));
      }
    }

    return colors;
  }

  Future<void> _pickDate({
    required DateTime? initial,
    required DateTime lastDate,
    required ValueChanged<DateTime?> onPicked,
  }) async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(1990),
      lastDate: lastDate,
      initialDate: initial ?? DateTime(lastDate.year - 1),
    );
    onPicked(picked);
  }

  Future<void> _openColorPicker() async {
    Color current = Colors.orange;
    var confirmed = false;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Выберите цвет'),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: current,
              onColorChanged: (color) => current = color,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () {
                confirmed = true;
                Navigator.pop(context);
              },
              child: const Text('Выбрать'),
            ),
          ],
        );
      },
    );

    if (!confirmed) {
      return;
    }

    final argb = current.toARGB32().toRadixString(16).padLeft(8, '0');
    final hex = '#${argb.substring(2).toUpperCase()}';
    setState(() {
      if (!_customColorsHex.contains(hex)) {
        _customColorsHex = <String>[..._customColorsHex, hex];
      }
    });
  }

  String? _normalizeHex(String input) {
    final value = input.trim().toUpperCase();
    final prepared = value.startsWith('#') ? value : '#$value';
    final regExp = RegExp(r'^#[0-9A-F]{6}$');
    if (!regExp.hasMatch(prepared)) {
      return null;
    }
    return prepared;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PawlyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _SectionTitle(title: title, subtitle: subtitle),
          const SizedBox(height: PawlySpacing.md),
          child,
        ],
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({
    required this.title,
    required this.mode,
    required this.onChanged,
  });

  final String title;
  final _CatalogPickMode mode;
  final ValueChanged<_CatalogPickMode> onChanged;

  @override
  Widget build(BuildContext context) {
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
        Wrap(
          spacing: PawlySpacing.xs,
          runSpacing: PawlySpacing.xs,
          children: <Widget>[
            ChoiceChip(
              label: const Text('Из каталога'),
              selected: mode == _CatalogPickMode.catalog,
              onSelected: (_) => onChanged(_CatalogPickMode.catalog),
            ),
            ChoiceChip(
              label: const Text('Свой вариант'),
              selected: mode == _CatalogPickMode.custom,
              onSelected: (_) => onChanged(_CatalogPickMode.custom),
            ),
          ],
        ),
      ],
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PawlyRadius.lg),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: PawlySpacing.md,
            vertical: PawlySpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(PawlyRadius.lg),
            border: Border.all(color: colorScheme.outlineVariant),
            color: colorScheme.surface,
          ),
          child: Row(
            children: <Widget>[
              Icon(Icons.event_rounded, color: colorScheme.primary),
              const SizedBox(width: PawlySpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium,
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

class _PetEditInitialData {
  const _PetEditInitialData({
    required this.pet,
    required this.catalog,
  });

  final Pet pet;
  final CatalogSnapshot catalog;
}

String _formatDate(DateTime value) {
  final local = value.toLocal();
  final yyyy = local.year.toString().padLeft(4, '0');
  final mm = local.month.toString().padLeft(2, '0');
  final dd = local.day.toString().padLeft(2, '0');
  return '$yyyy-$mm-$dd';
}
