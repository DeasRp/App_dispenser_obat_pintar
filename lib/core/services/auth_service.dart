import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

enum UserRole { lansia, keluarga }

class AppProfile {
  final String id;
  final String nama;
  final UserRole role;
  final String? noHp;

  const AppProfile({
    required this.id,
    required this.nama,
    required this.role,
    this.noHp,
  });

  factory AppProfile.fromJson(Map<String, dynamic> json) {
    final roleText = json['role'] as String? ?? 'lansia';
    return AppProfile(
      id: json['id'] as String,
      nama: json['nama'] as String? ?? '',
      role: roleText == 'keluarga' ? UserRole.keluarga : UserRole.lansia,
      noHp: json['no_hp'] as String?,
    );
  }
}

/// Wrapper autentikasi + profile aplikasi.
///
/// Supabase Auth menangani email/password, sedangkan tabel `profiles`
/// menyimpan identitas aplikasi dan role (`lansia` / `keluarga`).
class AuthService {
  final _client = SupabaseService.client;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  User? get currentUser => _client.auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  Future<AuthResponse> daftar({
    required String email,
    required String password,
    required String nama,
    required UserRole role,
    String? noHp,
  }) async {
    final roleText = role == UserRole.keluarga ? 'keluarga' : 'lansia';

    return _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'nama': nama.trim(),
        'role': roleText,
        'no_hp': noHp?.trim() ?? '',
      },
    );
  }

  Future<AuthResponse> masuk({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    // Untuk akun lansia, pastikan baris `lansia` tersedia. Ini juga
    // menangani signup dengan email confirmation, saat insert langsung
    // setelah signUp belum bisa dilakukan karena belum ada session aktif.
    await ensureLansiaRecord();
    return response;
  }

  Future<AppProfile?> getCurrentProfile() async {
    final user = currentUser;
    if (user == null) return null;

    final response = await _client
        .from('profiles')
        .select('id, nama, role, no_hp')
        .eq('id', user.id)
        .maybeSingle();

    if (response == null) return null;
    return AppProfile.fromJson(response);
  }

  Future<UserRole?> getCurrentRole() async {
    final profile = await getCurrentProfile();
    return profile?.role;
  }

  /// Membuat data domain `lansia` untuk akun ber-role lansia jika belum ada.
  /// Akun keluarga tidak membuat baris `lansia`; keterhubungannya nanti
  /// melalui tabel `keluarga_lansia`.
  Future<void> ensureLansiaRecord() async {
    final user = currentUser;
    if (user == null) return;

    final profile = await getCurrentProfile();
    if (profile == null || profile.role != UserRole.lansia) return;

    final existing = await _client
        .from('lansia')
        .select('id')
        .eq('user_id', user.id)
        .maybeSingle();

    if (existing != null) return;

    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final noHp = (profile.noHp ?? metadata['no_hp'] as String? ?? '').trim();

    await _client.from('lansia').insert({
      'user_id': user.id,
      'nama': profile.nama.isNotEmpty ? profile.nama : 'Pengguna',
      // Schema lama masih mewajibkan no_hp_keluarga NOT NULL.
      // Untuk lansia yang hidup mandiri, nomor akun sendiri dipakai sebagai
      // fallback sampai pengaturan kontak diperbarui.
      'no_hp_keluarga': noHp,
      'no_hp_lansia': noHp.isEmpty ? null : noHp,
      'notifikasi_target': 'lansia',
    });
  }

  Future<void> keluar() async {
    await _client.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }
}
