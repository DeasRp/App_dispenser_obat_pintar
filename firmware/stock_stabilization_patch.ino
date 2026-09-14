// Patch stabilisasi stok untuk firmware ESP32 ObatKu.
// Terapkan bagian ini pada firmware utama dispenser.
// Acuan stok penuh: 30 gram.

const float BERAT_STOK_PENUH_GRAM = 30.0;
const int STOK_SAVE_CHANGE_PERSEN = 5;
const unsigned long STOK_SAVE_MIN_INTERVAL = 20UL * 1000UL;

// Membaca berat dengan averaging lebih banyak agar noise HX711 berkurang.
float bacaBeratStokGram() {
  if (!timbangan.is_ready()) return -1;

  float gram = timbangan.get_units(20);

  // Hilangkan drift kecil di sekitar nol.
  if (gram > -0.25f && gram < 0.25f) {
    gram = 0.0f;
  }

  return gram;
}

// Hysteresis 3% agar nilai visual tidak berubah karena noise kecil.
int bacaPersenStok() {
  static int persenStabil = -1;

  float gram = bacaBeratStokGram();
  if (gram < 0) return -1;

  int persenBaru = constrain(
    (int)round((gram / BERAT_STOK_PENUH_GRAM) * 100.0f),
    0,
    100
  );

  if (persenStabil < 0 || abs(persenBaru - persenStabil) >= 3) {
    persenStabil = persenBaru;
  }

  return persenStabil;
}

// Gunakan fungsi ini pada kirimRiwayatStokKeSupabase() agar nilai yang
// disimpan sama dengan persentase stabil yang dikirim ke aplikasi.
int bacaPersenStokUntukRiwayat() {
  return bacaPersenStok();
}

// Pada fungsi simpanRiwayatStokJikaBerubah(), gunakan threshold berikut:
// abs(persenSekarang - lastSavedStockPercent) >= STOK_SAVE_CHANGE_PERSEN
// dan cooldown:
// millis() - lastStockChangeSave >= STOK_SAVE_MIN_INTERVAL
//
// Pada loop(), publishStock() tetap dapat dijalankan setiap 5 detik.
