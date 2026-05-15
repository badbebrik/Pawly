import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/design_system.dart';
import '../../controllers/active_pet_controller.dart';
import '../../controllers/pet_create_controller.dart';
import '../../controllers/pets_controller.dart';
import '../../data/pet_catalog_provider.dart';
import '../../models/pet_form.dart';
import '../../shared/formatters/pet_catalog_label_formatters.dart';
import '../../shared/formatters/pet_date_formatters.dart';
import '../../shared/formatters/pet_form_step_formatters.dart';
import '../../shared/widgets/form/pet_form.dart';
import '../../states/pet_create_state.dart';
import '../widgets/pet_create_review_section.dart';

class PetCreatePage extends ConsumerStatefulWidget {
  const PetCreatePage({super.key});

  @override
  ConsumerState<PetCreatePage> createState() => _PetCreatePageState();
}

class _PetCreatePageState extends ConsumerState<PetCreatePage> {
  final _nameCtrl = TextEditingController();
  final _customSpeciesCtrl = TextEditingController();
  final _customBreedCtrl = TextEditingController();
  final _customPatternCtrl = TextEditingController();
  final _microchipCtrl = TextEditingController();
  final _breedSearchCtrl = TextEditingController();

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
    final catalogAsync = ref.watch(petCatalogProvider);
    final state = ref.watch(petCreateControllerProvider);
    final draft = state.draft;
    final c = ref.read(petCreateControllerProvider.notifier);

    ref.listen<PetCreateState>(petCreateControllerProvider, (_, next) {
      if (next.error != null && next.error!.isNotEmpty) {
        showPawlySnackBar(
          context,
          message: next.error!,
          tone: PawlySnackBarTone.error,
        );
      }
    });

    _syncTextControllers(state);

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
            onPressed: () => ref.invalidate(petCatalogProvider),
            fullWidth: false,
          ),
        ),
        data: (catalog) {
          final species = catalog.species;
          final breedsForSpecies = state.breedsForSpecies(catalog);
          final filteredBreeds = state.filteredBreeds(catalog);
          final patterns = catalog.patterns;
          final colors = catalog.colors;
          final speciesName = petSpeciesLabel(catalog, draft);
          final breedName = petBreedLabel(catalog, draft);
          final patternName = petPatternLabel(catalog, draft);
          final selectedCatalogColors = state.selectedCatalogColors(catalog);

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
                    labelBuilder: petCreateStepLabel,
                    onChanged: (step) => c.goToStep(catalog, step),
                  ),
                  const SizedBox(height: PawlySpacing.md),
                  if (state.step == PetCreateStep.basic) ...[
                    PetBasicFormSection(
                      draft: draft,
                      species: species,
                      nameController: _nameCtrl,
                      customSpeciesController: _customSpeciesCtrl,
                      birthDateLabel: petFormDateLabel(draft.birthDate),
                      onNameChanged: c.setName,
                      onSexChanged: c.setSex,
                      onSpeciesModeChanged: c.setSpeciesMode,
                      onSpeciesChanged: c.setSpeciesId,
                      onCustomSpeciesChanged: c.setCustomSpeciesName,
                      onBirthDatePressed: () => _pickDate(
                        c.setBirthDate,
                        initial: draft.birthDate,
                      ),
                    ),
                    const SizedBox(height: PawlySpacing.md),
                    PawlyButton(
                      label: 'Далее',
                      onPressed: () => c.nextStep(catalog),
                    ),
                  ],
                  if (state.step == PetCreateStep.breed) ...[
                    PetBreedFormSection(
                      draft: draft,
                      searchController: _breedSearchCtrl,
                      customBreedController: _customBreedCtrl,
                      searchQuery: state.breedSearchQuery,
                      breeds: filteredBreeds,
                      totalBreedCount: breedsForSpecies.length,
                      onBreedModeChanged: c.setBreedMode,
                      onSearchQueryChanged: c.setBreedSearchQuery,
                      onBreedChanged: c.setBreedId,
                      onCustomBreedChanged: c.setCustomBreedName,
                    ),
                    const SizedBox(height: PawlySpacing.md),
                    PawlyButton(
                      label: 'Далее',
                      onPressed: () => c.nextStep(catalog),
                    ),
                  ],
                  if (state.step == PetCreateStep.appearance) ...[
                    PetAppearanceFormSection(
                      draft: draft,
                      patterns: patterns,
                      colors: colors,
                      customPatternController: _customPatternCtrl,
                      maxColors: petCreateMaxColors,
                      subtitle: 'Окрас шерсти и основные цвета.',
                      onPatternModeChanged: c.setPatternMode,
                      onPatternChanged: c.setPatternId,
                      onCustomPatternChanged: c.setCustomPatternName,
                      onColorToggled: c.toggleColor,
                      onCustomColorDeleted: c.removeCustomColorAt,
                      onCustomColorPressed: () => _openColorPicker(
                        (color) => c.addCustomColor(
                          hex: color.hex,
                          name: color.name,
                        ),
                      ),
                    ),
                    const SizedBox(height: PawlySpacing.md),
                    PawlyButton(
                      label: 'Далее',
                      onPressed: () => c.nextStep(catalog),
                    ),
                  ],
                  if (state.step == PetCreateStep.optional) ...[
                    PetOptionalFormSection(
                      draft: draft,
                      microchipController: _microchipCtrl,
                      microchipInstalledAtLabel:
                          petFormDateLabel(draft.microchipInstalledAt),
                      subtitle: 'Можно заполнить сейчас или пропустить.',
                      onIsNeuteredChanged: c.setIsNeutered,
                      onIsOutdoorChanged: c.setIsOutdoor,
                      onMicrochipIdChanged: c.setMicrochipId,
                      onMicrochipInstalledAtPressed: () => _pickDate(
                        c.setMicrochipInstalledAt,
                        initial: draft.microchipInstalledAt,
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
                  if (state.step == PetCreateStep.review)
                    PetCreateReviewSection(
                      draft: draft,
                      speciesName: speciesName,
                      breedName: breedName,
                      patternName: patternName,
                      selectedCatalogColors: selectedCatalogColors,
                      isSubmitting: state.isSubmitting,
                      onSubmit: () async {
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
                        context.goNamed('pets');
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _syncTextControllers(PetCreateState state) {
    final draft = state.draft;
    _setControllerText(_nameCtrl, draft.name);
    _setControllerText(_customSpeciesCtrl, draft.customSpeciesName);
    _setControllerText(_customBreedCtrl, draft.customBreedName);
    _setControllerText(_customPatternCtrl, draft.customPatternName);
    _setControllerText(_microchipCtrl, draft.microchipId);
    _setControllerText(_breedSearchCtrl, state.breedSearchQuery);
  }

  void _setControllerText(TextEditingController controller, String value) {
    if (controller.text == value) return;
    controller.value = controller.value.copyWith(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
      composing: TextRange.empty,
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
    if (!mounted) {
      return;
    }
    onPicked(date);
  }

  Future<void> _openColorPicker(
    ValueChanged<PetFormColor> onPicked,
  ) async {
    final picked = await showDialog<PetFormCustomColor>(
      context: context,
      builder: (context) => const PetFormCustomColorPickerDialog(),
    );

    if (picked == null || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      onPicked(
        PetFormColor(
          hex: picked.hex,
          name: picked.name,
        ),
      );
    });
  }
}
