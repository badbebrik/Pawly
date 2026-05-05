import 'package:flutter/material.dart';

import '../../../../../design_system/design_system.dart';
import '../../../states/vet_visits/vet_visits_state.dart';
import '../shared/health_common_widgets.dart';
import 'vet_visit_list_card.dart';

class VetVisitsContent extends StatelessWidget {
  const VetVisitsContent({
    required this.petId,
    required this.state,
    required this.searchController,
    required this.selectedBucket,
    required this.onSearchChanged,
    required this.onBucketChanged,
    required this.onRetry,
    required this.onLoadMore,
    super.key,
  });

  final String petId;
  final PetVetVisitsState state;
  final TextEditingController searchController;
  final VetVisitBucket selectedBucket;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<VetVisitBucket> onBucketChanged;
  final Future<void> Function() onRetry;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (!state.canRead) {
      return HealthStateMessageView(
        title: 'Нет доступа',
        message: 'У вас нет права просмотра визитов этого питомца.',
        onRetry: onRetry,
      );
    }

    final items = state.itemsFor(selectedBucket);
    final isUpcoming = selectedBucket == VetVisitBucket.upcoming;

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
            hintText: 'Клиника, врач, причина',
            textInputAction: TextInputAction.search,
            prefixIcon: const Icon(Icons.search_rounded),
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: PawlySpacing.md),
          HealthBucketSegment<VetVisitBucket>(
            selectedValue: selectedBucket,
            onChanged: onBucketChanged,
            options: <HealthBucketOption<VetVisitBucket>>[
              HealthBucketOption<VetVisitBucket>(
                value: VetVisitBucket.upcoming,
                label: 'План',
                count: state.upcomingItems.length,
              ),
              HealthBucketOption<VetVisitBucket>(
                value: VetVisitBucket.history,
                label: 'История',
                count: state.historyItems.length,
              ),
            ],
          ),
          const SizedBox(height: PawlySpacing.md),
          if (items.isEmpty)
            HealthInlineMessage(
              title: isUpcoming ? 'Предстоящих визитов нет' : 'История пуста',
              message: isUpcoming
                  ? 'Добавьте визит, чтобы не потерять дату приема.'
                  : 'Завершенные визиты появятся здесь.',
            )
          else
            ...items.map(
              (item) => VetVisitListCard(
                petId: petId,
                item: item,
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
