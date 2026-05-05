import 'package:flutter/material.dart';

import '../../../models/health_models.dart';
import '../../../../../design_system/design_system.dart';

class VaccinationTargetPickerRow extends StatelessWidget {
  const VaccinationTargetPickerRow({
    required this.targets,
    required this.selectedIds,
    required this.customNames,
    required this.onTap,
    super.key,
  });

  final List<HealthDictionaryItem> targets;
  final Set<String> selectedIds;
  final List<String> customNames;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedLabels = _selectedTargetLabels();
    final summary = switch (selectedLabels.length) {
      0 => 'Не выбраны',
      1 => selectedLabels.first,
      2 => selectedLabels.join(', '),
      _ => '${selectedLabels.length} целей',
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: PawlySpacing.md,
            vertical: PawlySpacing.sm,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Цели вакцинации',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: PawlySpacing.xxxs),
                    Text(
                      summary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: selectedLabels.isEmpty
                            ? colorScheme.onSurfaceVariant
                            : colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: PawlySpacing.sm),
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

  List<String> _selectedTargetLabels() {
    final labels = <String>[
      for (final target in targets)
        if (selectedIds.contains(target.id)) target.name,
      ...customNames,
    ];
    return labels;
  }
}

class VaccinationTargetSelection {
  const VaccinationTargetSelection({
    required this.selectedIds,
    required this.customNames,
  });

  final Set<String> selectedIds;
  final List<String> customNames;
}

class VaccinationTargetsSheet extends StatefulWidget {
  const VaccinationTargetsSheet({
    required this.targets,
    required this.selectedIds,
    required this.customNames,
    super.key,
  });

  final List<HealthDictionaryItem> targets;
  final Set<String> selectedIds;
  final List<String> customNames;

  @override
  State<VaccinationTargetsSheet> createState() =>
      _VaccinationTargetsSheetState();
}

class _VaccinationTargetsSheetState extends State<VaccinationTargetsSheet> {
  final _searchController = TextEditingController();
  final _customController = TextEditingController();
  late final Set<String> _selectedIds = <String>{...widget.selectedIds};
  late final List<String> _customNames = <String>[...widget.customNames];
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewInsets = MediaQuery.of(context).viewInsets;
    final filteredTargets = _filteredTargets();

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.78,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  PawlySpacing.lg,
                  0,
                  PawlySpacing.lg,
                  PawlySpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Цели вакцинации',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: PawlySpacing.md),
                    PawlyTextField(
                      controller: _searchController,
                      hintText: 'Найти цель',
                      prefixIcon: const Icon(Icons.search_rounded),
                      onChanged: (value) {
                        setState(() => _searchQuery = value.trim());
                      },
                    ),
                    const SizedBox(height: PawlySpacing.sm),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: PawlyTextField(
                            controller: _customController,
                            hintText: 'Своя цель',
                            textCapitalization: TextCapitalization.sentences,
                            onFieldSubmitted: (_) => _addCustomTarget(),
                          ),
                        ),
                        const SizedBox(width: PawlySpacing.sm),
                        IconButton.filledTonal(
                          onPressed: _addCustomTarget,
                          icon: const Icon(Icons.add_rounded),
                          tooltip: 'Добавить цель',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  children: <Widget>[
                    if (_customNames.isNotEmpty) ...<Widget>[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          PawlySpacing.lg,
                          0,
                          PawlySpacing.lg,
                          PawlySpacing.xs,
                        ),
                        child: Text(
                          'Свои цели',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      for (final name in _customNames)
                        _VaccinationCustomTargetRow(
                          name: name,
                          onRemove: () {
                            setState(() => _customNames.remove(name));
                          },
                        ),
                    ],
                    if (filteredTargets.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(PawlySpacing.lg),
                        child: Text(
                          'Подходящих целей нет.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    else
                      for (final target in filteredTargets)
                        CheckboxListTile(
                          value: _selectedIds.contains(target.id),
                          onChanged: (_) => _toggleTarget(target.id),
                          title: Text(target.name),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  PawlySpacing.lg,
                  PawlySpacing.sm,
                  PawlySpacing.lg,
                  PawlySpacing.lg,
                ),
                child: PawlyButton(
                  label: 'Готово',
                  onPressed: () {
                    Navigator.of(context).pop(
                      VaccinationTargetSelection(
                        selectedIds: _selectedIds,
                        customNames: _customNames,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<HealthDictionaryItem> _filteredTargets() {
    final query = _searchQuery.toLowerCase();
    if (query.isEmpty) {
      return widget.targets;
    }
    return widget.targets
        .where((target) => target.name.toLowerCase().contains(query))
        .toList(growable: false);
  }

  void _toggleTarget(String targetId) {
    setState(() {
      if (_selectedIds.contains(targetId)) {
        _selectedIds.remove(targetId);
      } else {
        _selectedIds.add(targetId);
      }
    });
  }

  void _addCustomTarget() {
    final name = _customController.text.trim();
    if (name.isEmpty) {
      return;
    }

    final exists = _customNames.any(
          (item) => item.toLowerCase() == name.toLowerCase(),
        ) ||
        widget.targets.any(
          (item) => item.name.toLowerCase() == name.toLowerCase(),
        );
    setState(() {
      if (!exists) {
        _customNames.add(name);
      }
      _customController.clear();
    });
  }
}

class _VaccinationCustomTargetRow extends StatelessWidget {
  const _VaccinationCustomTargetRow({
    required this.name,
    required this.onRemove,
  });

  final String name;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.check_circle_rounded),
      title: Text(name),
      trailing: IconButton(
        onPressed: onRemove,
        icon: const Icon(Icons.close_rounded),
        tooltip: 'Удалить цель',
      ),
    );
  }
}
