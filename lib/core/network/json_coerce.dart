/// Tolerant JSON readers. The legacy catalogue behind the API returns some
/// numbers as strings ("12") as often as numbers (12), so models read every
/// field through these instead of casting — one odd row must not blank a page.
library;

int jsonInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

double jsonDouble(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

String jsonString(Object? value) => value?.toString() ?? '';
