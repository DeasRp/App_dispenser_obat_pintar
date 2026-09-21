import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../models/jadwal_obat_model.dart';
import '../models/monitoring_model.dart';
import '../providers/device_provider.dart';
import '../repositories/jadwal_repository.dart';
import '../repositories/monitoring_repository.dart';
import '../widgets/connection_status_banner.dart';
import '../widgets/last_medicine_taken_card.dart';
import '../widgets/next_schedule_card.dart';
import '../widgets/stock_status_card.dart';
import '../widgets/today_intake_summary_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _jadwalRepo = JadwalRepository();
  final _monitoringRepo = MonitoringRepository();

  Future<RiwayatKonsumsiModel?>? _riwayatTerakhirFuture;
  Future<RingkasanHariIniModel>? _ringkasanHariIniFuture;

  void _muatDataDashboard(String lansiaId) {
    if (lansiaId.isEmpty) return;
    setState(() {
      _riwayatTerakhirFuture = _jadwalRepo.getRiwayatTerakhir(lansiaId);
      _ringkasanHariIniFuture = _monitoringRepo.getRingkasanHariIni(
        lansiaId: lansiaId,
      );
    });
  }

  Future<void> _refreshSemua(DeviceProvider deviceProvider) async {
    await deviceProvider.refreshDeviceStatus();
    _muatDataDashboard(deviceProvider.lansiaId);
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

  String _sapaan() {
    final jam = DateTime.now().hour;
    if (jam < 12) return 'Selamat pagi';
    if (jam < 15) return 'Selamat siang';
    if (jam < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  Widget _buildHero(DeviceProvider provider) {
    final nama = provider.status.namaLansia.trim().isEmpty
        ? 'Pengguna'
        : provider.status.namaLansia.trim();
    final online = provider.status.isDeviceOnline;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.24),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.medication_outlined,
              color: Colors.white,
              size: 27,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_sapaan()},',
                  style: const TextStyle(
                    color: Color(0xFFFFEEF1),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  nama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: online
                            ? const Color(0xFF83E6AA)
                            : Colors.white70,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      online ? 'Dispenser online' : 'Dispenser offline',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(
            Icons.monitor_heart_outlined,
            color: Colors.white70,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _cardShadow(Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceProvider>(
      builder: (context, deviceProvider, child) {
        if (deviceProvider.lansiaId.isNotEmpty) {
          _riwayatTerakhirFuture ??=
              _jadwalRepo.getRiwayatTerakhir(deviceProvider.lansiaId);
          _ringkasanHariIniFuture ??= _monitoringRepo.getRingkasanHariIni(
            lansiaId: deviceProvider.lansiaId,
          );
        }

        return Scaffold(
          backgroundColor: AppColors.surfaceSoft,
          body: SafeArea(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => _refreshSemua(deviceProvider),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHero(deviceProvider),
                    const SizedBox(height: 14),
                    _cardShadow(
                      ConnectionStatusBanner(
                        isLoading: deviceProvider.isLoading,
                        isOnline: deviceProvider.status.isDeviceOnline,
                        statusText: deviceProvider.status.wifiStatusText,
                      ),
                    ),
                    if (!deviceProvider.isMqttConnected) ...[
                      const SizedBox(height: 6),
                      const Row(
                        children: [
                          Icon(
                            Icons.cloud_off_outlined,
                            size: 15,
                            color: AppColors.muted,
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Dispenser offline. Data terakhir tetap tersedia.',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),
                    _cardShadow(
                      NextScheduleCard(
                        isLoading: deviceProvider.isLoading,
                        nextScheduleTime:
                            deviceProvider.status.nextScheduleTime,
                        nextScheduleObat:
                            deviceProvider.status.nextScheduleObat,
                        nextScheduleJumlah:
                            deviceProvider.status.nextScheduleJumlah,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _cardShadow(
                      StockStatusCard(
                        isLoading: deviceProvider.isLoading,
                        stockPercentage:
                            deviceProvider.status.stokObatPercent,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _cardShadow(
                      FutureBuilder<RingkasanHariIniModel>(
                        future: _ringkasanHariIniFuture,
                        builder: (context, snapshot) {
                          return TodayIntakeSummaryCard(
                            isLoading: snapshot.connectionState ==
                                ConnectionState.waiting,
                            ringkasan: snapshot.data,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    _cardShadow(
                      FutureBuilder<RiwayatKonsumsiModel?>(
                        future: _riwayatTerakhirFuture,
                        builder: (context, snapshot) {
                          final riwayat = snapshot.data;
                          return LastMedicineTakenCard(
                            isLoading: snapshot.connectionState ==
                                ConnectionState.waiting,
                            namaObatTerakhir: riwayat?.namaObat,
                            waktuTerakhir: riwayat?.waktuDiambil,
                            statusTerakhir: riwayat?.status,
                          );
                        },
                      ),
                    ),
                    if (deviceProvider.isLansia) ...[
                      const SizedBox(height: 12),
                      _cardShadow(
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: FilledButton.icon(
                            onPressed: deviceProvider.canDispenseManual
                                ? () =>
                                    _showDispenseConfirmationDialog(context)
                                : null,
                            icon: const Icon(Icons.medication_outlined),
                            label: const Text('Keluarkan Obat Manual'),
                            style: FilledButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ),
                      if (!deviceProvider.canDispenseManual) ...[
                        const SizedBox(height: 5),
                        const Text(
                          'Tersedia saat dispenser online.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
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
