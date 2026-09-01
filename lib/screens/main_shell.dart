import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/services/auth_service.dart';
import '../providers/device_provider.dart';
import 'dashboard_screen.dart';
import 'hubungkan_lansia_screen.dart';
import 'kelola_jadwal_screen.dart';
import 'monitoring_screen.dart';
import 'notifikasi_screen.dart';
import 'setting_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  static const List<_NavItem> _navItems = [
    _NavItem(label: 'Home', icon: Icons.home_outlined, activeIcon: Icons.home),
    _NavItem(label: 'Jadwal', icon: Icons.calendar_month_outlined, activeIcon: Icons.calendar_month),
    _NavItem(label: 'Monitoring', icon: Icons.analytics_outlined, activeIcon: Icons.analytics),
    _NavItem(label: 'Setting', icon: Icons.settings_outlined, activeIcon: Icons.settings),
  ];

  static const List<String> _titles = [
    'Dispenser Obat Pintar',
    'Kelola Jadwal',
    'Monitoring',
    'Pengaturan',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeviceProvider>().init();
    });
  }

  Future<void> _bukaPairing(DeviceProvider deviceProvider) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HubungkanLansiaScreen(
          onTerhubung: deviceProvider.refreshLansiaConnection,
        ),
      ),
    );
  }

  Future<void> _bukaNotifikasi(DeviceProvider deviceProvider) async {
    if (deviceProvider.lansiaId.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotifikasiScreen(lansiaId: deviceProvider.lansiaId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deviceProvider = context.watch<DeviceProvider>();

    if (deviceProvider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Hanya error Auth/Supabase inti yang memblokir aplikasi.
    // Kegagalan MQTT/ESP32 tidak masuk ke errorMessage.
    if (deviceProvider.errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Remindora')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 52),
                const SizedBox(height: 16),
                Text(deviceProvider.errorMessage!, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => deviceProvider.init(),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (deviceProvider.isKeluarga &&
        !deviceProvider.sudahTerhubungDenganLansia) {
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
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.link_off, size: 72),
                  const SizedBox(height: 20),
                  const Text(
                    'Akun belum terhubung dengan Lansia',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Masukkan email akun Lansia untuk menghubungkan akun keluarga dengan dispenser yang dipantau.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => _bukaPairing(deviceProvider),
                    icon: const Icon(Icons.link),
                    label: const Text('Hubungkan dengan Email Lansia'),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: () => deviceProvider.refreshLansiaConnection(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Periksa Ulang Koneksi'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (!deviceProvider.sudahTerhubungDenganLansia) {
      return Scaffold(
        appBar: AppBar(title: const Text('Remindora')),
        body: const Center(
          child: Text('Data Lansia belum tersedia untuk akun ini.'),
        ),
      );
    }

    // Semua halaman berikut hanya membutuhkan lansiaId/Supabase.
    // MQTT boleh null/offline.
    final pages = <Widget>[
      const DashboardScreen(),
      KelolaJadwalScreen(lansiaId: deviceProvider.lansiaId),
      MonitoringScreen(lansiaId: deviceProvider.lansiaId),
      SettingScreen(lansiaId: deviceProvider.lansiaId),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        centerTitle: false,
        actions: [
          if (!deviceProvider.isMqttConnected)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Tooltip(
                message: 'Dispenser offline — data Supabase tetap tersedia',
                child: Icon(Icons.cloud_off_outlined, size: 20),
              ),
            ),
          IconButton(
            tooltip: 'Notifikasi',
            onPressed: () => _bukaNotifikasi(deviceProvider),
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: _navItems
            .map(
              (item) => NavigationDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.activeIcon),
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}
