import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../design_system/design_system.dart';
import '../../../catalog/data/catalog_cache_models.dart';
import '../../../catalog/presentation/providers/pet_dictionaries_providers.dart';
import '../../../pets/presentation/providers/active_pet_controller.dart';
import '../../../pets/presentation/providers/pets_controller.dart';
import '../../../pets/presentation/widgets/pet_form_widgets.dart';
import '../providers/pet_create_controller.dart';

class PetCreateFlowPage extends ConsumerStatefulWidget {
  const PetCreateFlowPage({super.key});

  @override
  ConsumerState<PetCreateFlowPage> createState() => _PetCreateFlowPageState();
}

class _PetCreateFlowPageState extends ConsumerState<PetCreateFlowPage> {
  final _nameCtrl = TextEditingController();
  final _customSpeciesCtrl = TextEditingController();
  final _customBreedCtrl = TextEditingController();
  final _customPatternCtrl = TextEditingController();
  final _microchipCtrl = TextEditingController();
  final _breedSearchCtrl = TextEditingController();
  String _breedSearchQuery = '';

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
    final catalogAsync = ref.watch(petDictionariesSyncProvider);
    final state = ref.watch(petCreateControllerProvider);
    final c = ref.read(petCreateControllerProvider.notifier);

    ref.listen<PetCreateState>(petCreateControllerProvider, (_, next) {
      if (next.error != null && next.error!.isNotEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next.error!)));
      }
    });

    _nameCtrl.value = _nameCtrl.value.copyWith(text: state.name);
    _customSpeciesCtrl.value =
        _customSpeciesCtrl.value.copyWith(text: state.customSpeciesName);
    _customBreedCtrl.value =
        _customBreedCtrl.value.copyWith(text: state.customBreedName);
    _customPatternCtrl.value =
        _customPatternCtrl.value.copyWith(text: state.customPatternName);
    _microchipCtrl.value =
        _microchipCtrl.value.copyWith(text: state.microchipId);

    return PawlyScreenScaffold(
      title: 'Создание',
      leading: IconButton(
        onPressed: () {
          if (state.step == PetCreateStep.basic) {
            context.pop();
          } else {
            c.previousStep();
          }
        },
        icon: const Icon(Icons.chevron_left_rounded, size: 30),
      ),
      body: catalogAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: PawlyButton(
            label: 'Повторить загрузку каталога',
            onPressed: () => ref.invalidate(petDictionariesSyncProvider),
            fullWidth: false,
          ),
        ),
        data: (catalog) {
          final species = catalog.species;
          final breedsForSpecies = state.speciesId == null
              ? catalog.breeds
              : catalog.breeds
                  .where((e) => e.speciesId == state.speciesId)
                  .toList(growable: false);
          final breedSearchQuery = _breedSearchQuery.trim().toLowerCase();
          final filteredBreeds = breedSearchQuery.isEmpty
              ? breedsForSpecies.take(12).toList(growable: false)
              : breedsForSpecies
                  .where(
                    (entry) =>
                        entry.name.toLowerCase().contains(breedSearchQuery),
                  )
                  .take(24)
                  .toList(growable: false);
          final patterns = catalog.patterns;
          final colors = catalog.colors;
          final speciesName = state.speciesMode == CatalogPickMode.catalog
              ? _catalogOptionName(
                  species,
                  state.speciesId,
                  fallback: 'Не выбран',
                )
              : _fallbackText(state.customSpeciesName);
          final breedName = state.breedMode == CatalogPickMode.catalog
              ? _catalogBreedName(
                  catalog.breeds,
                  state.breedId,
                  fallback: 'Не выбрана',
                )
              : _fallbackText(state.customBreedName);
          final patternName = state.patternMode == CatalogPickMode.catalog
              ? _catalogPatternName(
                  patterns,
                  state.patternId,
                  fallback: 'Не выбран',
                )
              : _fallbackText(state.customPatternName);
          final selectedCatalogColors = colors
              .where((e) => state.colorIds.contains(e.id))
              .toList(growable: false);
          final selectedColorCount =
              state.colorIds.length + state.customColorsHex.length;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                PawlySpacing.md,
                PawlySpacing.sm,
                PawlySpacing.md,
                PawlySpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  PetFormStepTabs<PetCreateStep>(
                    steps: PetCreateStep.values,
                    value: state.step,
                    labelBuilder: _createStepLabel,
                    onChanged: (step) => c.goToStep(catalog, step),
                  ),
                  const SizedBox(height: PawlySpacing.md),
                  if (state.step == PetCreateStep.basic) ...[
                    PetFormSectionCard(
                      title: 'Основное',
                      subtitle: 'Кличка, пол, вид и дата рождения.',
                      child: Column(
                        children: <Widget>[
                          PawlyTextField(
                            controller: _nameCtrl,
                            label: 'Кличка',
                            onChanged: c.setName,
                          ),
                          const SizedBox(height: PawlySpacing.md),
                          PetFormTwoOptionCardPicker<String>(
                            title: 'Пол',
                            value: state.sex,
                            options: const <PetFormCardPickerOption<String>>[
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
                            onChanged: c.setSex,
                          ),
                          const SizedBox(height: PawlySpacing.md),
                          PetFormModeToggle<CatalogPickMode>(
                            title: 'Вид',
                            value: state.speciesMode,
                            catalogValue: CatalogPickMode.catalog,
                            customValue: CatalogPickMode.custom,
                            onChanged: c.setSpeciesMode,
                          ),
                          const SizedBox(height: PawlySpacing.sm),
                          if (state.speciesMode == CatalogPickMode.catalog)
                            PetFormSpeciesGridPicker(
                              species: species,
                              selectedId: state.speciesId,
                              onChanged: c.setSpeciesId,
                            ),
                          if (state.speciesMode == CatalogPickMode.custom)
                            PawlyTextField(
                              controller: _customSpeciesCtrl,
                              label: 'Свой вид',
                              onChanged: c.setCustomSpeciesName,
                            ),
                          const SizedBox(height: PawlySpacing.md),
                          PetFormDateButton(
                            label: 'Дата рождения',
                            value: _dateLabel(state.birthDate),
                            onPressed: () => _pickDate(
                              c.setBirthDate,
                              initial: state.birthDate,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: PawlySpacing.md),
                    PawlyButton(
                      label: 'Далее',
                      onPressed: () => c.nextStep(catalog),
                    ),
                  ],
                  if (state.step == PetCreateStep.breed) ...[
                    PetFormSectionCard(
                      title: 'Порода',
                      subtitle: state.speciesMode == CatalogPickMode.custom
                          ? 'Для своего вида укажите породу вручную.'
                          : 'Выберите породу из каталога или укажите свою.',
                      child: Column(
                        children: <Widget>[
                          if (state.speciesMode == CatalogPickMode.catalog) ...[
                            PetFormModeToggle<CatalogPickMode>(
                              title: 'Порода',
                              value: state.breedMode,
                              catalogValue: CatalogPickMode.catalog,
                              customValue: CatalogPickMode.custom,
                              onChanged: c.setBreedMode,
                            ),
                            const SizedBox(height: PawlySpacing.sm),
                          ],
                          if (state.speciesMode == CatalogPickMode.catalog &&
                              state.breedMode == CatalogPickMode.catalog)
                            PetFormBreedSearchPicker(
                              controller: _breedSearchCtrl,
                              query: _breedSearchQuery,
                              breeds: filteredBreeds,
                              totalCount: breedsForSpecies.length,
                              selectedId: state.breedId,
                              onQueryChanged: (value) {
                                setState(() {
                                  _breedSearchQuery = value;
                                });
                              },
                              onChanged: c.setBreedId,
                            ),
                          if (state.speciesMode == CatalogPickMode.custom ||
                              state.breedMode == CatalogPickMode.custom)
                            PawlyTextField(
                              controller: _customBreedCtrl,
                              label: 'Своя порода',
                              onChanged: c.setCustomBreedName,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: PawlySpacing.md),
                    PawlyButton(
                      label: 'Далее',
                      onPressed: () => c.nextStep(catalog),
                    ),
                  ],
                  if (state.step == PetCreateStep.appearance) ...[
                    PetFormSectionCard(
                      title: 'Внешность',
                      subtitle: 'Окрас шерсти и основные цвета.',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          PetFormModeToggle<CatalogPickMode>(
                            title: 'Окрас',
                            value: state.patternMode,
                            catalogValue: CatalogPickMode.catalog,
                            customValue: CatalogPickMode.custom,
                            onChanged: c.setPatternMode,
                          ),
                          const SizedBox(height: PawlySpacing.sm),
                          if (state.patternMode == CatalogPickMode.catalog)
                            DropdownButtonFormField<String>(
                              initialValue: state.patternId,
                              decoration: const InputDecoration(
                                  labelText: 'Выберите окрас'),
                              items: patterns
                                  .map((e) => DropdownMenuItem<String>(
                                      value: e.id, child: Text(e.name)))
                                  .toList(growable: false),
                              onChanged: c.setPatternId,
                            ),
                          if (state.patternMode == CatalogPickMode.custom)
                            PawlyTextField(
                              controller: _customPatternCtrl,
                              label: 'Свой окрас',
                              onChanged: c.setCustomPatternName,
                            ),
                          const SizedBox(height: PawlySpacing.md),
                          Text(
                            'Цвета · $selectedColorCount/$petCreateMaxColors',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: PawlySpacing.xs),
                          Wrap(
                            spacing: PawlySpacing.xs,
                            runSpacing: PawlySpacing.xs,
                            children: colors.map((e) {
                              final selected = state.colorIds.contains(e.id);
                              return PetFormCatalogColorChip(
                                label: e.name,
                                hex: e.hex,
                                selected: selected,
                                onTap: () => c.toggleColor(e.id),
                              );
                            }).toList(growable: false),
                          ),
                          const SizedBox(height: PawlySpacing.sm),
                          Wrap(
                            spacing: PawlySpacing.xs,
                            runSpacing: PawlySpacing.xs,
                            children: <Widget>[
                              ...state.customColorsHex
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                return PetFormCustomColorChip(
                                  color: PetFormCustomColor(
                                    hex: entry.value.hex,
                                    name: entry.value.name,
                                  ),
                                  onDeleted: () =>
                                      c.removeCustomColorAt(entry.key),
                                );
                              }),
                              _AddColorButton(
                                enabled:
                                    selectedColorCount < petCreateMaxColors,
                                onPressed: () => _openColorPicker(
                                  (color) => c.addCustomColor(
                                    hex: color.hex,
                                    name: color.name,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: PawlySpacing.md),
                    PawlyButton(
                      label: 'Далее',
                      onPressed: () => c.nextStep(catalog),
                    ),
                  ],
                  if (state.step == PetCreateStep.optional) ...[
                    PetFormSectionCard(
                      title: 'Дополнительно',
                      subtitle: 'Можно заполнить сейчас или пропустить.',
                      child: Column(
                        children: <Widget>[
                          DropdownButtonFormField<String>(
                            initialValue: state.isNeutered,
                            decoration: const InputDecoration(
                                labelText: 'Стерилизация'),
                            items: const <DropdownMenuItem<String>>[
                              DropdownMenuItem(
                                  value: 'UNKNOWN', child: Text('Неизвестно')),
                              DropdownMenuItem(value: 'YES', child: Text('Да')),
                              DropdownMenuItem(value: 'NO', child: Text('Нет')),
                            ],
                            onChanged: (v) => c.setIsNeutered(v ?? 'UNKNOWN'),
                          ),
                          const SizedBox(height: PawlySpacing.sm),
                          PetFormTwoOptionCardPicker<bool>(
                            title: 'Уличный/свободный выгул',
                            value: state.isOutdoor,
                            options: const <PetFormCardPickerOption<bool>>[
                              PetFormCardPickerOption<bool>(
                                value: false,
                                label: 'Домашний',
                                icon: Icons.home_rounded,
                              ),
                              PetFormCardPickerOption<bool>(
                                value: true,
                                label: 'Свободный выгул',
                                icon: Icons.park_rounded,
                                accent: Color(0xFF57A3D9),
                              ),
                            ],
                            onChanged: c.setIsOutdoor,
                          ),
                          const SizedBox(height: PawlySpacing.sm),
                          PawlyTextField(
                            controller: _microchipCtrl,
                            label: 'ID микрочипа (опционально)',
                            onChanged: c.setMicrochipId,
                          ),
                          const SizedBox(height: PawlySpacing.sm),
                          PetFormDateButton(
                            label: 'Дата установки чипа',
                            value: _dateLabel(state.microchipInstalledAt),
                            onPressed: () => _pickDate(
                              c.setMicrochipInstalledAt,
                              initial: state.microchipInstalledAt,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: PawlySpacing.md),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: PawlyButton(
                            label: 'Пропустить',
                            variant: PawlyButtonVariant.ghost,
                            onPressed: () => c.nextStep(catalog),
                          ),
                        ),
                        const SizedBox(width: PawlySpacing.sm),
                        Expanded(
                          child: PawlyButton(
                            label: 'Далее',
                            onPressed: () => c.nextStep(catalog),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (state.step == PetCreateStep.review) ...[
                    _ReviewIntroCard(
                      title: 'Проверьте данные',
                      subtitle:
                          'После создания питомца можно будет дополнить карточку.',
                    ),
                    const SizedBox(height: PawlySpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: _ReviewCard(
                        title: Text(
                          'Основное',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        child: Column(
                          children: <Widget>[
                            _ReviewRow(
                              label: 'Кличка',
                              value: state.name.trim(),
                            ),
                            _ReviewRow(
                              label: 'Пол',
                              value: _sexLabel(state.sex),
                            ),
                            _ReviewRow(label: 'Вид', value: speciesName),
                            _ReviewRow(label: 'Порода', value: breedName),
                            _ReviewRow(
                              label: 'Окрас',
                              value: patternName,
                              isLast: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: PawlySpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: _ReviewCard(
                        title: Text(
                          'Внешность',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Цвета',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            const SizedBox(height: PawlySpacing.sm),
                            if (selectedCatalogColors.isNotEmpty ||
                                state.customColorsHex.isNotEmpty)
                              Wrap(
                                spacing: PawlySpacing.xs,
                                runSpacing: PawlySpacing.xs,
                                children: <Widget>[
                                  ...selectedCatalogColors.map(
                                    (color) => PetFormCatalogColorChip(
                                      label: color.name,
                                      hex: color.hex,
                                      selected: true,
                                    ),
                                  ),
                                  ...state.customColorsHex.map(
                                    (color) => PetFormCustomColorChip(
                                      color: PetFormCustomColor(
                                        hex: color.hex,
                                        name: color.name,
                                      ),
                                      onDeleted: null,
                                    ),
                                  ),
                                ],
                              )
                            else
                              Text(
                                'Не выбраны',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: PawlySpacing.sm),
                    SizedBox(
                      width: double.infinity,
                      child: _ReviewCard(
                        title: Text(
                          'Дополнительно',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        child: Column(
                          children: <Widget>[
                            _ReviewRow(
                              label: 'Дата рождения',
                              value: _dateLabel(state.birthDate),
                            ),
                            _ReviewRow(
                              label: 'Стерилизация',
                              value: _yesNoUnknownLabel(state.isNeutered),
                            ),
                            _ReviewRow(
                              label: 'Свободный выгул',
                              value: state.isOutdoor ? 'Да' : 'Нет',
                            ),
                            _ReviewRow(
                              label: 'Микрочип',
                              value: _fallbackText(state.microchipId),
                            ),
                            _ReviewRow(
                              label: 'Дата установки чипа',
                              value: _dateLabel(state.microchipInstalledAt),
                              isLast: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: PawlySpacing.lg),
                    PawlyButton(
                      label:
                          state.isSubmitting ? 'Создаем...' : 'Создать питомца',
                      onPressed: state.isSubmitting
                          ? null
                          : () async {
                              final createdPet = await c.submit(catalog);
                              if (!context.mounted) return;
                              if (createdPet == null) return;
                              await ref
                                  .read(activePetControllerProvider.notifier)
                                  .selectPet(createdPet.id);
                              await ref
                                  .read(petsControllerProvider.notifier)
                                  .refreshAfterPetMutation();
                              if (!context.mounted) return;
                              context.go(AppRoutes.pets);
                            },
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickDate(
    ValueChanged<DateTime?> onPicked, {
    DateTime? initial,
  }) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(1990),
      lastDate: now,
      initialDate: initial ?? DateTime(now.year - 1),
    );
    onPicked(date);
  }

  Future<void> _openColorPicker(
    ValueChanged<CustomPetColorDraft> onPicked,
  ) async {
    final picked = await showDialog<PetFormCustomColor>(
      context: context,
      builder: (context) => const PetFormCustomColorPickerDialog(),
    );

    if (picked == null || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      onPicked(
        CustomPetColorDraft(
          hex: picked.hex,
          name: picked.name,
        ),
      );
    });
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.title,
    required this.child,
  });

  final Widget title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(PawlySpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(PawlyRadius.xl),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          title,
          const SizedBox(height: PawlySpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _ReviewIntroCard extends StatelessWidget {
  const _ReviewIntroCard({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(PawlySpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(PawlyRadius.xl),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: PawlySpacing.xxs),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddColorButton extends StatelessWidget {
  const _AddColorButton({
    required this.enabled,
    required this.onPressed,
  });

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: const Text('Свой цвет'),
      avatar: const Icon(Icons.add_rounded, size: 18),
      onPressed: enabled ? onPressed : null,
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : PawlySpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(width: PawlySpacing.md),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}

String _catalogOptionName(
  List<CatalogOption> options,
  String? id, {
  required String fallback,
}) {
  if (id == null || id.isEmpty) return fallback;
  for (final option in options) {
    if (option.id != id) continue;
    final name = option.name.trim();
    if (name.isNotEmpty) return name;
  }
  return fallback;
}

String _createStepLabel(PetCreateStep step) {
  switch (step) {
    case PetCreateStep.basic:
      return 'Основное';
    case PetCreateStep.breed:
      return 'Порода';
    case PetCreateStep.appearance:
      return 'Внешность';
    case PetCreateStep.optional:
      return 'Еще';
    case PetCreateStep.review:
      return 'Проверка';
  }
}

String _catalogBreedName(
  List<CatalogBreedOption> options,
  String? id, {
  required String fallback,
}) {
  if (id == null || id.isEmpty) return fallback;
  for (final option in options) {
    if (option.id != id) continue;
    final name = option.name.trim();
    if (name.isNotEmpty) return name;
  }
  return fallback;
}

String _catalogPatternName(
  List<CatalogPatternOption> options,
  String? id, {
  required String fallback,
}) {
  if (id == null || id.isEmpty) return fallback;
  for (final option in options) {
    if (option.id != id) continue;
    final name = option.name.trim();
    if (name.isNotEmpty) return name;
  }
  return fallback;
}

String _fallbackText(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? 'Не заполнено' : trimmed;
}

String _sexLabel(String value) {
  switch (value) {
    case 'MALE':
      return 'Самец';
    case 'FEMALE':
      return 'Самка';
    default:
      return 'Не указан';
  }
}

String _yesNoUnknownLabel(String value) {
  switch (value) {
    case 'YES':
      return 'Да';
    case 'NO':
      return 'Нет';
    default:
      return 'Не указано';
  }
}

String _dateLabel(DateTime? value) {
  if (value == null) return 'Не заполнено';
  return value.toLocal().toString().split(' ').first;
}
