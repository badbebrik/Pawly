import 'package:flutter/material.dart';

import '../../../../../design_system/design_system.dart';
import '../../../states/medical_records/medical_records_state.dart';
import '../shared/health_common_widgets.dart';
import 'medical_record_list_card.dart';

class MedicalRecordsContent extends StatelessWidget {
  const MedicalRecordsContent({
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
  final PetMedicalRecordsState state;
  final TextEditingController searchController;
  final MedicalRecordBucket selectedBucket;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<MedicalRecordBucket> onBucketChanged;
  final Future<void> Function() onRetry;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (!state.canRead) {
      return HealthStateMessageView(
        title: 'Нет доступа',
        message: 'У вас нет права просмотра медкарты этого питомца.',
        onRetry: onRetry,
      );
    }

    final items = state.itemsFor(selectedBucket);
    final isActive = selectedBucket == MedicalRecordBucket.active;

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
            hintText: 'Название, описание',
            textInputAction: TextInputAction.search,
            prefixIcon: const Icon(Icons.search_rounded),
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: PawlySpacing.md),
          HealthBucketSegment<MedicalRecordBucket>(
            selectedValue: selectedBucket,
            onChanged: onBucketChanged,
            options: <HealthBucketOption<MedicalRecordBucket>>[
              HealthBucketOption<MedicalRecordBucket>(
                value: MedicalRecordBucket.active,
                label: 'Активные',
                count: state.activeItems.length,
              ),
              HealthBucketOption<MedicalRecordBucket>(
                value: MedicalRecordBucket.archive,
                label: 'Архив',
                count: state.archiveItems.length,
              ),
            ],
          ),
          const SizedBox(height: PawlySpacing.md),
          if (items.isEmpty)
            HealthInlineMessage(
              title: isActive ? 'Активных записей нет' : 'Архив пуст',
              message: isActive
                  ? 'Добавьте запись, чтобы важная медицинская информация была под рукой.'
                  : 'Закрытые записи появятся здесь.',
            )
          else
            ...items.map(
              (item) => MedicalRecordListCard(
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
