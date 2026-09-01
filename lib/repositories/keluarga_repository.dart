import '../core/services/supabase_service.dart';

class LansiaTerhubungModel {
  final String lansiaId;
  final String nama;
  final String email;

  const LansiaTerhubungModel({
    required this.lansiaId,
    required this.nama,
    required this.email,
  });

  factory LansiaTerhubungModel.fromJson(Map<String, dynamic> json) {
    return LansiaTerhubungModel(
      lansiaId: json['lansia_id'] as String,
      nama: json['nama'] as String? ?? 'Lansia',
      email: json['email'] as String? ?? '-',
    );
  }
}

class KeluargaRepository {
  final _client = SupabaseService.client;

  Future<String> hubungkanDenganEmailLansia(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
      throw Exception('Email Lansia wajib diisi.');
    }

    final response = await _client.rpc(
      'hubungkan_lansia_dengan_email',
      params: {'p_email': normalizedEmail},
    );

    if (response == null) {
      throw Exception('Gagal menghubungkan akun dengan Lansia.');
    }

    return response.toString();
  }

  Future<LansiaTerhubungModel?> getLansiaTerhubung() async {
    final response = await _client.rpc('get_lansia_terhubung');

    if (response is! List || response.isEmpty) return null;
    return LansiaTerhubungModel.fromJson(
      Map<String, dynamic>.from(response.first as Map),
    );
  }

  Future<void> putuskanHubungan(String lansiaId) async {
    final response = await _client.rpc(
      'putuskan_hubungan_lansia',
      params: {'p_lansia_id': lansiaId},
    );

    if (response != true) {
      throw Exception('Hubungan dengan Lansia tidak ditemukan.');
    }
  }
}
