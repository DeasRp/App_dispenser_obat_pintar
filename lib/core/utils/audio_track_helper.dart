import 'package:flutter/material.dart';

/// Menentukan nomor track audio DFPlayer secara otomatis berdasarkan jam
/// jadwal, supaya user tidak perlu pilih manual saat menambah jadwal.
///
/// Pastikan file di SD card DFPlayer sesuai urutan ini:
/// 0001.mp3 -> "Sudah waktunya minum obat pagi. Silakan letakkan gelas."
/// 0002.mp3 -> "Sudah waktunya minum obat siang. Silakan letakkan gelas."
/// 0003.mp3 -> "Sudah waktunya minum obat sore. Silakan letakkan gelas."
/// 0004.mp3 -> "Sudah waktunya minum obat malam. Silakan letakkan gelas."
/// 0005.mp3 -> "Jangan lupa minum obat sekarang. Silakan letakkan gelas."
int tentukanTrackAudio(TimeOfDay jam) {
  final totalMenit = jam.hour * 60 + jam.minute;

  const pagiMulai = 4 * 60;      // 04:00
  const siangMulai = 11 * 60;    // 11:00
  const soreMulai = 15 * 60;     // 15:00
  const malamMulai = 18 * 60;    // 18:00
  const diniHariMulai = 22 * 60; // 22:00

  if (totalMenit >= pagiMulai && totalMenit < siangMulai) {
    return 1; // Pagi
  } else if (totalMenit >= siangMulai && totalMenit < soreMulai) {
    return 2; // Siang
  } else if (totalMenit >= soreMulai && totalMenit < malamMulai) {
    return 3; // Sore
  } else if (totalMenit >= malamMulai && totalMenit < diniHariMulai) {
    return 4; // Malam
  } else {
    return 5; // Dini hari / fallback umum
  }
}