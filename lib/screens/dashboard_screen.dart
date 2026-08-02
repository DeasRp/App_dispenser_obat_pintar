import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/device_provider.dart';
import '../repositories/jadwal_repository.dart';
import '../models/jadwal_obat_model.dart';
import '../widgets/connection_status_banner.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/next_schedule_card.dart';
import '../widgets/stock_status_card.dart';
import '../widgets/glass_status_card.dart';
import '../widgets/today_schedule_list.dart';
import '../widgets/last_medicine_taken_card.dart';

// Halaman utama / Dashboard Aplikasi
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _jadwalRepo = JadwalRepository();
  Future<RiwayatKonsumsiModel?>? _riwayatTerakhirFuture;

  void _muatRiwayatTerakhir(String lansiaId) {
    if (lansiaId.isEmpty) return;
    setState(() {
      _riwayatTerakhirFuture = _jadwalRepo.getRiwayatTerakhir(lansiaId);
    });
  }

  Future<void> _refreshSemua(DeviceProvider deviceProvider) async {
    await deviceProvider.refreshDeviceStatus();
    _muatRiwayatTerakhir(deviceProvider.lansiaId);
  }

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
                Navigator.of(dialogContext).pop();
              },
            ),
            FilledButton(
              child: const Text("Ya, Keluarkan"),
              onPressed: () {
                context.read<DeviceProvider>().publishDispenseCommand();
                Navigator.of(dialogContext).pop();

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

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceProvider>(
      builder: (context, deviceProvider, child) {
        // Muat riwayat terakhir sekali saja saat lansiaId sudah tersedia.
        _riwayatTerakhirFuture ??= deviceProvider.lansiaId.isNotEmpty
            ? _jadwalRepo.getRiwayatTerakhir(deviceProvider.lansiaId)
            : null;

        return Scaffold(
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () => _refreshSemua(deviceProvider),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // 1. Header: Sapaan + Nama Lansia
                    DashboardHeader(namaLansia: deviceProvider.status.namaLansia),
                    const SizedBox(height: 8),

                    // 2. Banner Status Koneksi (Dispenser Online + WiFi)
                    ConnectionStatusBanner(
                      isLoading: deviceProvider.isLoading,
                      isOnline: deviceProvider.status.isDeviceOnline,
                      statusText: deviceProvider.status.wifiStatusText,
                    ),
                    const SizedBox(height: 12),

                    // 3. Card "Jadwal Berikutnya"
                    NextScheduleCard(
                      isLoading: deviceProvider.isLoading,
                      nextScheduleTime: deviceProvider.status.nextScheduleTime,
                      nextScheduleObat: deviceProvider.status.nextScheduleObat,
                      nextScheduleJumlah: deviceProvider.status.nextScheduleJumlah,
                    ),
                    const SizedBox(height: 12),

                    // 4. Grid 2 Kolom (Stok & Gelas)
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.5,
                      children: [
                        StockStatusCard(
                          isLoading: deviceProvider.isLoading,
                          stockPercentage: deviceProvider.status.stokObatPercent,
                        ),
                        GlassStatusCard(
                          isLoading: deviceProvider.isLoading,
                          statusGelasTerisi: deviceProvider.status.statusGelasTerisi,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // 5. Last Medicine Taken
                    FutureBuilder<RiwayatKonsumsiModel?>(
                      future: _riwayatTerakhirFuture,
                      builder: (context, snapshot) {
                        final riwayat = snapshot.data;
                        return LastMedicineTakenCard(
                          isLoading: snapshot.connectionState == ConnectionState.waiting,
                          namaObatTerakhir: riwayat?.namaObat,
                          waktuTerakhir: riwayat?.waktuDiambil,
                          statusTerakhir: riwayat?.status,
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    // 6. Card "Jadwal Hari Ini"
                    TodayScheduleList(
                      isLoading: deviceProvider.isLoading,
                      schedules: deviceProvider.status.todaySchedule,
                    ),
                    const SizedBox(height: 16),

                    // 6. Tombol Dispense Manual
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: FilledButton.icon(
                        icon: const Icon(Icons.medication_liquid),
                        label: const Text("Keluarkan Obat Manual"),
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