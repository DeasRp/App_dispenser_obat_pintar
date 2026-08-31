import 'package:flutter/material.dart';
import '../core/services/auth_service.dart';
import '../core/theme/app_theme.dart';
import 'main_shell.dart';

/// Menentukan tampilan utama berdasarkan `profiles.role`.
///
/// Tahap migrasi auth/role:
/// - Lansia masuk ke MainShell yang sudah ada.
/// - Keluarga diarahkan ke placeholder khusus sampai alur pairing
///   `keluarga_lansia` selesai pada tahap berikutnya.
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
                    const Icon(Icons.error_outline, size: 48, color: AppColors.error),
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

        if (profile.role == UserRole.lansia) {
          return const MainShell();
        }

        return _KeluargaLanding(profile: profile);
      },
    );
  }
}

class _KeluargaLanding extends StatelessWidget {
  final AppProfile profile;

  const _KeluargaLanding({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Remindora Keluarga'),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            onPressed: () async => AuthService().keluar(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.family_restroom,
                  size: 72,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  'Halo, ${profile.nama}',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Akun Anda terdaftar sebagai Keluarga. Tahap berikutnya adalah menghubungkan akun ini dengan Lansia melalui tabel keluarga_lansia / kode pairing.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
