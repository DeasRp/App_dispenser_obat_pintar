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

  Widget _buildHero(DeviceProvider provider) {
    final online = provider.status.isDeviceOnline;
    final nama = provider.status.namaLansia.trim().isEmpty
        ? 'Pengguna'
        : provider.status.namaLansia;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.home_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dashboard ObatKu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Ringkasan kondisi dispenser untuk $nama',
                      style: const TextStyle(
                        color: Color(0xFFFFEEF1),
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: online ? const Color(0xFF7EE2A8) : Colors.white70,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    online ? 'Dispenser terhubung dan siap digunakan' : 'Dispenser sedang offline',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(
                  Icons.swipe_down_alt,
                  color: Colors.white70,
                  size: 19,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
    required String subtitle,
    Color color = AppColors.primary,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSurface({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.hairlineSoft),
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.all(4),
      child: child,
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
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHero(deviceProvider),
                    const SizedBox(height: 18),
                    ConnectionStatusBanner(
                      isLoading: deviceProvider.isLoading,
                      isOnline: deviceProvider.status.isDeviceOnline,
                      statusText: deviceProvider.status.wifiStatusText,
                    ),
                    if (!deviceProvider.isMqttConnected) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.18),
                          ),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.cloud_off_outlined,
                              color: AppColors.warning,
                              size: 19,
                            ),
                            SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                'Dispenser offline. Data aplikasi tetap dapat diakses dari Supabase dan akan disinkronkan kembali saat perangkat online.',
                                style: TextStyle(
                                  color: AppColors.body,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    _buildSectionTitle(
                      icon: Icons.schedule_outlined,
                      title: 'Jadwal Berikutnya',
                      subtitle: 'Obat yang akan dikeluarkan pada jadwal terdekat',
                    ),
                    _buildInfoSurface(
                      child: NextScheduleCard(
                        isLoading: deviceProvider.isLoading,
                        nextScheduleTime: deviceProvider.status.nextScheduleTime,
                        nextScheduleObat: deviceProvider.status.nextScheduleObat,
                        nextScheduleJumlah:
                            deviceProvider.status.nextScheduleJumlah,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildSectionTitle(
                      icon: Icons.inventory_2_outlined,
                      title: 'Kondisi Stok',
                      subtitle: 'Persentase stok obat yang tersedia di dispenser',
                      color: AppColors.success,
                    ),
                    _buildInfoSurface(
                      child: StockStatusCard(
                        isLoading: deviceProvider.isLoading,
                        stockPercentage: deviceProvider.status.stokObatPercent,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildSectionTitle(
                      icon: Icons.today_outlined,
                      title: 'Aktivitas Hari Ini',
                      subtitle: 'Ringkasan pengambilan dan jadwal terlewat hari ini',
                      color: const Color(0xFF6C63FF),
                    ),
                    _buildInfoSurface(
                      child: FutureBuilder<RingkasanHariIniModel>(
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
                    const SizedBox(height: 20),
                    _buildSectionTitle(
                      icon: Icons.history_outlined,
                      title: 'Pengambilan Terakhir',
                      subtitle: 'Riwayat obat terakhir yang tercatat oleh sistem',
                      color: AppColors.warning,
                    ),
                    _buildInfoSurface(
                      child: FutureBuilder<RiwayatKonsumsiModel?>(
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
                      const SizedBox(height: 22),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.canvas,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: AppColors.hairlineSoft),
                          boxShadow: AppShadows.card,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Kontrol Dispenser',
                              style: TextStyle(
                                color: AppColors.ink,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Gunakan hanya ketika berada dekat dengan dispenser.',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 14),
                            FilledButton.icon(
                              onPressed: deviceProvider.canDispenseManual
                                  ? () => _showDispenseConfirmationDialog(context)
                                  : null,
                              icon: const Icon(Icons.medication_outlined),
                              label: const Text('Keluarkan Obat Manual'),
                              style: FilledButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                              ),
                            ),
                            if (!deviceProvider.canDispenseManual) ...[
                              const SizedBox(height: 8),
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 15,
                                    color: AppColors.muted,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Dispense manual tersedia saat dispenser online.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
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
