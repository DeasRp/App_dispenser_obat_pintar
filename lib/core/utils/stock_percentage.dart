const double fullMedicineStockGrams = 30.0;

/// Mengubah berat stok obat (gram) menjadi persentase 0-100.
///
/// Kapasitas penuh dispenser adalah 6 kompartemen x 5 gram = 30 gram.
int calculateStockPercentage(num weightGrams) {
  final percentage = (weightGrams.toDouble() / fullMedicineStockGrams * 100)
      .round();
  return percentage.clamp(0, 100).toInt();
}

/// Membaca persentase stok dari payload MQTT.
///
/// Format utama yang disarankan: {"weight": 30}. Beberapa nama field berat
/// alternatif tetap diterima agar kompatibel dengan firmware yang sudah ada.
/// Payload lama {"percent": 100} juga masih didukung.
int stockPercentageFromPayload(Map<String, dynamic> data) {
  const weightKeys = <String>[
    'weight',
    'weight_grams',
    'grams',
    'gram',
    'berat',
    'berat_gram',
  ];

  for (final key in weightKeys) {
    final weight = _parseNumber(data[key]);
    if (weight != null) return calculateStockPercentage(weight);
  }

  final percent = _parseNumber(data['percent']);
  return (percent ?? 0).round().clamp(0, 100).toInt();
}

num? _parseNumber(dynamic value) {
  if (value is num) return value;
  if (value is String) return num.tryParse(value.replaceAll(',', '.'));
  return null;
}
