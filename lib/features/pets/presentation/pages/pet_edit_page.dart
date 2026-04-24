import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/models/pet_models.dart';
import '../../../../design_system/design_system.dart';
import '../../../catalog/data/catalog_cache_models.dart';
import '../../../catalog/presentation/providers/pet_dictionaries_providers.dart';
import '../providers/active_pet_details_controller.dart';
import '../providers/pets_controller.dart';
import '../widgets/pet_form_widgets.dart';

enum _CatalogPickMode { catalog, custom }

enum _PetEditStep { basic, breed, appearance, optional }

const _petEditMaxColors = 10;

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
  final _customSpeciesCtrl = TextEditingController();
  final _customBreedCtrl = TextEditingController();
  final _customPatternCtrl = TextEditingController();
  final _microchipCtrl = TextEditingController();
  final _breedSearchCtrl = TextEditingController();

  bool _initialized = false;
  bool _isSubmitting = false;
  _PetEditStep _step = _PetEditStep.basic;
  String _breedSearchQuery = '';

  late String _sex;
  DateTime? _birthDate;
  late _CatalogPickMode _speciesMode;
  String? _speciesId;

  late _CatalogPickMode _breedMode;
  String? _breedId;
  String _customBreedName = '';

  late _CatalogPickMode _patternMode;
  String? _patternId;
  String _customPatternName = '';

  Set<String> _colorIds = <String>{};
  List<PetFormCustomColor> _customColors = <PetFormCustomColor>[];
  late String _isNeutered;
  late bool _isOutdoor;
  DateTime? _microchipInstalledAt;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _customSpeciesCtrl.dispose();
    _customBreedCtrl.dispose();
    _customPatternCtrl.dispose();
    _microchipCtrl.dispose();
    _breedSearchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accessAsync = ref.watch(petAccessPolicyProvider(widget.petId));

    return PawlyScreenScaffold(
      title: 'Редактирование',
      leading: IconButton(
        onPressed: () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.chevron_left_rounded, size: 30),
      ),
      body: accessAsync.when(
        data: (access) {
          if (!access.petWrite) {
            return const _PetEditNoAccessView();
          }

          final initialDataAsync =
              ref.watch(_petEditInitialDataProvider(widget.petId));
          return initialDataAsync.when(
            data: (data) {
              _initializeOnce(data.pet);

              final breedsForSpecies = data.catalog.breeds
                  .where((entry) => entry.speciesId == _speciesId)
                  .toList(growable: false);
              final breedSearchQuery = _breedSearchQuery.trim().toLowerCase();
              final filteredBreeds = breedSearchQuery.isEmpty
                  ? _defaultBreedResults(
                      breedsForSpecies,
                      selectedId: _breedId,
                    )
                  : breedsForSpecies
                      .where(
                        (entry) =>
                            entry.name.toLowerCase().contains(breedSearchQuery),
                      )
                      .take(24)
                      .toList(growable: false);
              final selectedColorCount =
                  _colorIds.length + _customColors.length;

              return SafeArea(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      PawlySpacing.md,
                      PawlySpacing.sm,
                      PawlySpacing.md,
                      PawlySpacing.xl,
                    ),
                    children: <Widget>[
                      PetFormStepTabs<_PetEditStep>(
                        steps: _PetEditStep.values,
                        value: _step,
                        labelBuilder: _editStepLabel,
                        onChanged: (step) => setState(() => _step = step),
                      ),
                      const SizedBox(height: PawlySpacing.md),
                      if (_step == _PetEditStep.basic)
                        PetFormSectionCard(
                          title: 'Основное',
                          subtitle: 'Кличка, пол, вид и дата рождения.',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              PawlyTextField(
                                controller: _nameCtrl,
                                label: 'Кличка',
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Введите кличку';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: PawlySpacing.md),
                              PetFormTwoOptionCardPicker<String>(
                                title: 'Пол',
                                value: _sex,
                                options: const <PetFormCardPickerOption<
                                    String>>[
                                  PetFormCardPickerOption<String>(
                                    value: 'MALE',
                                    label: 'Самец',
                                    icon: Icons.male_rounded,
                                    accent: Color(0xFF3D87D8),
                                  ),
                                  PetFormCardPickerOption<String>(
                                    value: 'FEMALE',
                                    label: 'Самка',
                                    icon: Icons.female_rounded,
                                    accent: Color(0xFFE86A9A),
                                  ),
                                ],
                                onChanged: (value) =>
                                    setState(() => _sex = value),
                              ),
                              if (_sex != 'UNKNOWN')
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton(
                                    onPressed: () =>
                                        setState(() => _sex = 'UNKNOWN'),
                                    child: const Text('Не указывать'),
                                  ),
                                ),
                              const SizedBox(height: PawlySpacing.md),
                              PetFormModeToggle<_CatalogPickMode>(
                                title: 'Вид',
                                value: _speciesMode,
                                catalogValue: _CatalogPickMode.catalog,
                                customValue: _CatalogPickMode.custom,
                                onChanged: _setSpeciesMode,
                              ),
                              const SizedBox(height: PawlySpacing.sm),
                              if (_speciesMode == _CatalogPickMode.catalog)
                                PetFormSpeciesGridPicker(
                                  species: data.catalog.species,
                                  selectedId: _speciesId,
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setState(() {
                                      _speciesMode = _CatalogPickMode.catalog;
                                      _speciesId = value;
                                      _customSpeciesCtrl.clear();
                                      _breedId = null;
                                      _breedMode = _CatalogPickMode.catalog;
                                      _breedSearchCtrl.clear();
                                      _breedSearchQuery = '';
                                    });
                                  },
                                )
                              else
                                PawlyTextField(
                                  controller: _customSpeciesCtrl,
                                  label: 'Свой вид',
                                  validator: (value) {
                                    if (_speciesMode ==
                                            _CatalogPickMode.custom &&
                                        (value == null ||
                                            value.trim().isEmpty)) {
                                      return 'Введите свой вид';
                                    }
                                    return null;
                                  },
                                ),
                              const SizedBox(height: PawlySpacing.md),
                              PetFormDateButton(
                                label: 'Дата рождения',
                                value: _birthDate == null
                                    ? 'Не заполнено'
                                    : _formatDate(_birthDate!),
                                onPressed: () => _pickDate(
                                  initial: _birthDate,
                                  lastDate: DateTime.now(),
                                  onPicked: (value) =>
                                      setState(() => _birthDate = value),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_step == _PetEditStep.breed)
                        PetFormSectionCard(
                          title: 'Порода',
                          subtitle: _speciesMode == _CatalogPickMode.custom
                              ? 'Для своего вида укажите породу вручную.'
                              : 'Поиск по каталогу или свой вариант.',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              if (_speciesMode == _CatalogPickMode.catalog) ...[
                                PetFormModeToggle<_CatalogPickMode>(
                                  title: 'Порода',
                                  value: _breedMode,
                                  catalogValue: _CatalogPickMode.catalog,
                                  customValue: _CatalogPickMode.custom,
                                  onChanged: (value) =>
                                      setState(() => _breedMode = value),
                                ),
                                const SizedBox(height: PawlySpacing.sm),
                              ],
                              if (_speciesMode == _CatalogPickMode.catalog &&
                                  _breedMode == _CatalogPickMode.catalog)
                                PetFormBreedSearchPicker(
                                  controller: _breedSearchCtrl,
                                  query: _breedSearchQuery,
                                  breeds: filteredBreeds,
                                  totalCount: breedsForSpecies.length,
                                  selectedId: _breedId,
                                  onQueryChanged: (value) {
                                    setState(() {
                                      _breedSearchQuery = value;
                                    });
                                  },
                                  onChanged: (value) =>
                                      setState(() => _breedId = value),
                                )
                              else
                                PawlyTextField(
                                  controller: _customBreedCtrl,
                                  label: 'Своя порода',
                                  onChanged: (value) =>
                                      _customBreedName = value,
                                  validator: (value) {
                                    if (_breedMode == _CatalogPickMode.custom &&
                                        (value == null ||
                                            value.trim().isEmpty)) {
                                      return 'Введите свою породу';
                                    }
                                    return null;
                                  },
                                ),
                            ],
                          ),
                        ),
                      if (_step == _PetEditStep.appearance)
                        PetFormSectionCard(
                          title: 'Внешность',
                          subtitle: 'Окрас и основные цвета питомца.',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              PetFormModeToggle<_CatalogPickMode>(
                                title: 'Окрас',
                                value: _patternMode,
                                catalogValue: _CatalogPickMode.catalog,
                                customValue: _CatalogPickMode.custom,
                                onChanged: (value) =>
                                    setState(() => _patternMode = value),
                              ),
                              const SizedBox(height: PawlySpacing.sm),
                              if (_patternMode == _CatalogPickMode.catalog)
                                DropdownButtonFormField<String>(
                                  initialValue: _patternId,
                                  decoration: const InputDecoration(
                                    labelText: 'Выберите окрас',
                                  ),
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
                                )
                              else
                                PawlyTextField(
                                  controller: _customPatternCtrl,
                                  label: 'Свой окрас',
                                  onChanged: (value) =>
                                      _customPatternName = value,
                                  validator: (value) {
                                    if (_patternMode ==
                                            _CatalogPickMode.custom &&
                                        (value == null ||
                                            value.trim().isEmpty)) {
                                      return 'Введите свой окрас';
                                    }
                                    return null;
                                  },
                                ),
                              const SizedBox(height: PawlySpacing.md),
                              Text(
                                'Цвета · $selectedColorCount/$_petEditMaxColors',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: PawlySpacing.xs),
                              Wrap(
                                spacing: PawlySpacing.xs,
                                runSpacing: PawlySpacing.xs,
                                children: data.catalog.colors.map((entry) {
                                  final selected = _colorIds.contains(entry.id);
                                  return PetFormCatalogColorChip(
                                    label: entry.name,
                                    hex: entry.hex,
                                    selected: selected,
                                    onTap: () => _toggleColor(entry.id),
                                  );
                                }).toList(growable: false),
                              ),
                              const SizedBox(height: PawlySpacing.sm),
                              Wrap(
                                spacing: PawlySpacing.xs,
                                runSpacing: PawlySpacing.xs,
                                children: <Widget>[
                                  ..._customColors.asMap().entries.map(
                                        (entry) => PetFormCustomColorChip(
                                          color: entry.value,
                                          onDeleted: () => setState(
                                            () => _customColors
                                                .removeAt(entry.key),
                                          ),
                                        ),
                                      ),
                                  ActionChip(
                                    label: const Text('Свой цвет'),
                                    avatar:
                                        const Icon(Icons.add_rounded, size: 18),
                                    onPressed:
                                        selectedColorCount >= _petEditMaxColors
                                            ? null
                                            : _openColorPicker,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      if (_step == _PetEditStep.optional)
                        PetFormSectionCard(
                          title: 'Дополнительно',
                          subtitle: 'Стерилизация, выгул и микрочип.',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              _ThreeOptionSegment(
                                title: 'Стерилизация',
                                value: _isNeutered,
                                options: const <_SegmentOption>[
                                  _SegmentOption(
                                      value: 'UNKNOWN', label: 'Неизв.'),
                                  _SegmentOption(value: 'YES', label: 'Да'),
                                  _SegmentOption(value: 'NO', label: 'Нет'),
                                ],
                                onChanged: (value) =>
                                    setState(() => _isNeutered = value),
                              ),
                              const SizedBox(height: PawlySpacing.md),
                              PetFormTwoOptionCardPicker<bool>(
                                title: 'Уличный свободный выгул',
                                value: _isOutdoor,
                                options: const <PetFormCardPickerOption<bool>>[
                                  PetFormCardPickerOption<bool>(
                                    value: true,
                                    label: 'Да',
                                    icon: Icons.park_rounded,
                                  ),
                                  PetFormCardPickerOption<bool>(
                                    value: false,
                                    label: 'Нет',
                                    icon: Icons.home_rounded,
                                  ),
                                ],
                                onChanged: (value) =>
                                    setState(() => _isOutdoor = value),
                              ),
                              const SizedBox(height: PawlySpacing.md),
                              PawlyTextField(
                                controller: _microchipCtrl,
                                label: 'ID микрочипа',
                              ),
                              const SizedBox(height: PawlySpacing.sm),
                              PetFormDateButton(
                                label: 'Дата установки чипа',
                                value: _microchipInstalledAt == null
                                    ? 'Не заполнено'
                                    : _formatDate(_microchipInstalledAt!),
                                onPressed: () => _pickDate(
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
                      const SizedBox(height: PawlySpacing.md),
                      _EditBottomActions(
                        isSubmitting: _isSubmitting,
                        onPrevious: _step.index == 0
                            ? null
                            : () {
                                setState(() {
                                  _step = _PetEditStep.values[_step.index - 1];
                                });
                              },
                        onNext: _step.index == _PetEditStep.values.length - 1
                            ? null
                            : () {
                                setState(() {
                                  _step = _PetEditStep.values[_step.index + 1];
                                });
                              },
                        onSubmit: () => _submit(data.pet),
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
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const _PetEditNoAccessView(),
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
    _customSpeciesCtrl.text = pet.customSpeciesName ?? '';
    _speciesMode = _speciesId == null || _speciesId!.isEmpty
        ? _CatalogPickMode.custom
        : _CatalogPickMode.catalog;

    _breedMode =
        _speciesMode == _CatalogPickMode.custom || pet.breed.source == 'CUSTOM'
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
    _customColors = pet.colors
        .where(
          (entry) => entry.hexOverride != null && entry.hexOverride!.isNotEmpty,
        )
        .map(
          (entry) => PetFormCustomColor(
            hex: entry.hexOverride!,
            name: entry.note ?? '',
          ),
        )
        .toList(growable: false);

    _isNeutered = pet.isNeutered;
    _isOutdoor = pet.isOutdoor;
    _microchipCtrl.text = pet.microchipId ?? '';
    _microchipInstalledAt = pet.microchipInstalledAt;
  }

  Future<void> _submit(Pet pet) async {
    if (!_validateAll()) {
      return;
    }

    final payload = UpdatePetPayload(
      rowVersion: pet.rowVersion,
      payload: CreatePetPayload(
        name: _nameCtrl.text.trim(),
        speciesId: _speciesMode == _CatalogPickMode.catalog ? _speciesId : null,
        customSpeciesName: _speciesMode == _CatalogPickMode.custom
            ? _customSpeciesCtrl.text.trim()
            : null,
        sex: _sex,
        birthDate: _birthDate,
        breedId: _speciesMode == _CatalogPickMode.catalog &&
                _breedMode == _CatalogPickMode.catalog
            ? _breedId
            : null,
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

    for (final color in _customColors) {
      final hex = _normalizeHex(color.hex);
      if (hex != null) {
        colors.add(
          PetColor(
            hexOverride: hex,
            note: color.name.trim().isEmpty ? null : color.name.trim(),
            sortOrder: sortOrder++,
          ),
        );
      }
    }

    return colors;
  }

  void _setSpeciesMode(_CatalogPickMode value) {
    setState(() {
      _speciesMode = value;
      if (value == _CatalogPickMode.catalog) {
        _customSpeciesCtrl.clear();
      } else {
        _speciesId = null;
        _breedId = null;
        _breedMode = _CatalogPickMode.custom;
        _breedSearchCtrl.clear();
        _breedSearchQuery = '';
      }
    });
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
    final picked = await showDialog<PetFormCustomColor>(
      context: context,
      builder: (context) => const PetFormCustomColorPickerDialog(),
    );

    if (picked == null || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        final normalized = _normalizeHex(picked.hex);
        if (normalized == null) return;
        if (_customColors.any((entry) => entry.hex == normalized)) return;
        if (_colorIds.length + _customColors.length >= _petEditMaxColors) {
          return;
        }
        _customColors = <PetFormCustomColor>[
          ..._customColors,
          PetFormCustomColor(hex: normalized, name: picked.name),
        ];
      });
    });
  }

  void _toggleColor(String id) {
    var limitReached = false;
    setState(() {
      if (_colorIds.contains(id)) {
        _colorIds.remove(id);
        return;
      }
      if (_colorIds.length + _customColors.length >= _petEditMaxColors) {
        limitReached = true;
        return;
      }
      _colorIds.add(id);
    });
    if (limitReached) {
      _showMessage('Можно выбрать до $_petEditMaxColors цветов.');
    }
  }

  bool _validateAll() {
    if (!_formKey.currentState!.validate()) {
      return false;
    }
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _step = _PetEditStep.basic);
      _showMessage('Введите кличку.');
      return false;
    }
    if (_speciesMode == _CatalogPickMode.catalog &&
        (_speciesId == null || _speciesId!.isEmpty)) {
      setState(() => _step = _PetEditStep.basic);
      _showMessage('Выберите вид.');
      return false;
    }
    if (_speciesMode == _CatalogPickMode.custom &&
        _customSpeciesCtrl.text.trim().isEmpty) {
      setState(() => _step = _PetEditStep.basic);
      _showMessage('Введите свой вид.');
      return false;
    }
    if (_breedMode == _CatalogPickMode.catalog &&
        (_breedId == null || _breedId!.isEmpty)) {
      setState(() => _step = _PetEditStep.breed);
      _showMessage('Выберите породу.');
      return false;
    }
    if (_breedMode == _CatalogPickMode.custom &&
        _customBreedCtrl.text.trim().isEmpty) {
      setState(() => _step = _PetEditStep.breed);
      _showMessage('Введите свою породу.');
      return false;
    }
    if (_patternMode == _CatalogPickMode.catalog &&
        (_patternId == null || _patternId!.isEmpty)) {
      setState(() => _step = _PetEditStep.appearance);
      _showMessage('Выберите окрас.');
      return false;
    }
    if (_patternMode == _CatalogPickMode.custom &&
        _customPatternCtrl.text.trim().isEmpty) {
      setState(() => _step = _PetEditStep.appearance);
      _showMessage('Введите свой окрас.');
      return false;
    }
    if (_colorIds.isEmpty && _customColors.isEmpty) {
      setState(() => _step = _PetEditStep.appearance);
      _showMessage('Выберите минимум один цвет.');
      return false;
    }
    return true;
  }

  String? _normalizeHex(String input) {
    final value = input.trim().toUpperCase();
    final prepared = value.startsWith('#') ? value : '#$value';
    if (prepared.length != 7) {
      return null;
    }
    final raw = prepared.substring(1);
    if (int.tryParse(raw, radix: 16) == null) return null;
    return prepared;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SegmentOption {
  const _SegmentOption({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;
}

class _ThreeOptionSegment extends StatelessWidget {
  const _ThreeOptionSegment({
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
  }) : assert(options.length == 3);

  final String title;
  final String value;
  final List<_SegmentOption> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: PawlySpacing.xs),
        Container(
          padding: const EdgeInsets.all(PawlySpacing.xxs),
          decoration: BoxDecoration(
            color: colorScheme.onSurface.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(PawlyRadius.lg),
          ),
          child: Row(
            children: options.map((entry) {
              return PetFormSegmentButton(
                label: entry.label,
                selected: value == entry.value,
                onTap: () => onChanged(entry.value),
              );
            }).toList(growable: false),
          ),
        ),
      ],
    );
  }
}

class _EditBottomActions extends StatelessWidget {
  const _EditBottomActions({
    required this.isSubmitting,
    required this.onSubmit,
    this.onPrevious,
    this.onNext,
  });

  final bool isSubmitting;
  final VoidCallback onSubmit;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final showNavigation = onPrevious != null || onNext != null;

    return Column(
      children: <Widget>[
        if (showNavigation) ...<Widget>[
          Row(
            children: <Widget>[
              if (onPrevious != null)
                Expanded(
                  child: PawlyButton(
                    label: 'Назад',
                    onPressed: onPrevious,
                    variant: PawlyButtonVariant.secondary,
                  ),
                ),
              if (onPrevious != null && onNext != null)
                const SizedBox(width: PawlySpacing.sm),
              if (onNext != null)
                Expanded(
                  child: PawlyButton(
                    label: 'Далее',
                    onPressed: onNext,
                    variant: PawlyButtonVariant.secondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: PawlySpacing.sm),
        ],
        PawlyButton(
          label: isSubmitting ? 'Сохраняем...' : 'Сохранить',
          onPressed: isSubmitting ? null : onSubmit,
        ),
      ],
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

class _PetEditNoAccessView extends StatelessWidget {
  const _PetEditNoAccessView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PawlySpacing.md),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(PawlyRadius.xl),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.72),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(PawlySpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Нет доступа',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: PawlySpacing.xs),
                Text(
                  'У вас нет права редактировать этого питомца.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _editStepLabel(_PetEditStep step) {
  switch (step) {
    case _PetEditStep.basic:
      return 'Основное';
    case _PetEditStep.breed:
      return 'Порода';
    case _PetEditStep.appearance:
      return 'Внешность';
    case _PetEditStep.optional:
      return 'Еще';
  }
}

String _formatDate(DateTime value) {
  final local = value.toLocal();
  final yyyy = local.year.toString().padLeft(4, '0');
  final mm = local.month.toString().padLeft(2, '0');
  final dd = local.day.toString().padLeft(2, '0');
  return '$yyyy-$mm-$dd';
}

List<CatalogBreedOption> _defaultBreedResults(
  List<CatalogBreedOption> breeds, {
  required String? selectedId,
}) {
  final results = breeds.take(12).toList(growable: true);
  if (selectedId == null || selectedId.isEmpty) {
    return results;
  }
  final selectedAlreadyVisible = results.any((entry) => entry.id == selectedId);
  if (selectedAlreadyVisible) {
    return results;
  }
  for (final breed in breeds) {
    if (breed.id != selectedId) continue;
    results.insert(0, breed);
    break;
  }
  return results;
}
