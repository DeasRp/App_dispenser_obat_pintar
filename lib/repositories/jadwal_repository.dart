import '../core/services/supabase_service.dart';
import '../models/jadwal_obat_model.dart';

/// Semua operasi CRUD jadwal obat & baca riwayat konsumsi lewat Supabase.
/// ESP32 membaca tabel yang sama lewat REST API secara terpisah, jadi
/// perubahan dari app ini akan otomatis diambil ESP32 saat sinkronisasi
/// berikutnya (atau langsung, kalau app juga mengirim perintah MQTT
/// 'medicine/cmd/sync_jadwal' setelah operasi berhasil).
class JadwalRepository {
  final _client = SupabaseService.client;

  Future<List<JadwalObatModel>> getJadwalByLansia(String lansiaId) async {
    final response = await _client
        .from('jadwal_obat')
        .select()
        .eq('lansia_id', lansiaId)
        .eq('aktif', true)
        .order('urutan_kompartemen', ascending: true);

    return (response as List)
        .map((item) => JadwalObatModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<JadwalObatModel> tambahJadwal(JadwalObatModel jadwal) async {
    final response = await _client
        .from('jadwal_obat')
        .insert(jadwal.toJson())
        .select()
        .single();

    return JadwalObatModel.fromJson(response);
  }

  Future<JadwalObatModel> updateJadwal(String id, JadwalObatModel jadwal) async {
    final response = await _client
        .from('jadwal_obat')
        .update(jadwal.toJson())
        .eq('id', id)
        .select()
        .single();

    return JadwalObatModel.fromJson(response);
  }

  /// Soft delete (nonaktifkan), bukan hapus permanen, supaya riwayat
  /// konsumsi lama yang mereferensikan jadwal ini tidak jadi anak yatim.
  Future<void> nonaktifkanJadwal(String id) async {
    await _client.from('jadwal_obat').update({'aktif': false}).eq('id', id);
  }

  /// Ambil satu baris riwayat konsumsi paling baru, untuk kartu
  /// "Last Medicine Taken" di dashboard.
  Future<RiwayatKonsumsiModel?> getRiwayatTerakhir(String lansiaId) async {
    final response = await _client
        .from('riwayat_konsumsi')
        .select('*, jadwal_obat!inner(lansia_id)')
        .eq('jadwal_obat.lansia_id', lansiaId)
        .order('waktu_diambil', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return RiwayatKonsumsiModel.fromJson(response);
  }

  Future<void> hapusJadwalPermanen(String id) async {
    await _client.from('jadwal_obat').delete().eq('id', id);
  }

  Future<List<RiwayatKonsumsiModel>> getRiwayat({
    required String lansiaId,
    int limit = 30,
  }) async {
    // riwayat_konsumsi tidak punya lansia_id langsung, jadi kita join
    // lewat jadwal_obat. Kalau Anda ingin query lebih sederhana, bisa
    // tambahkan kolom lansia_id di tabel riwayat_konsumsi juga.
    final response = await _client
        .from('riwayat_konsumsi')
        .select('*, jadwal_obat!inner(lansia_id)')
        .eq('jadwal_obat.lansia_id', lansiaId)
        .order('waktu_diambil', ascending: false)
        .limit(limit);

    return (response as List)
        .map((item) => RiwayatKonsumsiModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
