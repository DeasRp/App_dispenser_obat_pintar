
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/services/auth_service.dart';
import '../providers/device_provider.dart';
import '../widgets/connection_status_banner.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/next_schedule_card.dart';
import '../widgets/stock_status_card.dart';
import '../widgets/glass_status_card.dart';
import '../widgets/today_schedule_list.dart';

// Halaman utama / Dashboard Aplikasi
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  // Fungsi untuk menampilkan dialog konfirmasi sebelum dispense manual
  void _showDispenseConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Konfirmasi"),
          content: const Text(
              "Apakah Anda yakin ingin mengeluarkan obat secara manual?"),
          actions: <Widget>[
            TextButton(
              child: const Text("Batal"),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Tutup dialog
              },
            ),
            FilledButton(
              child: const Text("Ya, Keluarkan"),
              onPressed: () {
                // Panggil provider untuk mengirim perintah
                // `listen: false` karena kita hanya memanggil fungsi, tidak perlu rebuild
                context.read<DeviceProvider>().publishDispenseCommand();
                Navigator.of(dialogContext).pop(); // Tutup dialog

                // Tampilkan notifikasi (opsional)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Perintah mengeluarkan obat dikirim..."),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // Fungsi untuk menampilkan dialog konfirmasi sebelum logout
  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Keluar Akun"),
          content: const Text("Apakah Anda yakin ingin keluar dari aplikasi?"),
          actions: <Widget>[
            TextButton(
              child: const Text("Batal"),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text("Ya, Keluar"),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await AuthService().signOut();
                // AuthGate akan otomatis redirect ke LoginScreen
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Menggunakan Consumer untuk mendapatkan data dari provider dan
    // rebuild widget ketika data berubah.
    return Consumer<DeviceProvider>(
      builder: (context, deviceProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text("Dispenser Obat Pintar"),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: "Logout",
                onPressed: () => _showLogoutConfirmationDialog(context),
              ),
            ],
          ),
          // SafeArea memastikan konten tidak terpotong oleh notch/statusbar
          body: SafeArea(
            child: RefreshIndicator(
              // Pull-to-refresh akan memanggil fungsi ini
              onRefresh: deviceProvider.refreshDeviceStatus,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                // Padding horizontal untuk seluruh layar
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // 1. Header: Sapaan + Nama Lansia
                    DashboardHeader(namaLansia: deviceProvider.status.namaLansia),
                    const SizedBox(height: 8),

                    // 2. Banner Status Koneksi
                    ConnectionStatusBanner(
                      isLoading: deviceProvider.isLoading,
                      isOnline: deviceProvider.status.isDeviceOnline,
                      statusText: deviceProvider.status.wifiStatusText,
                    ),

                    // 3. Card "Jadwal Berikutnya"
                    NextScheduleCard(
                      isLoading: deviceProvider.isLoading,
                      nextScheduleTime: deviceProvider.status.nextScheduleTime,
                      nextScheduleObat: deviceProvider.status.nextScheduleObat,
                      nextScheduleJumlah: deviceProvider.status.nextScheduleJumlah,
                    ),

                    // 4. Grid 2 Kolom (Stok & Gelas)
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.5,
                      children: [
                        // Card "Stok Obat"
                        StockStatusCard(
                          isLoading: deviceProvider.isLoading,
                          stockPercentage: deviceProvider.status.stokObatPercent,
                        ),
                        // Card "Status Gelas"
                        GlassStatusCard(
                          isLoading: deviceProvider.isLoading,
                          statusGelasTerisi: deviceProvider.status.statusGelasTerisi,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // 5. Card "Jadwal Hari Ini"
                    TodayScheduleList(
                      isLoading: deviceProvider.isLoading,
                      schedules: deviceProvider.status.todaySchedule,
                    ),

                    // 6. Tombol Dispense Manual
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.medication_liquid),
                        label: const Text("Keluarkan Obat Manual"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: Theme.of(context).textTheme.titleMedium,
                        ),
                        onPressed: () => _showDispenseConfirmationDialog(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
