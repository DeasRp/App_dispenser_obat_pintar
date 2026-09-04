import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/services/auth_service.dart';
import '../core/services/csv_export_service.dart';
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
  bool _isExportingCsv = false;
  final _csvExportService = CsvExportService();

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

    // Sinkronkan badge setelah pengguna membaca notifikasi.
    await deviceProvider.refreshUnreadNotifications();
  }

  Widget _buildNotificationBell(DeviceProvider deviceProvider) {
    final count = deviceProvider.unreadNotificationCount;
    final label = count > 99 ? '99+' : '$count';

    return IconButton(
      tooltip: count > 0 ? '$count notifikasi belum dibaca' : 'Notifikasi',
      onPressed: () => _bukaNotifikasi(deviceProvider),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_outlined),
          if (count > 0)
            Positioned(
              right: -8,
              top: -7,
              child: Container(
                constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surface,
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onError,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _eksporCsv(DeviceProvider deviceProvider, int hari) async {
    if (_isExportingCsv || deviceProvider.lansiaId.isEmpty) return;

    setState(() => _isExportingCsv = true);

    try {
      final jumlah = await _csvExportService.exportRiwayatKonsumsi(
        lansiaId: deviceProvider.lansiaId,
        hari: hari,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$jumlah data riwayat berhasil disiapkan dalam format CSV.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final pesan = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengekspor CSV: $pesan')),
      );
    } finally {
      if (mounted) setState(() => _isExportingCsv = false);
    }
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

    final tampilkanEksporCsv =
        deviceProvider.isKeluarga && _selectedIndex == 2;

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
          if (tampilkanEksporCsv)
            _isExportingCsv
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : PopupMenuButton<int>(
                    tooltip: 'Ekspor riwayat CSV',
                    icon: const Icon(Icons.download_outlined),
                    onSelected: (hari) => _eksporCsv(deviceProvider, hari),
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 7,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.table_view_outlined),
                          title: Text('Ekspor CSV 7 hari'),
                        ),
                      ),
                      PopupMenuItem(
                        value: 30,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.table_view_outlined),
                          title: Text('Ekspor CSV 30 hari'),
                        ),
                      ),
                    ],
                  ),
          _buildNotificationBell(deviceProvider),
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
