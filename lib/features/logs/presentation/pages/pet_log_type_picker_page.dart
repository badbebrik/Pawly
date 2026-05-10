import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/design_system.dart';
import '../../controllers/logs_controller.dart';
import '../../models/log_constants.dart';
import '../../models/log_models.dart';
import '../../shared/utils/log_catalog_filters.dart';
import '../../shared/utils/log_type_utils.dart';
import '../widgets/log_type_picker_widgets.dart';

class PetLogTypePickerPage extends ConsumerStatefulWidget {
  const PetLogTypePickerPage({required this.petId, super.key});

  final String petId;

  @override
  ConsumerState<PetLogTypePickerPage> createState() =>
      _PetLogTypePickerPageState();
}

class _PetLogTypePickerPageState extends ConsumerState<PetLogTypePickerPage> {
  late final TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bootstrapAsync = ref.watch(
      petLogComposerBootstrapProvider(widget.petId),
    );

    return PawlyScreenScaffold(
      title: 'Выбрать тип',
      floatingActionButton: PawlyAddActionButton(
        label: 'Новый тип',
        tooltip: 'Создать тип записи',
        onTap: _openCreateType,
      ),
      body: bootstrapAsync.when(
        data: (bootstrap) => _buildContent(context, bootstrap),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => LogTypePickerErrorView(
          onRetry: () =>
              ref.invalidate(petLogComposerBootstrapProvider(widget.petId)),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    LogsBootstrap bootstrap,
  ) {
    final groups = groupedBootstrapLogTypes(bootstrap);
    final filteredRecent = filterUniqueLogTypesByName(
      types: groups.recent,
      query: _searchQuery,
    );
    final filteredSystem = filterUniqueLogTypesByName(
      types: groups.system,
      query: _searchQuery,
    );
    final filteredCustom = filterUniqueLogTypesByName(
      types: groups.custom,
      query: _searchQuery,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        PawlySpacing.md,
        PawlySpacing.sm,
        PawlySpacing.md,
        PawlySpacing.xl,
      ),
      children: <Widget>[
        PawlyTextField(
          controller: _searchController,
          hintText: 'Поиск по типам',
          prefixIcon: const Icon(Icons.search_rounded),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        const SizedBox(height: PawlySpacing.md),
        LogTypeChoiceCard(
          title: 'Без типа',
          subtitle: 'Обычная запись без привязки к конкретному типу',
          emoji: '📝',
          onTap: () => Navigator.of(context).pop(noLogTypeSelectionId),
        ),
        if (filteredRecent.isNotEmpty) ...<Widget>[
          const SizedBox(height: PawlySpacing.lg),
          const LogTypePickerSectionTitle(title: 'Недавние'),
          const SizedBox(height: PawlySpacing.sm),
          ...filteredRecent.map(_buildTypeCard),
        ],
        if (filteredSystem.isNotEmpty) ...<Widget>[
          const SizedBox(height: PawlySpacing.lg),
          const LogTypePickerSectionTitle(title: 'Системные'),
          const SizedBox(height: PawlySpacing.sm),
          ...filteredSystem.map(_buildTypeCard),
        ],
        if (filteredCustom.isNotEmpty) ...<Widget>[
          const SizedBox(height: PawlySpacing.lg),
          const LogTypePickerSectionTitle(title: 'Мои'),
          const SizedBox(height: PawlySpacing.sm),
          ...filteredCustom.map(_buildTypeCard),
        ],
      ],
    );
  }

  Widget _buildTypeCard(LogTypeItem type) {
    return Padding(
      padding: const EdgeInsets.only(bottom: PawlySpacing.md),
      child: LogTypeChoiceCard.forType(
        type: type,
        onTap: () => Navigator.of(context).pop(type.id),
      ),
    );
  }

  Future<void> _openCreateType() async {
    final createdTypeId = await context.pushNamed<String>(
      'petLogTypeCreate',
      pathParameters: <String, String>{'petId': widget.petId},
    );
    if (createdTypeId == null || !mounted) {
      return;
    }

    ref.invalidate(petLogComposerBootstrapProvider(widget.petId));
    try {
      await ref.read(petLogComposerBootstrapProvider(widget.petId).future);
    } catch (_) {}
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(createdTypeId);
  }
}
