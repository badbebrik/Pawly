import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/models/log_models.dart';
import '../../../../design_system/design_system.dart';
import '../providers/health_controllers.dart';

const String noLogTypeSelectionId = '__none__';

class PetLogTypePickerPage extends ConsumerStatefulWidget {
  const PetLogTypePickerPage({
    required this.petId,
    super.key,
  });

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

    return Scaffold(
      appBar: AppBar(title: const Text('Выбрать тип')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateType,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Новый тип'),
      ),
      body: bootstrapAsync.when(
        data: (bootstrap) => _buildContent(context, bootstrap),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _TypePickerErrorView(
          onRetry: () => ref.invalidate(
            petLogComposerBootstrapProvider(widget.petId),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    LogComposerBootstrapResponse bootstrap,
  ) {
    final filteredRecent = _filterTypes(bootstrap.recentLogTypes);
    final filteredSystem = _filterTypes(bootstrap.systemLogTypes);
    final filteredCustom = _filterTypes(bootstrap.customLogTypes);

    return ListView(
      padding: const EdgeInsets.all(PawlySpacing.lg),
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
        const SizedBox(height: PawlySpacing.md),
        _TypeChoiceCard(
          title: 'Без типа',
          subtitle: 'Обычная запись без привязки к конкретному типу',
          trailing: const _LogTypeEmoji(
            emoji: '📝',
            semanticLabel: 'Без типа',
          ),
          onTap: () => Navigator.of(context).pop(noLogTypeSelectionId),
        ),
        if (filteredRecent.isNotEmpty) ...<Widget>[
          const SizedBox(height: PawlySpacing.lg),
          _SectionTitle(title: 'Недавние'),
          const SizedBox(height: PawlySpacing.sm),
          ...filteredRecent.map(_buildTypeCard),
        ],
        if (filteredSystem.isNotEmpty) ...<Widget>[
          const SizedBox(height: PawlySpacing.lg),
          _SectionTitle(title: 'Системные'),
          const SizedBox(height: PawlySpacing.sm),
          ...filteredSystem.map(_buildTypeCard),
        ],
        if (filteredCustom.isNotEmpty) ...<Widget>[
          const SizedBox(height: PawlySpacing.lg),
          _SectionTitle(title: 'Мои'),
          const SizedBox(height: PawlySpacing.sm),
          ...filteredCustom.map(_buildTypeCard),
        ],
      ],
    );
  }

  List<LogType> _filterTypes(List<LogType> types) {
    final query = _searchQuery.trim().toLowerCase();
    final result = <LogType>[];
    final seenIds = <String>{};

    for (final type in types) {
      if (!seenIds.add(type.id)) {
        continue;
      }
      if (query.isNotEmpty && !type.name.toLowerCase().contains(query)) {
        continue;
      }
      result.add(type);
    }

    return result;
  }

  Widget _buildTypeCard(LogType type) {
    final metrics =
        type.metricRequirements.map((item) => item.metricName).join(', ');
    final sticker = _logTypeSticker(
      code: type.code,
      scope: type.scope,
      name: type.name,
      metricNames: type.metricRequirements.map((item) => item.metricName),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: PawlySpacing.md),
      child: _TypeChoiceCard(
        title: type.name,
        subtitle: metrics.isEmpty ? 'Метрики не заданы' : 'Метрики: $metrics',
        trailing: _LogTypeEmoji(
          emoji: sticker.emoji,
          semanticLabel: sticker.label,
        ),
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
    await ref.read(petLogComposerBootstrapProvider(widget.petId).future);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(createdTypeId);
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _TypeChoiceCard extends StatelessWidget {
  const _TypeChoiceCard({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PawlyCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: PawlySpacing.xs),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: PawlySpacing.md),
          SizedBox(
            width: 44,
            child: Center(child: trailing),
          ),
        ],
      ),
    );
  }
}

class _LogTypeSticker {
  const _LogTypeSticker({
    required this.emoji,
    required this.label,
  });

  final String emoji;
  final String label;
}

_LogTypeSticker _logTypeSticker({
  required String? code,
  required String scope,
  required String name,
  required Iterable<String> metricNames,
}) {
  final normalizedCode =
      code?.trim().toUpperCase() ?? _inferLogTypeCode(name, metricNames);

  return switch (normalizedCode) {
    'WEIGHING' => const _LogTypeSticker(
        emoji: '⚖️',
        label: 'Вес',
      ),
    'WEIGHT' => const _LogTypeSticker(
        emoji: '⚖️',
        label: 'Вес',
      ),
    'TEMPERATURE' => const _LogTypeSticker(
        emoji: '🌡️',
        label: 'Температура',
      ),
    'APPETITE' => const _LogTypeSticker(
        emoji: '🍽️',
        label: 'Аппетит',
      ),
    'WATER_INTAKE' => const _LogTypeSticker(
        emoji: '💧',
        label: 'Питье',
      ),
    'ACTIVITY' => const _LogTypeSticker(
        emoji: '🏃',
        label: 'Активность',
      ),
    'SLEEP' => const _LogTypeSticker(
        emoji: '😴',
        label: 'Сон',
      ),
    'STOOL' => const _LogTypeSticker(
        emoji: '💩',
        label: 'Стул',
      ),
    'URINATION' => const _LogTypeSticker(
        emoji: '🚽',
        label: 'Мочеиспускание',
      ),
    'VOMITING' => const _LogTypeSticker(
        emoji: '🤮',
        label: 'Рвота',
      ),
    'COUGHING' => const _LogTypeSticker(
        emoji: '😮‍💨',
        label: 'Кашель',
      ),
    'ITCHING' => const _LogTypeSticker(
        emoji: '🐾',
        label: 'Зуд',
      ),
    'PAIN_EPISODE' => const _LogTypeSticker(
        emoji: '⚠️',
        label: 'Боль',
      ),
    'MOOD_BEHAVIOR' => const _LogTypeSticker(
        emoji: '🙂',
        label: 'Поведение',
      ),
    'SEIZURE_EPISODE' => const _LogTypeSticker(
        emoji: '⚡',
        label: 'Судороги',
      ),
    'MEDICATION_TAKEN' => const _LogTypeSticker(
        emoji: '💊',
        label: 'Лекарство',
      ),
    'MEDICATION_MISSED' => const _LogTypeSticker(
        emoji: '⏭️',
        label: 'Пропуск',
      ),
    _ => scope == 'SYSTEM'
        ? const _LogTypeSticker(
            emoji: '🏷️',
            label: 'Системный',
          )
        : const _LogTypeSticker(
            emoji: '✨',
            label: 'Мой',
          ),
  };
}

String _inferLogTypeCode(String name, Iterable<String> metricNames) {
  final haystack = <String>[
    name,
    ...metricNames,
  ].join(' ').toLowerCase();

  if (haystack.contains('вес')) {
    return 'WEIGHT';
  }
  if (haystack.contains('температур')) {
    return 'TEMPERATURE';
  }
  if (haystack.contains('аппетит')) {
    return 'APPETITE';
  }
  if (haystack.contains('пить') || haystack.contains('вода')) {
    return 'WATER_INTAKE';
  }
  if (haystack.contains('активност')) {
    return 'ACTIVITY';
  }
  if (haystack.contains('сон')) {
    return 'SLEEP';
  }
  if (haystack.contains('стул')) {
    return 'STOOL';
  }
  if (haystack.contains('моч')) {
    return 'URINATION';
  }
  if (haystack.contains('рвот')) {
    return 'VOMITING';
  }
  if (haystack.contains('каш')) {
    return 'COUGHING';
  }
  if (haystack.contains('зуд')) {
    return 'ITCHING';
  }
  if (haystack.contains('бол')) {
    return 'PAIN_EPISODE';
  }
  if (haystack.contains('поведени') || haystack.contains('настроени')) {
    return 'MOOD_BEHAVIOR';
  }
  if (haystack.contains('судорог')) {
    return 'SEIZURE_EPISODE';
  }
  if (haystack.contains('лекар')) {
    return 'MEDICATION_TAKEN';
  }

  return '';
}

class _LogTypeEmoji extends StatelessWidget {
  const _LogTypeEmoji({
    required this.emoji,
    required this.semanticLabel,
  });

  final String emoji;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: Text(
        emoji,
        style: Theme.of(context).textTheme.headlineLarge,
      ),
    );
  }
}

class _TypePickerErrorView extends StatelessWidget {
  const _TypePickerErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PawlySpacing.lg),
        child: PawlyCard(
          title: const Text('Не удалось загрузить типы логов.'),
          footer: PawlyButton(
            label: 'Повторить',
            onPressed: onRetry,
            variant: PawlyButtonVariant.secondary,
          ),
          child: const SizedBox.shrink(),
        ),
      ),
    );
  }
}
