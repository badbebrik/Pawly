import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../design_system/design_system.dart';
import '../../../../logs/controllers/logs_dependencies.dart';
import '../../../../logs/models/log_constants.dart';
import '../../../../logs/models/log_models.dart';
import '../../../shared/formatters/health_display_formatters.dart';
import '../../../shared/formatters/health_log_formatters.dart';

class VetVisitLogPickerSheet extends ConsumerStatefulWidget {
  const VetVisitLogPickerSheet({
    required this.petId,
    required this.excludedLogIds,
    super.key,
  });

  final String petId;
  final Set<String> excludedLogIds;

  @override
  ConsumerState<VetVisitLogPickerSheet> createState() =>
      _VetVisitLogPickerSheetState();
}

class _VetVisitLogPickerSheetState
    extends ConsumerState<VetVisitLogPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  late Future<LogsPageResult> _logsFuture;

  @override
  void initState() {
    super.initState();
    _logsFuture = _loadLogs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final height = MediaQuery.of(context).size.height * 0.8;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SafeArea(
        child: SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              PawlySpacing.lg,
              0,
              PawlySpacing.lg,
              PawlySpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Прикрепить запись',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: PawlySpacing.xs),
                Text(
                  'Выберите существующую запись из журнала питомца.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: PawlySpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: PawlyTextField(
                        controller: _searchController,
                        label: 'Поиск по записям',
                        textInputAction: TextInputAction.search,
                        onFieldSubmitted: (_) => _reloadLogs(),
                        prefixIcon: const Icon(Icons.search_rounded),
                      ),
                    ),
                    const SizedBox(width: PawlySpacing.sm),
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: PawlyButton(
                        label: 'Найти',
                        onPressed: _reloadLogs,
                        variant: PawlyButtonVariant.secondary,
                        fullWidth: false,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: PawlySpacing.md),
                Expanded(
                  child: FutureBuilder<LogsPageResult>(
                    future: _logsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: PawlyCard(
                            title: const Text('Не удалось загрузить записи'),
                            footer: PawlyButton(
                              label: 'Повторить',
                              onPressed: _reloadLogs,
                              variant: PawlyButtonVariant.secondary,
                            ),
                            child: const Text(
                              'Попробуйте обновить список еще раз.',
                            ),
                          ),
                        );
                      }

                      final response = snapshot.data ??
                          const LogsPageResult(items: <LogListItem>[]);
                      final logs = response.items
                          .where(
                            (log) => !widget.excludedLogIds.contains(log.id),
                          )
                          .toList(growable: false);

                      if (logs.isEmpty) {
                        return Center(
                          child: PawlyCard(
                            child: Text(
                              widget.excludedLogIds.isEmpty
                                  ? 'Подходящих записей пока нет.'
                                  : 'Все найденные записи уже прикреплены к визиту.',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: logs.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: PawlySpacing.sm),
                        itemBuilder: (context, index) {
                          final log = logs[index];
                          return _LogPickerTile(log: log);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<LogsPageResult> _loadLogs() {
    return ref.read(logsRepositoryProvider).listLogs(
          widget.petId,
          query: LogsQuery(
            limit: 30,
            searchQuery: nonEmptyHealthText(_searchController.text),
            sort: LogSort.occurredAtDesc,
            includeFacets: false,
          ),
        );
  }

  void _reloadLogs() {
    setState(() => _logsFuture = _loadLogs());
  }
}

class _LogPickerTile extends StatelessWidget {
  const _LogPickerTile({required this.log});

  final LogListItem log;

  @override
  Widget build(BuildContext context) {
    return PawlyCard(
      onTap: () => Navigator.of(context).pop(log),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.notes_rounded),
          const SizedBox(width: PawlySpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  log.logTypeName ?? 'Запись',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: PawlySpacing.xs),
                Text(
                  formatHealthLogListItemSubtitle(log),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
