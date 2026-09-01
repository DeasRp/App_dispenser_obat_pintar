import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/jadwal_obat_model.dart';
import '../providers/device_provider.dart';
import '../repositories/jadwal_repository.dart';
import '../widgets/connection_status_banner.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/last_medicine_taken_card.dart';
import '../widgets/next_schedule_card.dart';
import '../widgets/stock_status_card.dart';

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
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text(
          'Apakah Anda yakin ingin mengeluarkan obat secara manual?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final terkirim =
                  context.read<DeviceProvider>().publishDispenseCommand();
              Navigator.of(dialogContext).pop();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    terkirim
                        ? 'Perintah mengeluarkan obat dikirim.'
                        : 'Dispenser sedang offline. Perintah tidak dikirim.',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Keluarkan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceProvider>(
      builder: (context, deviceProvider, child) {
        _riwayatTerakhirFuture ??= deviceProvider.lansiaId.isNotEmpty
            ? _jadwalRepo.getRiwayatTerakhir(deviceProvider.lansiaId)
            : null;

        return Scaffold(
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () => _refreshSemua(deviceProvider),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DashboardHeader(
                      namaLansia: deviceProvider.status.namaLansia,
                    ),
                    const SizedBox(height: 8),
                    ConnectionStatusBanner(
                      isLoading: deviceProvider.isLoading,
                      isOnline: deviceProvider.status.isDeviceOnline,
                      statusText: deviceProvider.status.wifiStatusText,
                    ),
                    if (!deviceProvider.isMqttConnected) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Dispenser offline. Jadwal, riwayat, monitoring, notifikasi, dan pengaturan tetap dapat digunakan dari Supabase.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                    const SizedBox(height: 12),
                    NextScheduleCard(
                      isLoading: deviceProvider.isLoading,
                      nextScheduleTime: deviceProvider.status.nextScheduleTime,
                      nextScheduleObat: deviceProvider.status.nextScheduleObat,
                      nextScheduleJumlah:
                          deviceProvider.status.nextScheduleJumlah,
                    ),
                    const SizedBox(height: 12),
                    StockStatusCard(
                      isLoading: deviceProvider.isLoading,
                      stockPercentage: deviceProvider.status.stokObatPercent,
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<RiwayatKonsumsiModel?>(
                      future: _riwayatTerakhirFuture,
                      builder: (context, snapshot) {
                        final riwayat = snapshot.data;
                        return LastMedicineTakenCard(
                          isLoading:
                              snapshot.connectionState == ConnectionState.waiting,
                          namaObatTerakhir: riwayat?.namaObat,
                          waktuTerakhir: riwayat?.waktuDiambil,
                          statusTerakhir: riwayat?.status,
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: deviceProvider.canDispenseManual
                          ? () => _showDispenseConfirmationDialog(context)
                          : null,
                      icon: const Icon(Icons.medication_outlined),
                      label: const Text('Keluarkan Obat Manual'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                    if (!deviceProvider.canDispenseManual) ...[
                      const SizedBox(height: 6),
                      const Text(
                        'Dispense manual hanya tersedia saat dispenser terhubung.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
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
