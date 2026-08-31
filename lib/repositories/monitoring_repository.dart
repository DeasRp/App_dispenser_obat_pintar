import '../core/services/supabase_service.dart';
import '../models/monitoring_model.dart';

/// Repository monitoring setelah migrasi schema Supabase.
///
/// `riwayat_konsumsi` sekarang menyimpan `lansia_id` langsung dan ESP32
/// juga mencatat status `terlewat`. Karena itu monitoring tidak perlu lagi
/// join ke `jadwal_obat` atau mengestimasi jumlah jadwal yang terlewat.
class MonitoringRepository {
  final _client = SupabaseService.client;

  Future<List<RiwayatStokModel>> getHistoriStok({
    required String lansiaId,
    int hariTerakhir = 30,
  }) async {
    final sejak = DateTime.now().subtract(Duration(days: hariTerakhir));

    final response = await _client
        .from('riwayat_stok')
        .select('persen, created_at')
        .eq('lansia_id', lansiaId)
        .gte('created_at', sejak.toIso8601String())
        .order('created_at', ascending: true);

    return (response as List)
        .map((item) => RiwayatStokModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Grafik jumlah obat yang benar-benar diambil per hari.
  ///
  /// Hanya status `diambil` yang masuk grafik. Untuk baris ini
  /// `waktu_diambil` seharusnya terisi, tetapi tetap dicek null agar aman.
  Future<List<FrekuensiHarianModel>> getFrekuensiPengambilan({
    required String lansiaId,
    required RentangWaktu rentang,
  }) async {
    final hari = rentang == RentangWaktu.mingguan ? 7 : 30;
    final sejak = DateTime.now().subtract(Duration(days: hari));

    final response = await _client
        .from('riwayat_konsumsi')
        .select('waktu_diambil, status, created_at')
        .eq('lansia_id', lansiaId)
        .eq('status', 'diambil')
        .gte('created_at', sejak.toIso8601String())
        .order('created_at', ascending: true);

    final rows = response as List;

    final Map<String, int> hitungPerTanggal = {};

    for (final row in rows) {
      final waktuRaw = row['waktu_diambil'] as String?;
      if (waktuRaw == null || waktuRaw.isEmpty) continue;

      final waktu = DateTime.parse(waktuRaw).toLocal();
      final key = '${waktu.year}-${waktu.month}-${waktu.day}';
      hitungPerTanggal[key] = (hitungPerTanggal[key] ?? 0) + 1;
    }

    final hasil = <FrekuensiHarianModel>[];

    for (int i = hari - 1; i >= 0; i--) {
      final tanggal = DateTime.now().subtract(Duration(days: i));
      final key = '${tanggal.year}-${tanggal.month}-${tanggal.day}';

      hasil.add(
        FrekuensiHarianModel(
          tanggal: DateTime(tanggal.year, tanggal.month, tanggal.day),
          jumlahDiambil: hitungPerTanggal[key] ?? 0,
        ),
      );
    }

    return hasil;
  }

  /// Hitung kepatuhan langsung dari status riwayat aktual yang dicatat ESP32.
  ///
  /// Status yang dikenali:
  /// - `diambil`
  /// - `terlewat`
  /// - `gagal_verifikasi`
  Future<KepatuhanModel> getKepatuhan({
    required String lansiaId,
    required RentangWaktu rentang,
  }) async {
    final hari = rentang == RentangWaktu.mingguan ? 7 : 30;
    final sejak = DateTime.now().subtract(Duration(days: hari));

    final response = await _client
        .from('riwayat_konsumsi')
        .select('status, created_at')
        .eq('lansia_id', lansiaId)
        .gte('created_at', sejak.toIso8601String());

    final rows = response as List;

    int diambil = 0;
    int terlewat = 0;
    int gagalVerifikasi = 0;

    for (final row in rows) {
      final status = row['status'] as String? ?? '';

      switch (status) {
        case 'diambil':
          diambil++;
          break;
        case 'terlewat':
          terlewat++;
          break;
        case 'gagal_verifikasi':
          gagalVerifikasi++;
          break;
      }
    }

    return KepatuhanModel(
      diambil: diambil,
      gagalVerifikasi: gagalVerifikasi,
      terlewat: terlewat,
    );
  }
}
