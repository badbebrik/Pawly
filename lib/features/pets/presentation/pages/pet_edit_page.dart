import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/design_system.dart';
import '../../controllers/pet_edit_controller.dart';
import '../../controllers/pets_controller.dart';
import '../../models/pet_form.dart';
import '../../shared/formatters/pet_date_formatters.dart';
import '../../shared/formatters/pet_form_step_formatters.dart';
import '../../shared/widgets/form/pet_form.dart';
import '../../states/pet_edit_state.dart';
import '../widgets/pet_edit_widgets.dart';

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
    final accessAsync = ref.watch(petAccessPolicyProvider(widget.petId));

    ref.listen<AsyncValue<PetEditState>>(
      petEditControllerProvider(widget.petId),
      (previous, next) {
        final previousError = previous?.asData?.value.error;
        final error = next.asData?.value.error;
        if (error == null || error.isEmpty || error == previousError) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      },
    );

    return PawlyScreenScaffold(
      title: 'Редактирование',
      leading: IconButton(
        onPressed: () => Navigator.of(context).maybePop(),
        icon: const Icon(Icons.chevron_left_rounded, size: 30),
      ),
      body: accessAsync.when(
        data: (access) {
          if (!access.petWrite) {
            return const PetEditNoAccessView();
          }

          final editAsync = ref.watch(petEditControllerProvider(widget.petId));
          return editAsync.when(
            data: _buildLoadedContent,
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(
              child: PawlyButton(
                label: 'Повторить',
                onPressed: () =>
                    ref.invalidate(petEditControllerProvider(widget.petId)),
                variant: PawlyButtonVariant.secondary,
                fullWidth: false,
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const PetEditNoAccessView(),
      ),
    );
  }

  Widget _buildLoadedContent(PetEditState state) {
    final draft = state.draft;
    final controller = ref.read(
      petEditControllerProvider(widget.petId).notifier,
    );

    _syncTextControllers(state);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          PawlySpacing.md,
          PawlySpacing.sm,
          PawlySpacing.md,
          PawlySpacing.xl,
        ),
        children: <Widget>[
          PetFormStepTabs<PetEditStep>(
            steps: PetEditStep.values,
            value: state.step,
            labelBuilder: petEditStepLabel,
            onChanged: controller.setStep,
          ),
          const SizedBox(height: PawlySpacing.md),
          if (state.step == PetEditStep.basic)
            PetBasicFormSection(
              draft: draft,
              species: state.catalog.species,
              nameController: _nameCtrl,
              customSpeciesController: _customSpeciesCtrl,
              birthDateLabel: petFormDateLabel(draft.birthDate),
              onNameChanged: controller.setName,
              onSexChanged: controller.setSex,
              onSpeciesModeChanged: (value) {
                controller.setSpeciesMode(value);
                if (value == CatalogPickMode.custom) {
                  _breedSearchCtrl.clear();
                }
              },
              onSpeciesChanged: (value) {
                if (value == null) return;
                _breedSearchCtrl.clear();
                controller.setSpeciesId(value);
              },
              onCustomSpeciesChanged: controller.setCustomSpeciesName,
              onBirthDatePressed: () => _pickDate(
                initial: draft.birthDate,
                lastDate: DateTime.now(),
                onPicked: controller.setBirthDate,
              ),
              onClearSex: () => controller.setSex('UNKNOWN'),
            ),
          if (state.step == PetEditStep.breed)
            PetBreedFormSection(
              draft: draft,
              searchController: _breedSearchCtrl,
              customBreedController: _customBreedCtrl,
              searchQuery: state.breedSearchQuery,
              breeds: state.filteredBreeds,
              totalBreedCount: state.breedsForSpecies.length,
              onBreedModeChanged: controller.setBreedMode,
              onSearchQueryChanged: controller.setBreedSearchQuery,
              onBreedChanged: controller.setBreedId,
              onCustomBreedChanged: controller.setCustomBreedName,
              subtitle: draft.speciesMode == CatalogPickMode.custom
                  ? 'Для своего вида укажите породу вручную.'
                  : 'Поиск по каталогу или свой вариант.',
            ),
          if (state.step == PetEditStep.appearance)
            PetAppearanceFormSection(
              draft: draft,
              patterns: state.catalog.patterns,
              colors: state.catalog.colors,
              customPatternController: _customPatternCtrl,
              maxColors: petFormMaxColors,
              onPatternModeChanged: controller.setPatternMode,
              onPatternChanged: controller.setPatternId,
              onCustomPatternChanged: controller.setCustomPatternName,
              onColorToggled: controller.toggleColor,
              onCustomColorDeleted: controller.removeCustomColorAt,
              onCustomColorPressed: _openColorPicker,
            ),
          if (state.step == PetEditStep.optional)
            PetOptionalFormSection(
              draft: draft,
              microchipController: _microchipCtrl,
              microchipInstalledAtLabel:
                  petFormDateLabel(draft.microchipInstalledAt),
              onIsNeuteredChanged: controller.setIsNeutered,
              onIsOutdoorChanged: controller.setIsOutdoor,
              onMicrochipIdChanged: controller.setMicrochipId,
              onMicrochipInstalledAtPressed: () => _pickDate(
                initial: draft.microchipInstalledAt,
                lastDate: DateTime.now(),
                onPicked: controller.setMicrochipInstalledAt,
              ),
            ),
          const SizedBox(height: PawlySpacing.md),
          PetEditBottomActions(
            isSubmitting: state.isSubmitting,
            onPrevious: state.step.index == 0 ? null : controller.previousStep,
            onNext: state.step.index == PetEditStep.values.length - 1
                ? null
                : controller.nextStep,
            onSubmit: _submit,
          ),
        ],
      ),
    );
  }

  void _syncTextControllers(PetEditState state) {
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
    ref.read(petEditControllerProvider(widget.petId).notifier).addCustomColor(
          hex: picked.hex,
          name: picked.name,
        );
  }

  Future<void> _submit() async {
    final saved = await ref
        .read(petEditControllerProvider(widget.petId).notifier)
        .submit();
    if (!saved || !mounted) return;
    Navigator.of(context).pop(true);
  }
}
