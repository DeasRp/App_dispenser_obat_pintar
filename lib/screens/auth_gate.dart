import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/services/auth_service.dart';
import 'login_screen.dart';
import 'main_shell.dart';

/// Widget ini dipasang sebagai `home:` di MaterialApp.
/// Otomatis menampilkan LoginScreen kalau belum login, atau
/// MainShell (dengan bottom nav) kalau sudah login -- dan berpindah
/// otomatis setiap kali status auth berubah (login/logout/token refresh).
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<AuthState>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        final sudahLogin = authService.isLoggedIn;
        final userId = authService.currentUser?.id;

        if (!sudahLogin) {
          return const LoginScreen();
        }

        // PENTING: key berbasis userId memaksa Flutter membuat instance
        // MainShell baru (State + initState terpanggil ulang) setiap kali
        // user yang login berganti -- misalnya saat daftar akun baru tanpa
        // logout eksplisit dulu, di mana Supabase langsung mengganti sesi.
        // Tanpa key ini, MainShell dianggap widget yang sama sehingga
        // deviceProvider.init() tidak pernah dipanggil ulang, dan data
        // akun lama (terutama dari MQTT) tetap tersisa di layar.
        return MainShell(key: ValueKey(userId));
      },
    );
  }
}