String formatDisplayUnitCode(String? unitCode) {
  final raw = unitCode?.trim();
  if (raw == null || raw.isEmpty) {
    return '';
  }

  return switch (raw.toLowerCase()) {
    'kg' => 'кг',
    'g' => 'г',
    'mg' => 'мг',
    'mcg' => 'мкг',
    'ml' => 'мл',
    'l' => 'л',
    'cm' => 'см',
    'mm' => 'мм',
    'm' => 'м',
    'h' => 'ч',
    'c' || '°c' || 'degc' => '°C',
    'f' || '°f' || 'degf' => '°F',
    'bpm' => 'уд/мин',
    'rpm' => 'дых/мин',
    'count' => 'раз',
    '%' => '%',
    _ => raw,
  };
}
