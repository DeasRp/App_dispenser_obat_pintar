import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/device_provider.dart';
import 'dashboard_screen.dart';
import 'kelola_jadwal_screen.dart';
import 'setting_screen.dart';

/// Shell utama dengan BottomNavigationBar.
/// Mengelola perpindahan antara Home (Dashboard), Jadwal, dan Setting.
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
    _NavItem(label: 'Setting', icon: Icons.settings_outlined, activeIcon: Icons.settings),
  ];

  static const List<String> _titles = [
    'Dispenser Obat Pintar',
    'Kelola Jadwal',
    'Pengaturan',
  ];

  @override
  Widget build(BuildContext context) {
    final deviceProvider = context.watch<DeviceProvider>();

    // Daftar halaman — dibangun di sini agar KelolaJadwalScreen
    // bisa mendapat argumen yang dibutuhkan dari provider.
    final List<Widget> pages = [
      const DashboardScreen(),
      KelolaJadwalScreen(
        lansiaId: deviceProvider.lansiaId,
        mqttService: deviceProvider.mqttService,
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
