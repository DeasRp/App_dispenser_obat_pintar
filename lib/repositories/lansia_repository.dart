import '../core/services/supabase_service.dart';

/// Model kecil khusus untuk field kontak & notifikasi di tabel lansia.
/// Dipakai oleh SettingScreen -- tidak menyentuh field lain (nama,
/// user_id, dll) supaya tidak overlap dengan repository lain.
class KontakLansiaModel {
  final String nama;
  final String noHpKeluarga;
  final String? noHpLansia;
  final String notifikasiTarget; // 'keluarga' | 'lansia'

  KontakLansiaModel({
    required this.nama,
    required this.noHpKeluarga,
    required this.noHpLansia,
    required this.notifikasiTarget,
  });

  factory KontakLansiaModel.fromJson(Map<String, dynamic> json) {
    return KontakLansiaModel(
      nama: json['nama'] as String? ?? '',
      noHpKeluarga: json['no_hp_keluarga'] as String? ?? '',
      noHpLansia: json['no_hp_lansia'] as String?,
      notifikasiTarget: json['notifikasi_target'] as String? ?? 'keluarga',
    );
  }
}

class LansiaRepository {
  final _client = SupabaseService.client;

  Future<KontakLansiaModel> getKontak(String lansiaId) async {
    final response = await _client
        .from('lansia')
        .select('nama, no_hp_keluarga, no_hp_lansia, notifikasi_target')
        .eq('id', lansiaId)
        .single();

    return KontakLansiaModel.fromJson(response);
  }

  Future<void> updateKontak({
    required String lansiaId,
    required String noHpKeluarga,
    required String? noHpLansia,
    required String notifikasiTarget,
  }) async {
    await _client.from('lansia').update({
      'no_hp_keluarga': noHpKeluarga,
      'no_hp_lansia': (noHpLansia == null || noHpLansia.isEmpty) ? null : noHpLansia,
      'notifikasi_target': notifikasiTarget,
    }).eq('id', lansiaId);
  }
}