import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/device_provider.dart';
import 'dashboard_screen.dart';
import 'kelola_jadwal_screen.dart';
import 'monitoring_screen.dart';
import 'setting_screen.dart';

/// Shell utama dengan BottomNavigationBar.
/// Mengelola perpindahan antara Home (Dashboard), Jadwal, Monitoring, dan Setting.
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
    // Trigger koneksi MQTT + muat lansiaId sekali saat shell pertama kali
    // dibuka (setelah login). listen: false karena ini cuma memanggil
    // fungsi, bukan butuh rebuild saat provider berubah.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeviceProvider>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final deviceProvider = context.watch<DeviceProvider>();

    // Selama MqttService belum siap (init() masih berjalan), tampilkan
    // loading penuh -- mencegah KelolaJadwalScreen dibangun dengan
    // mqttService yang masih null.
    if (!deviceProvider.isSiap) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Daftar halaman — dibangun di sini agar KelolaJadwalScreen dan
    // MonitoringScreen bisa mendapat argumen yang dibutuhkan dari provider.
    final List<Widget> pages = [
      const DashboardScreen(),
      KelolaJadwalScreen(
        lansiaId: deviceProvider.lansiaId,
        mqttService: deviceProvider.mqttService!,
      ),
      MonitoringScreen(
        lansiaId: deviceProvider.lansiaId,
      ),
      const SettingScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        centerTitle: false,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
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

/// Data class kecil untuk item navigasi.
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