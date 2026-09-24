const double fullMedicineStockGrams = 30.0;
const int stockDisplayStepPercent = 5;

/// Mengubah berat stok obat (gram) menjadi persentase 0-100.
///
/// Kapasitas penuh stok dispenser ditetapkan 30 gram. Carousel memiliki
/// 5 kompartemen obat; berat tiap kompartemen dapat berbeda selama total
/// stok penuh tetap menggunakan acuan 30 gram.
int calculateStockPercentage(num weightGrams) {
  final percentage = (weightGrams.toDouble() / fullMedicineStockGrams * 100)
      .round();
  return percentage.clamp(0, 100).toInt();
}

/// Mengubah persentase stok menjadi perkiraan berat dalam gram.
double calculateStockWeightFromPercentage(num percent) {
  final clamped = percent.toDouble().clamp(0, 100);
  return clamped / 100 * fullMedicineStockGrams;
}

/// Membuat nilai persentase MQTT lebih tenang untuk kebutuhan visual UI.
/// Firmware sudah melakukan averaging + hysteresis; pembulatan ke kelipatan
/// 5% di sisi aplikasi menjadi lapisan kedua agar badge/grafik tidak berkedip
/// akibat perubahan kecil load cell.
int stabilizeStockDisplayPercent(num percent) {
  final clamped = percent.round().clamp(0, 100).toInt();
  if (clamped == 0 || clamped == 100) return clamped;

  final stable =
      (clamped / stockDisplayStepPercent).round() * stockDisplayStepPercent;
  return stable.clamp(0, 100).toInt();
}

/// Membaca berat stok dari payload MQTT dalam gram.
///
/// Format utama yang disarankan: {"weight": 30}. Beberapa nama field berat
/// alternatif tetap diterima agar kompatibel dengan firmware yang sudah ada.
/// Jika firmware hanya mengirim percent, nilai gram dihitung dari kapasitas
/// penuh 30 gram sebagai fallback.
double stockWeightGramsFromPayload(Map<String, dynamic> data) {
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
    if (weight != null) {
      return weight.toDouble().clamp(0, fullMedicineStockGrams);
    }
  }

  final percent = _parseNumber(data['percent']);
  return calculateStockWeightFromPercentage(percent ?? 0);
}

/// Membaca persentase stok dari payload MQTT.
///
/// Format utama yang disarankan: {"weight": 30}. Beberapa nama field berat
/// alternatif tetap diterima agar kompatibel dengan firmware yang sudah ada.
/// Payload {"percent": 100} dari firmware juga didukung dan distabilkan
/// untuk tampilan aplikasi.
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
    if (weight != null) {
      return stabilizeStockDisplayPercent(calculateStockPercentage(weight));
    }
  }

  final percent = _parseNumber(data['percent']);
  return stabilizeStockDisplayPercent(percent ?? 0);
}

num? _parseNumber(dynamic value) {
  if (value is num) return value;
  if (value is String) return num.tryParse(value.replaceAll(',', '.'));
  return null;
}
