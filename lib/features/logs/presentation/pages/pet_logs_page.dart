import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/design_system.dart';
import '../../../pets/controllers/pets_controller.dart';
import '../../controllers/logs_controller.dart';
import '../widgets/logs_list_view.dart';
import '../widgets/logs_state_views.dart';

class PetLogsPage extends ConsumerWidget {
  const PetLogsPage({required this.petId, super.key});

  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessAsync = ref.watch(petAccessPolicyProvider(petId));

    return accessAsync.when(
      data: (access) {
        if (!access.logRead) {
          return const PawlyScreenScaffold(
            title: 'Записи',
            body: LogsNoAccessView(),
          );
        }

        final logsState = ref.watch(petLogsControllerProvider(petId));
        return PawlyScreenScaffold(
          title: 'Записи',
          floatingActionButton: access.logWrite
              ? PawlyAddActionButton(
                  label: 'Добавить',
                  tooltip: 'Добавить запись',
                  onTap: () => _openCreateLog(context, ref),
                )
              : null,
          body: logsState.when(
            data: (state) => LogsListView(
              petId: petId,
              state: state,
              onRefresh: () =>
                  ref.read(petLogsControllerProvider(petId).notifier).reload(),
              onSearchChanged: (value) => ref
                  .read(petLogsControllerProvider(petId).notifier)
                  .setSearchQuery(value),
              onToggleType: (typeId) => ref
                  .read(petLogsControllerProvider(petId).notifier)
                  .toggleTypeFilter(typeId),
              onApplyTypeFilters: (typeIds) => ref
                  .read(petLogsControllerProvider(petId).notifier)
                  .setTypeFilters(typeIds),
              onSetSource: (source) => ref
                  .read(petLogsControllerProvider(petId).notifier)
                  .setSourceFilter(source),
              onSetWithAttachmentsOnly: (value) => ref
                  .read(petLogsControllerProvider(petId).notifier)
                  .setWithAttachmentsOnly(value),
              onSetWithMetricsOnly: (value) => ref
                  .read(petLogsControllerProvider(petId).notifier)
                  .setWithMetricsOnly(value),
              onLoadMore: () => ref
                  .read(petLogsControllerProvider(petId).notifier)
                  .loadMore(),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => LogsErrorView(
              onRetry: () =>
                  ref.read(petLogsControllerProvider(petId).notifier).reload(),
            ),
          ),
        );
      },
      loading: () => const PawlyScreenScaffold(
        title: 'Записи',
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => PawlyScreenScaffold(
        title: 'Записи',
        body: LogsErrorView(
          onRetry: () => ref.invalidate(petAccessPolicyProvider(petId)),
        ),
      ),
    );
  }

  Future<void> _openCreateLog(BuildContext context, WidgetRef ref) async {
    final created = await context.pushNamed<bool>(
      'petLogCreate',
      pathParameters: <String, String>{'petId': petId},
    );
    if (created == true && context.mounted) {
      await ref.read(petLogsControllerProvider(petId).notifier).reload();
    }
  }
}
