import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/services/auth_service.dart';
import 'login_screen.dart';
import 'role_gate.dart';

/// Widget root autentikasi.
///
/// Belum login -> LoginScreen
/// Sudah login -> RoleGate -> profiles.role -> Lansia / Keluarga
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

        // Key berbasis user memastikan role/profile dimuat ulang ketika
        // akun yang aktif berubah.
        return RoleGate(key: ValueKey(userId));
      },
    );
  }
}
