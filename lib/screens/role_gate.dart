import 'package:flutter/material.dart';

import '../core/services/auth_service.dart';
import '../core/theme/app_theme.dart';
import 'main_shell.dart';

/// Menentukan tampilan utama berdasarkan `profiles.role`.
///
/// Baik Lansia maupun Keluarga masuk ke MainShell.
/// Perbedaan cara mendapatkan `lansia_id` ditangani oleh DeviceProvider:
/// - Lansia   -> lansia.user_id = auth.uid()
/// - Keluarga -> keluarga_lansia.keluarga_user_id = auth.uid()
class RoleGate extends StatefulWidget {
  const RoleGate({super.key});

  @override
  State<RoleGate> createState() => _RoleGateState();
}

class _RoleGateState extends State<RoleGate> {
  final _authService = AuthService();
  late Future<AppProfile?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  Future<AppProfile?> _loadProfile() async {
    await _authService.ensureLansiaRecord();
    return _authService.getCurrentProfile();
  }

  void _retry() {
    setState(() {
      _profileFuture = _loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppProfile?>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Gagal memuat profil akun.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _retry,
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final profile = snapshot.data;
        if (profile == null) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_off_outlined, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'Profil akun belum tersedia di database.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () async => _authService.keluar(),
                      child: const Text('Keluar'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return const MainShell();
      },
    );
  }
}
