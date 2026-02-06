import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../design_system/design_system.dart';
import '../../../catalog/presentation/providers/catalog_providers.dart';
import '../../../pets/presentation/providers/active_pet_controller.dart';
import '../../../pets/presentation/providers/pets_controller.dart';
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

  @override
  void dispose() {
    _nameCtrl.dispose();
    _customSpeciesCtrl.dispose();
    _customBreedCtrl.dispose();
    _customPatternCtrl.dispose();
    _microchipCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(catalogSyncProvider);
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Создание питомца'),
        leading: IconButton(
          onPressed: () {
            if (state.step == PetCreateStep.basic) {
              context.pop();
            } else {
              c.previousStep();
            }
          },
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: catalogAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: PawlyButton(
            label: 'Повторить загрузку каталога',
            onPressed: () => ref.invalidate(catalogSyncProvider),
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
          final patterns = catalog.patterns;
          final colors = catalog.colors;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(PawlySpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _StepPills(step: state.step),
                  const SizedBox(height: PawlySpacing.lg),
                  if (state.step == PetCreateStep.basic) ...[
                    PawlyTextField(
                      controller: _nameCtrl,
                      label: 'Имя питомца',
                      onChanged: c.setName,
                    ),
                    const SizedBox(height: PawlySpacing.sm),
                    DropdownButtonFormField<String>(
                      value: state.sex,
                      decoration: const InputDecoration(labelText: 'Пол'),
                      items: const <DropdownMenuItem<String>>[
                        DropdownMenuItem(
                            value: 'UNKNOWN', child: Text('Не указан')),
                        DropdownMenuItem(value: 'MALE', child: Text('Самец')),
                        DropdownMenuItem(value: 'FEMALE', child: Text('Самка')),
                      ],
                      onChanged: (v) => c.setSex(v ?? 'UNKNOWN'),
                    ),
                    const SizedBox(height: PawlySpacing.sm),
                    _ModeChips(
                      title: 'Вид',
                      mode: state.speciesMode,
                      onChanged: c.setSpeciesMode,
                    ),
                    const SizedBox(height: PawlySpacing.sm),
                    if (state.speciesMode == CatalogPickMode.catalog)
                      DropdownButtonFormField<String>(
                        value: state.speciesId,
                        decoration:
                            const InputDecoration(labelText: 'Выберите вид'),
                        items: species
                            .map((e) => DropdownMenuItem<String>(
                                value: e.id, child: Text(e.name)))
                            .toList(growable: false),
                        onChanged: c.setSpeciesId,
                      ),
                    if (state.speciesMode == CatalogPickMode.custom)
                      PawlyTextField(
                        controller: _customSpeciesCtrl,
                        label: 'Свой вид',
                        onChanged: c.setCustomSpeciesName,
                      ),
                    const SizedBox(height: PawlySpacing.lg),
                    PawlyButton(label: 'Далее', onPressed: c.nextStep),
                  ],
                  if (state.step == PetCreateStep.breed) ...[
                    _ModeChips(
                      title: 'Порода',
                      mode: state.breedMode,
                      onChanged: c.setBreedMode,
                    ),
                    const SizedBox(height: PawlySpacing.sm),
                    if (state.breedMode == CatalogPickMode.catalog)
                      DropdownButtonFormField<String>(
                        value: state.breedId,
                        decoration:
                            const InputDecoration(labelText: 'Выберите породу'),
                        items: breedsForSpecies
                            .map((e) => DropdownMenuItem<String>(
                                value: e.id, child: Text(e.name)))
                            .toList(growable: false),
                        onChanged: c.setBreedId,
                      ),
                    if (state.breedMode == CatalogPickMode.custom)
                      PawlyTextField(
                        controller: _customBreedCtrl,
                        label: 'Своя порода',
                        onChanged: c.setCustomBreedName,
                      ),
                    const SizedBox(height: PawlySpacing.lg),
                    PawlyButton(label: 'Далее', onPressed: c.nextStep),
                  ],
                  if (state.step == PetCreateStep.appearance) ...[
                    _ModeChips(
                      title: 'Паттерн',
                      mode: state.patternMode,
                      onChanged: c.setPatternMode,
                    ),
                    const SizedBox(height: PawlySpacing.sm),
                    if (state.patternMode == CatalogPickMode.catalog)
                      DropdownButtonFormField<String>(
                        value: state.patternId,
                        decoration: const InputDecoration(
                            labelText: 'Выберите паттерн'),
                        items: patterns
                            .map((e) => DropdownMenuItem<String>(
                                value: e.id, child: Text(e.name)))
                            .toList(growable: false),
                        onChanged: c.setPatternId,
                      ),
                    if (state.patternMode == CatalogPickMode.custom)
                      PawlyTextField(
                        controller: _customPatternCtrl,
                        label: 'Свой паттерн',
                        onChanged: c.setCustomPatternName,
                      ),
                    const SizedBox(height: PawlySpacing.md),
                    Text('Цвета',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: PawlySpacing.xs),
                    Wrap(
                      spacing: PawlySpacing.xs,
                      runSpacing: PawlySpacing.xs,
                      children: colors.map((e) {
                        final selected = state.colorIds.contains(e.id);
                        return FilterChip(
                          label: Text(e.name),
                          selected: selected,
                          onSelected: (_) => c.toggleColor(e.id),
                        );
                      }).toList(growable: false),
                    ),
                    const SizedBox(height: PawlySpacing.sm),
                    Wrap(
                      spacing: PawlySpacing.xs,
                      runSpacing: PawlySpacing.xs,
                      children: <Widget>[
                        ...state.customColorsHex.asMap().entries.map((entry) {
                          return InputChip(
                            label: Text(entry.value),
                            onDeleted: () => c.removeCustomColorAt(entry.key),
                          );
                        }),
                        ActionChip(
                          label: const Text('Свой цвет'),
                          avatar: const Icon(Icons.palette_outlined, size: 18),
                          onPressed: () =>
                              _openColorPicker((hex) => c.addCustomColor(hex)),
                        ),
                      ],
                    ),
                    const SizedBox(height: PawlySpacing.lg),
                    PawlyButton(label: 'Далее', onPressed: c.nextStep),
                  ],
                  if (state.step == PetCreateStep.optional) ...[
                    Text('Необязательные поля',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: PawlySpacing.sm),
                    PawlyButton(
                      label: state.birthDate == null
                          ? 'Дата рождения (опционально)'
                          : 'Дата рождения: ${state.birthDate!.toLocal().toString().split(' ').first}',
                      variant: PawlyButtonVariant.secondary,
                      onPressed: () =>
                          _pickDate(c.setBirthDate, initial: state.birthDate),
                    ),
                    const SizedBox(height: PawlySpacing.sm),
                    DropdownButtonFormField<String>(
                      value: state.isNeutered,
                      decoration:
                          const InputDecoration(labelText: 'Стерилизация'),
                      items: const <DropdownMenuItem<String>>[
                        DropdownMenuItem(
                            value: 'UNKNOWN', child: Text('Неизвестно')),
                        DropdownMenuItem(value: 'YES', child: Text('Да')),
                        DropdownMenuItem(value: 'NO', child: Text('Нет')),
                      ],
                      onChanged: (v) => c.setIsNeutered(v ?? 'UNKNOWN'),
                    ),
                    const SizedBox(height: PawlySpacing.sm),
                    SwitchListTile.adaptive(
                      title: const Text('Уличный/свободный выгул'),
                      value: state.isOutdoor,
                      onChanged: c.setIsOutdoor,
                    ),
                    const SizedBox(height: PawlySpacing.sm),
                    PawlyTextField(
                      controller: _microchipCtrl,
                      label: 'ID микрочипа (опционально)',
                      onChanged: c.setMicrochipId,
                    ),
                    const SizedBox(height: PawlySpacing.sm),
                    PawlyButton(
                      label: state.microchipInstalledAt == null
                          ? 'Дата установки чипа (опционально)'
                          : 'Дата установки: ${state.microchipInstalledAt!.toLocal().toString().split(' ').first}',
                      variant: PawlyButtonVariant.secondary,
                      onPressed: () => _pickDate(
                        c.setMicrochipInstalledAt,
                        initial: state.microchipInstalledAt,
                      ),
                    ),
                    const SizedBox(height: PawlySpacing.lg),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: PawlyButton(
                            label: 'Пропустить',
                            variant: PawlyButtonVariant.ghost,
                            onPressed: c.nextStep,
                          ),
                        ),
                        const SizedBox(width: PawlySpacing.sm),
                        Expanded(
                          child: PawlyButton(
                              label: 'Далее', onPressed: c.nextStep),
                        ),
                      ],
                    ),
                  ],
                  if (state.step == PetCreateStep.review) ...[
                    PawlyCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('Имя: ${state.name}'),
                          Text('Пол: ${state.sex}'),
                          Text(
                              'Вид: ${state.speciesMode == CatalogPickMode.catalog ? "Из каталога" : "Свой"}'),
                          Text(
                              'Порода: ${state.breedMode == CatalogPickMode.catalog ? "Из каталога" : "Своя"}'),
                          Text(
                              'Паттерн: ${state.patternMode == CatalogPickMode.catalog ? "Из каталога" : "Свой"}'),
                          Text(
                              'Цветов: ${state.colorIds.length + state.customColorsHex.length}'),
                        ],
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

  Future<void> _openColorPicker(ValueChanged<String> onPicked) async {
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
                child: const Text('Отмена')),
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

    if (confirmed) {
      final argb = current.toARGB32().toRadixString(16).padLeft(8, '0');
      final hex = '#${argb.substring(2).toUpperCase()}';
      onPicked(hex);
    }
  }
}

class _ModeChips extends StatelessWidget {
  const _ModeChips({
    required this.title,
    required this.mode,
    required this.onChanged,
  });

  final String title;
  final CatalogPickMode mode;
  final ValueChanged<CatalogPickMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text('$title: '),
        ChoiceChip(
          label: const Text('Из каталога'),
          selected: mode == CatalogPickMode.catalog,
          onSelected: (_) => onChanged(CatalogPickMode.catalog),
        ),
        const SizedBox(width: PawlySpacing.xs),
        ChoiceChip(
          label: const Text('Свой вариант'),
          selected: mode == CatalogPickMode.custom,
          onSelected: (_) => onChanged(CatalogPickMode.custom),
        ),
      ],
    );
  }
}

class _StepPills extends StatelessWidget {
  const _StepPills({required this.step});
  final PetCreateStep step;

  @override
  Widget build(BuildContext context) {
    const labels = <String>[
      'База',
      'Порода',
      'Внешность',
      'Опционально',
      'Проверка'
    ];

    return Wrap(
      spacing: PawlySpacing.xs,
      runSpacing: PawlySpacing.xs,
      children: List<Widget>.generate(labels.length, (i) {
        final active = i == step.index;
        final done = i < step.index;

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: PawlySpacing.sm,
            vertical: PawlySpacing.xxs,
          ),
          decoration: BoxDecoration(
            color: active || done
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(PawlyRadius.pill),
          ),
          child: Text(
            '${i + 1}. ${labels[i]}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: active || done
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onPrimaryContainer,
                ),
          ),
        );
      }),
    );
  }
}
