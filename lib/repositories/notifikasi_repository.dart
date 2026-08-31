import '../core/services/supabase_service.dart';
import '../models/notifikasi_model.dart';

class NotifikasiRepository {
  final _client = SupabaseService.client;

  Future<List<NotifikasiModel>> getNotifikasi({
    required String lansiaId,
    int limit = 50,
  }) async {
    final response = await _client
        .from('notifikasi')
        .select()
        .eq('lansia_id', lansiaId)
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map((item) => NotifikasiModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> tandaiDibaca(String id) async {
    if (id.isEmpty) return;
    await _client.from('notifikasi').update({'dibaca': true}).eq('id', id);
  }

  Future<void> tandaiSemuaDibaca(String lansiaId) async {
    await _client
        .from('notifikasi')
        .update({'dibaca': true})
        .eq('lansia_id', lansiaId)
        .eq('dibaca', false);
  }
}
