import '../core/services/supabase_service.dart';
import '../models/monitoring_model.dart';

/// Catatan penting soal "terlewat":
/// Tabel riwayat_konsumsi hanya diisi ESP32 saat proses dispense benar-benar
/// berjalan (status 'diambil' atau 'gagal_verifikasi'). Jadwal yang sama
/// sekali tidak dipicu (misal alat mati saat jam jadwal) TIDAK punya baris
/// di riwayat_konsumsi sama sekali, sehingga "terlewat" tidak bisa dihitung
/// langsung dari tabel ini -- perlu dibandingkan dengan jumlah jadwal aktif
/// yang seharusnya terjadi di rentang waktu tersebut. Implementasi di bawah
/// ini melakukan estimasi tersebut secara sederhana.
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

  Future<List<FrekuensiHarianModel>> getFrekuensiPengambilan({
    required String lansiaId,
    required RentangWaktu rentang,
  }) async {
    final hari = rentang == RentangWaktu.mingguan ? 7 : 30;
    final sejak = DateTime.now().subtract(Duration(days: hari));

    final response = await _client
        .from('riwayat_konsumsi')
        .select('waktu_diambil, status, jadwal_obat!inner(lansia_id)')
        .eq('jadwal_obat.lansia_id', lansiaId)
        .eq('status', 'diambil')
        .gte('waktu_diambil', sejak.toIso8601String())
        .order('waktu_diambil', ascending: true);

    final rows = response as List;

    // Kelompokkan per tanggal (tanpa jam)
    final Map<String, int> hitungPerTanggal = {};
    for (final row in rows) {
      final waktu = DateTime.parse(row['waktu_diambil'] as String);
      final key = '${waktu.year}-${waktu.month}-${waktu.day}';
      hitungPerTanggal[key] = (hitungPerTanggal[key] ?? 0) + 1;
    }

    // Isi semua tanggal dalam rentang, termasuk yang 0, biar grafik rapi
    final hasil = <FrekuensiHarianModel>[];
    for (int i = hari - 1; i >= 0; i--) {
      final tanggal = DateTime.now().subtract(Duration(days: i));
      final key = '${tanggal.year}-${tanggal.month}-${tanggal.day}';
      hasil.add(FrekuensiHarianModel(
        tanggal: DateTime(tanggal.year, tanggal.month, tanggal.day),
        jumlahDiambil: hitungPerTanggal[key] ?? 0,
      ));
    }
    return hasil;
  }

  Future<KepatuhanModel> getKepatuhan({
    required String lansiaId,
    required RentangWaktu rentang,
  }) async {
    final hari = rentang == RentangWaktu.mingguan ? 7 : 30;
    final sejak = DateTime.now().subtract(Duration(days: hari));

    // 1. Hitung status aktual dari riwayat_konsumsi
    final response = await _client
        .from('riwayat_konsumsi')
        .select('status, jadwal_obat!inner(lansia_id)')
        .eq('jadwal_obat.lansia_id', lansiaId)
        .gte('waktu_diambil', sejak.toIso8601String());

    final rows = response as List;
    int diambil = 0;
    int gagalVerifikasi = 0;
    for (final row in rows) {
      final status = row['status'] as String;
      if (status == 'diambil') diambil++;
      if (status == 'gagal_verifikasi') gagalVerifikasi++;
    }

    // 2. Estimasi jumlah jadwal yang SEHARUSNYA terjadi di rentang ini,
    // untuk menghitung berapa yang "terlewat" (tidak ada baris riwayat
    // sama sekali karena alat tidak sempat memprosesnya).
    final jadwalResponse = await _client
        .from('jadwal_obat')
        .select('id')
        .eq('lansia_id', lansiaId)
        .eq('aktif', true);

    final jumlahJadwalAktif = (jadwalResponse as List).length;
    final ekspektasiTotal = jumlahJadwalAktif * hari;
    final aktualTotal = diambil + gagalVerifikasi;
    final terlewat = (ekspektasiTotal - aktualTotal).clamp(0, ekspektasiTotal);

    return KepatuhanModel(
      diambil: diambil,
      gagalVerifikasi: gagalVerifikasi,
      terlewat: terlewat,
    );
  }
}
