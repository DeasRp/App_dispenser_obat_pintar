import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Wrapper untuk semua operasi autentikasi (register, login, logout)
/// menggunakan Supabase Auth dengan metode email + password.
class AuthService {
  final _client = SupabaseService.client;

  /// Stream ini emit setiap kali status login berubah (login/logout).
  /// Dipakai oleh AuthGate untuk otomatis pindah screen.
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  User? get currentUser => _client.auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  Future<AuthResponse> daftar({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signUp(email: email, password: password);
  }

  Future<AuthResponse> masuk({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> keluar() async {
    await _client.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }
}
