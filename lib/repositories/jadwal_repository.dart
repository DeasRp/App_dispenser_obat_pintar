import '../core/services/supabase_service.dart';
import '../models/jadwal_obat_model.dart';

/// Semua operasi CRUD jadwal obat dan riwayat konsumsi lewat Supabase.
///
/// Setelah migrasi, `riwayat_konsumsi` sudah mempunyai `lansia_id`
/// langsung. Karena itu query riwayat tidak perlu lagi join ke
/// `jadwal_obat` hanya untuk menentukan pemilik data.
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

  Future<JadwalObatModel> updateJadwal(
    String id,
    JadwalObatModel jadwal,
  ) async {
    final response = await _client
        .from('jadwal_obat')
        .update(jadwal.toJson())
        .eq('id', id)
        .select()
        .single();

    return JadwalObatModel.fromJson(response);
  }

  /// Soft delete agar riwayat lama tetap memiliki referensi jadwal.
  Future<void> nonaktifkanJadwal(String id) async {
    await _client
        .from('jadwal_obat')
        .update({'aktif': false})
        .eq('id', id);
  }

  /// Ambil riwayat paling baru milik Lansia.
  ///
  /// Menggunakan `created_at` karena pada status `terlewat`,
  /// `waktu_diambil` memang boleh NULL.
  Future<RiwayatKonsumsiModel?> getRiwayatTerakhir(String lansiaId) async {
    final response = await _client
        .from('riwayat_konsumsi')
        .select()
        .eq('lansia_id', lansiaId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return RiwayatKonsumsiModel.fromJson(response);
  }

  Future<void> hapusJadwalPermanen(String id) async {
    await _client.from('jadwal_obat').delete().eq('id', id);
  }

  /// Ambil daftar riwayat konsumsi berdasarkan `lansia_id` langsung.
  Future<List<RiwayatKonsumsiModel>> getRiwayat({
    required String lansiaId,
    int limit = 30,
  }) async {
    final response = await _client
        .from('riwayat_konsumsi')
        .select()
        .eq('lansia_id', lansiaId)
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map(
          (item) => RiwayatKonsumsiModel.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }
}
