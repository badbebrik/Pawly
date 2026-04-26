import '../../states/pet_create_state.dart';
import '../../states/pet_edit_state.dart';

String petCreateStepLabel(PetCreateStep step) {
  switch (step) {
    case PetCreateStep.basic:
      return 'Основное';
    case PetCreateStep.breed:
      return 'Порода';
    case PetCreateStep.appearance:
      return 'Внешность';
    case PetCreateStep.optional:
      return 'Еще';
    case PetCreateStep.review:
      return 'Проверка';
  }
}

String petEditStepLabel(PetEditStep step) {
  switch (step) {
    case PetEditStep.basic:
      return 'Основное';
    case PetEditStep.breed:
      return 'Порода';
    case PetEditStep.appearance:
      return 'Внешность';
    case PetEditStep.optional:
      return 'Еще';
  }
}
