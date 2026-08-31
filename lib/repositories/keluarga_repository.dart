import '../core/services/supabase_service.dart';

class KeluargaRepository {
  final _client = SupabaseService.client;

  /// Menghubungkan akun keluarga yang sedang login dengan akun Lansia
  /// berdasarkan email. Pencarian email dilakukan di sisi database melalui
  /// RPC SECURITY DEFINER sehingga Flutter tidak perlu dan tidak boleh
  /// membaca auth.users secara langsung.
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
}
