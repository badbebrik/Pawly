import 'package:flutter/material.dart';

import '../../../models/health_models.dart';
import '../../../../../design_system/design_system.dart';
import '../../../states/procedures/procedures_state.dart';
import '../shared/health_common_widgets.dart';
import 'procedure_list_card.dart';

class ProceduresContent extends StatelessWidget {
  const ProceduresContent({
    required this.petId,
    required this.state,
    required this.searchController,
    required this.selectedBucket,
    required this.onSearchChanged,
    required this.onBucketChanged,
    required this.onRetry,
    required this.onLoadMore,
    required this.onMarkDone,
    super.key,
  });

  final String petId;
  final PetProceduresState state;
  final TextEditingController searchController;
  final ProcedureBucket selectedBucket;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<ProcedureBucket> onBucketChanged;
  final Future<void> Function() onRetry;
  final VoidCallback onLoadMore;
  final ValueChanged<ProcedureCard> onMarkDone;

  @override
  Widget build(BuildContext context) {
    if (!state.canRead) {
      return HealthStateMessageView(
        title: 'Нет доступа',
        message: 'У вас нет права просмотра процедур этого питомца.',
        onRetry: onRetry,
      );
    }

    final items = state.itemsFor(selectedBucket);
    final isPlanned = selectedBucket == ProcedureBucket.planned;

    return RefreshIndicator(
      onRefresh: onRetry,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          PawlySpacing.md,
          PawlySpacing.sm,
          PawlySpacing.md,
          PawlySpacing.xl,
        ),
        children: <Widget>[
          PawlyTextField(
            controller: searchController,
            hintText: 'Название, препарат, заметки',
            textInputAction: TextInputAction.search,
            prefixIcon: const Icon(Icons.search_rounded),
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: PawlySpacing.md),
          HealthBucketSegment<ProcedureBucket>(
            selectedValue: selectedBucket,
            onChanged: onBucketChanged,
            options: <HealthBucketOption<ProcedureBucket>>[
              HealthBucketOption<ProcedureBucket>(
                value: ProcedureBucket.planned,
                label: 'План',
                count: state.plannedItems.length,
              ),
              HealthBucketOption<ProcedureBucket>(
                value: ProcedureBucket.history,
                label: 'История',
                count: state.historyItems.length,
              ),
            ],
          ),
          const SizedBox(height: PawlySpacing.md),
          if (items.isEmpty)
            HealthInlineMessage(
              title:
                  isPlanned ? 'Запланированных процедур нет' : 'История пуста',
              message: isPlanned
                  ? 'Добавьте процедуру, чтобы не потерять дату выполнения.'
                  : 'Выполненные процедуры появятся здесь.',
            )
          else
            ...items.map(
              (item) => ProcedureListCard(
                petId: petId,
                item: item,
                canWrite: state.canWrite,
                isBusy: state.busyProcedureIds.contains(item.id),
                onMarkDone:
                    item.status == 'PLANNED' ? () => onMarkDone(item) : null,
              ),
            ),
          if (state.nextCursorFor(selectedBucket) != null) ...<Widget>[
            const SizedBox(height: PawlySpacing.md),
            PawlyButton(
              label: state.isLoadingMore(selectedBucket)
                  ? 'Загрузка...'
                  : 'Загрузить еще',
              onPressed:
                  state.isLoadingMore(selectedBucket) ? null : onLoadMore,
              variant: PawlyButtonVariant.secondary,
            ),
          ],
        ],
      ),
    );
  }
}
