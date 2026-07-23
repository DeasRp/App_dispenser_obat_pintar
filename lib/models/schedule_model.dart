
// Enum untuk status jadwal harian
enum ScheduleStatus {
  sudahDiambil,
  menunggu,
  terjadwal,
}

// Enum untuk status gelas
enum GlassStatus {
  kosong,
  terisi,
}

// Model untuk data jadwal berikutnya
class NextSchedule {
  final String jam;
  final String namaObat;
  final String jumlah;

  NextSchedule({
    required this.jam,
    required this.namaObat,
    required this.jumlah,
  });
}

// Model untuk data jadwal hari ini
class TodaySchedule {
  final String jam;
  final String namaObat;
  final ScheduleStatus status;

  TodaySchedule({
    required this.jam,
    required this.namaObat,
    required this.status,
  });
}
