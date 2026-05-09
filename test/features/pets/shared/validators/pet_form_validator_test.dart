import 'package:flutter_test/flutter_test.dart';
import 'package:pawly/features/pets/data/pet_catalog_models.dart';
import 'package:pawly/features/pets/models/pet_form.dart';
import 'package:pawly/features/pets/shared/validators/pet_form_validator.dart';

void main() {
  group('validatePetForm', () {
    test('accepts a valid catalog-based form', () {
      final error = validatePetForm(_validForm(), _catalog());

      expect(error, isNull);
    });

    test('requires pet name', () {
      final error =
          validatePetForm(_validForm().copyWith(name: ' '), _catalog());

      expect(error!.section, PetFormValidationSection.basic);
      expect(error.message, 'Введите кличку питомца');
    });

    test('rejects missing and stale catalog species', () {
      final missing = validatePetForm(
        _validForm().copyWith(clearSpeciesId: true),
        _catalog(),
      );
      final stale = validatePetForm(
        _validForm().copyWith(speciesId: 'stale-species'),
        _catalog(),
      );

      expect(missing!.message, 'Выберите вид питомца');
      expect(stale!.message, 'Выбранный вид устарел. Обновите выбор.');
    });

    test('requires custom species name in custom mode', () {
      final error = validatePetForm(
        _validForm().copyWith(
          speciesMode: CatalogPickMode.custom,
          customSpeciesName: ' ',
        ),
        _catalog(),
      );

      expect(error!.section, PetFormValidationSection.basic);
      expect(error.message, 'Введите свой вариант вида');
    });

    test('rejects missing and stale catalog breed', () {
      final missing = validatePetForm(
        _validForm().copyWith(clearBreedId: true),
        _catalog(),
      );
      final stale = validatePetForm(
        _validForm().copyWith(breedId: 'stale-breed'),
        _catalog(),
      );

      expect(missing!.message, 'Выберите породу');
      expect(stale!.message, 'Выбранная порода устарела. Обновите выбор.');
    });

    test('requires custom breed name in custom mode', () {
      final error = validatePetForm(
        _validForm().copyWith(
          breedMode: CatalogPickMode.custom,
          customBreedName: '',
        ),
        _catalog(),
      );

      expect(error!.section, PetFormValidationSection.breed);
      expect(error.message, 'Введите свой вариант породы');
    });

    test('rejects missing and stale catalog pattern', () {
      final missing = validatePetForm(
        _validForm().copyWith(clearPatternId: true),
        _catalog(),
      );
      final stale = validatePetForm(
        _validForm().copyWith(patternId: 'stale-pattern'),
        _catalog(),
      );

      expect(missing!.message, 'Выберите окрас');
      expect(stale!.message, 'Выбранный окрас устарел. Обновите выбор.');
    });

    test('requires custom pattern name in custom mode', () {
      final error = validatePetForm(
        _validForm().copyWith(
          patternMode: CatalogPickMode.custom,
          customPatternName: ' ',
        ),
        _catalog(),
      );

      expect(error!.section, PetFormValidationSection.appearance);
      expect(error.message, 'Введите свой вариант окраса');
    });

    test('requires at least one color', () {
      final error = validatePetForm(
        _validForm().copyWith(colorIds: const <String>{}),
        _catalog(),
      );

      expect(error!.section, PetFormValidationSection.appearance);
      expect(error.message, 'Выберите минимум один цвет');
    });

    test('rejects stale catalog colors', () {
      final error = validatePetForm(
        _validForm().copyWith(colorIds: const <String>{'stale-color'}),
        _catalog(),
      );

      expect(
          error!.message, 'Один из выбранных цветов устарел. Обновите выбор.');
    });

    test('enforces maximum selected colors', () {
      final customColors = List<PetFormColor>.generate(
        petFormMaxColors + 1,
        (index) => PetFormColor(hex: '#00000$index', name: 'Color $index'),
      );

      final error = validatePetForm(
        _validForm().copyWith(
          colorIds: const <String>{},
          customColors: customColors,
        ),
        _catalog(),
      );

      expect(error!.message, 'Можно выбрать до 10 цветов.');
    });

    test('rejects invalid custom color hex', () {
      final error = validatePetForm(
        _validForm().copyWith(
          colorIds: const <String>{},
          customColors: const <PetFormColor>[
            PetFormColor(hex: 'not-a-color', name: 'Broken'),
          ],
        ),
        _catalog(),
      );

      expect(error!.message, 'Неверный формат пользовательского цвета');
    });
  });
}

PetForm _validForm() {
  return PetForm.empty().copyWith(
    name: 'Барсик',
    speciesId: 'cat',
    breedId: 'siberian',
    patternId: 'solid',
    colorIds: const <String>{'black'},
  );
}

PetCatalog _catalog() {
  return const PetCatalog(
    version: 1,
    species: <PetSpeciesOption>[
      PetSpeciesOption(id: 'cat', name: 'Кошка', iconName: 'cat'),
    ],
    breeds: <PetBreedOption>[
      PetBreedOption(id: 'siberian', speciesId: 'cat', name: 'Сибирская'),
    ],
    colors: <PetColorOption>[
      PetColorOption(id: 'black', name: 'Черный', hex: '#000000'),
    ],
    patterns: <PetCoatPatternOption>[
      PetCoatPatternOption(id: 'solid', name: 'Сплошной', iconKey: 'solid'),
    ],
  );
}
