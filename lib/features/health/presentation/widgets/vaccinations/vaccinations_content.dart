import 'package:flutter/material.dart';

import '../../../models/health_models.dart';
import '../../../../../design_system/design_system.dart';
import '../../../states/vaccinations/vaccinations_state.dart';
import '../shared/health_common_widgets.dart';
import 'vaccination_list_card.dart';

class VaccinationsContent extends StatelessWidget {
  const VaccinationsContent({
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
  final PetVaccinationsState state;
  final TextEditingController searchController;
  final VaccinationBucket selectedBucket;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<VaccinationBucket> onBucketChanged;
  final Future<void> Function() onRetry;
  final VoidCallback onLoadMore;
  final ValueChanged<VaccinationCard> onMarkDone;

  @override
  Widget build(BuildContext context) {
    if (!state.canRead) {
      return HealthStateMessageView(
        title: 'Нет доступа',
        message: 'У вас нет права просмотра вакцинаций этого питомца.',
        onRetry: onRetry,
      );
    }

    final items = state.itemsFor(selectedBucket);
    final isPlanned = selectedBucket == VaccinationBucket.planned;

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
            hintText: 'Вакцина, клиника, врач',
            textInputAction: TextInputAction.search,
            prefixIcon: const Icon(Icons.search_rounded),
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: PawlySpacing.md),
          HealthBucketSegment<VaccinationBucket>(
            selectedValue: selectedBucket,
            onChanged: onBucketChanged,
            options: <HealthBucketOption<VaccinationBucket>>[
              HealthBucketOption<VaccinationBucket>(
                value: VaccinationBucket.planned,
                label: 'План',
                count: state.plannedItems.length,
              ),
              HealthBucketOption<VaccinationBucket>(
                value: VaccinationBucket.history,
                label: 'История',
                count: state.historyItems.length,
              ),
            ],
          ),
          const SizedBox(height: PawlySpacing.md),
          if (items.isEmpty)
            HealthInlineMessage(
              title: isPlanned ? 'Плановых вакцинаций нет' : 'История пуста',
              message: isPlanned
                  ? 'Добавьте первую запись, чтобы не потерять дату прививки.'
                  : 'Выполненные вакцинации появятся здесь.',
            )
          else
            ...items.map(
              (item) => VaccinationListCard(
                petId: petId,
                item: item,
                canWrite: state.canWrite,
                isBusy: state.busyVaccinationIds.contains(item.id),
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
