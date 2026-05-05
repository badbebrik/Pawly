import '../../models/log_constants.dart';

class LogTypeSticker {
  const LogTypeSticker({required this.emoji, required this.label});

  final String emoji;
  final String label;
}

LogTypeSticker logTypeStickerForCode({
  required String? code,
  String? scope,
}) {
  final normalizedCode = code?.trim().toUpperCase();

  return switch (normalizedCode) {
    'WEIGHING' => const LogTypeSticker(emoji: '⚖️', label: 'Вес'),
    'WEIGHT' => const LogTypeSticker(emoji: '⚖️', label: 'Вес'),
    'TEMPERATURE' => const LogTypeSticker(emoji: '🌡️', label: 'Температура'),
    'APPETITE' => const LogTypeSticker(emoji: '🍽️', label: 'Аппетит'),
    'WATER_INTAKE' => const LogTypeSticker(emoji: '💧', label: 'Питье'),
    'ACTIVITY' => const LogTypeSticker(emoji: '🏃', label: 'Активность'),
    'SLEEP' => const LogTypeSticker(emoji: '😴', label: 'Сон'),
    'STOOL' => const LogTypeSticker(emoji: '💩', label: 'Стул'),
    'URINATION' => const LogTypeSticker(emoji: '🚽', label: 'Мочеиспускание'),
    'VOMITING' => const LogTypeSticker(emoji: '🤮', label: 'Рвота'),
    'COUGHING' => const LogTypeSticker(emoji: '😮‍💨', label: 'Кашель'),
    'ITCHING' => const LogTypeSticker(emoji: '🐾', label: 'Зуд'),
    'PAIN_EPISODE' => const LogTypeSticker(emoji: '⚠️', label: 'Боль'),
    'SEIZURE_EPISODE' => const LogTypeSticker(emoji: '⚡', label: 'Судороги'),
    'MEDICATION' => const LogTypeSticker(emoji: '💊', label: 'Лекарство'),
    'RESPIRATORY_SYMPTOMS' =>
      const LogTypeSticker(emoji: '🫁', label: 'Дыхание'),
    _ => scope == LogTypeScope.system
        ? const LogTypeSticker(emoji: '🏷️', label: 'Системный')
        : scope == null
            ? const LogTypeSticker(emoji: '📝', label: 'Запись')
            : const LogTypeSticker(emoji: '✨', label: 'Мой'),
  };
}
