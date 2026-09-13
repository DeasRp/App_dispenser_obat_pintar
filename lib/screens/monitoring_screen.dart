import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../core/theme/app_theme.dart';
import '../models/monitoring_model.dart';
import '../repositories/monitoring_repository.dart';

class MonitoringScreen extends StatefulWidget {
  final String lansiaId;

  const MonitoringScreen({super.key, required this.lansiaId});

  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> {
  final _repo = MonitoringRepository();

  RentangWaktu _rentangFrekuensi = RentangWaktu.mingguan;

  late Future<List<RiwayatStokModel>> _stokFuture;
  late Future<List<FrekuensiHarianModel>> _frekuensiFuture;
  late Future<KepatuhanModel> _kepatuhanFuture;

  @override
  void initState() {
    super.initState();
    _muatSemua();
  }

  void _muatSemua() {
    _stokFuture = _repo.getHistoriStok(
      lansiaId: widget.lansiaId,
      hariTerakhir: 30,
    );
    _frekuensiFuture = _repo.getFrekuensiPengambilan(
      lansiaId: widget.lansiaId,
      rentang: _rentangFrekuensi,
    );
    _kepatuhanFuture = _repo.getKepatuhan(
      lansiaId: widget.lansiaId,
      rentang: _rentangFrekuensi,
    );
  }

  Future<void> _refresh() async {
    setState(_muatSemua);
    await Future.wait<dynamic>([
      _stokFuture,
      _frekuensiFuture,
      _kepatuhanFuture,
    ]);
  }

  void _ubahRentang(RentangWaktu baru) {
    if (_rentangFrekuensi == baru) return;
    setState(() {
      _rentangFrekuensi = baru;
      _frekuensiFuture = _repo.getFrekuensiPengambilan(
        lansiaId: widget.lansiaId,
        rentang: baru,
      );
      _kepatuhanFuture = _repo.getKepatuhan(
        lansiaId: widget.lansiaId,
        rentang: baru,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceSoft,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _buildHeroMonitoring(),
            const SizedBox(height: 20),
            _buildStokSection(),
            const SizedBox(height: 20),
            _buildFrekuensiSection(),
            const SizedBox(height: 20),
            _buildKepatuhanSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroMonitoring() {
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
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.monitor_heart_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monitoring Kesehatan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Pantau stok, aktivitas pengambilan, dan kepatuhan obat.',
                  style: TextStyle(
                    color: Color(0xFFFFEEF1),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.swipe_down_alt, color: Colors.white70, size: 22),
        ],
      ),
    );
  }

  Widget _buildStokSection() {
    return _buildMonitoringCard(
      icon: Icons.inventory_2_outlined,
      iconColor: AppColors.primary,
      title: 'Stok Obat',
      subtitle: 'Perubahan persentase stok selama 30 hari terakhir',
      trailing: FutureBuilder<List<RiwayatStokModel>>(
        future: _stokFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildBadge('--', AppColors.muted);
          }
          return _buildBadge(
            '${snapshot.data!.last.persen}%',
            _stokColor(snapshot.data!.last.persen),
          );
        },
      ),
      child: _buildStokChart(),
    );
  }

  Widget _buildFrekuensiSection() {
    return _buildMonitoringCard(
      icon: Icons.medication_outlined,
      iconColor: const Color(0xFF6C63FF),
      title: 'Frekuensi Pengambilan',
      subtitle: 'Jumlah pengambilan obat yang berhasil setiap hari',
      trailing: _buildRentangSelector(),
      child: _buildFrekuensiChart(),
    );
  }

  Widget _buildKepatuhanSection() {
    return _buildMonitoringCard(
      icon: Icons.verified_outlined,
      iconColor: AppColors.success,
      title: 'Kepatuhan Minum Obat',
      subtitle: _rentangFrekuensi == RentangWaktu.mingguan
          ? 'Ringkasan kepatuhan 7 hari terakhir'
          : 'Ringkasan kepatuhan 30 hari terakhir',
      child: _buildKepatuhanChart(),
    );
  }

  Widget _buildMonitoringCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.hairlineSoft),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 12),
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
                      const SizedBox(height: 3),
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
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing,
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          SizedBox(
            height: 245,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 18, 16, 10),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildRentangSelector() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceStrong,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRentangChip('7H', RentangWaktu.mingguan),
          _buildRentangChip('30H', RentangWaktu.bulanan),
        ],
      ),
    );
  }

  Widget _buildRentangChip(String label, RentangWaktu value) {
    final aktif = _rentangFrekuensi == value;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _ubahRentang(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: aktif ? AppColors.canvas : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: aktif
              ? const [
                  BoxShadow(
                    color: Color(0x10000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: aktif ? AppColors.primary : AppColors.muted,
          ),
        ),
      ),
    );
  }

  Color _stokColor(int persen) {
    if (persen <= 20) return AppColors.error;
    if (persen <= 50) return AppColors.warning;
    return AppColors.success;
  }

  Widget _buildEmptyState({required IconData icon, required String text}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.mutedSoft, size: 24),
          ),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      ),
    );
  }

  Widget _buildStokChart() {
    return FutureBuilder<List<RiwayatStokModel>>(
      future: _stokFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoading();
        }
        if (snapshot.hasError) {
          return _buildEmptyState(
            icon: Icons.cloud_off_outlined,
            text: 'Data stok belum dapat dimuat.',
          );
        }

        final data = snapshot.data ?? [];
        if (data.isEmpty) {
          return _buildEmptyState(
            icon: Icons.inventory_2_outlined,
            text: 'Belum ada riwayat stok obat.',
          );
        }

        final spots = <FlSpot>[
          for (int i = 0; i < data.length; i++)
            FlSpot(i.toDouble(), data[i].persen.toDouble()),
        ];

        return LineChart(
          LineChartData(
            minY: 0,
            maxY: 100,
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (spots) => spots
                    .map(
                      (spot) => LineTooltipItem(
                        '${spot.y.toInt()}%',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 25,
              getDrawingHorizontalLine: (_) => const FlLine(
                color: AppColors.hairlineSoft,
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 38,
                  interval: 25,
                  getTitlesWidget: (value, meta) => Text(
                    '${value.toInt()}%',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.muted,
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: (data.length / 4).clamp(1, data.length).toDouble(),
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= data.length) {
                      return const SizedBox.shrink();
                    }
                    final tgl = data[index].createdAt.toLocal();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '${tgl.day}/${tgl.month}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.muted,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                curveSmoothness: 0.25,
                barWidth: 3,
                color: AppColors.primary,
                isStrokeCapRound: true,
                dotData: FlDotData(show: data.length <= 8),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.22),
                      AppColors.primary.withValues(alpha: 0.02),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFrekuensiChart() {
    return FutureBuilder<List<FrekuensiHarianModel>>(
      future: _frekuensiFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoading();
        }
        if (snapshot.hasError) {
          return _buildEmptyState(
            icon: Icons.cloud_off_outlined,
            text: 'Data pengambilan belum dapat dimuat.',
          );
        }

        final data = snapshot.data ?? [];
        if (data.isEmpty) {
          return _buildEmptyState(
            icon: Icons.medication_outlined,
            text: 'Belum ada data pengambilan obat.',
          );
        }

        final labelInterval = data.length > 10 ? (data.length / 6).ceil() : 1;
        final maxJumlah = data.fold<int>(
          0,
          (max, item) => item.jumlahDiambil > max ? item.jumlahDiambil : max,
        );
        final maxY = (maxJumlah < 3 ? 3 : maxJumlah + 1).toDouble();

        return BarChart(
          BarChartData(
            maxY: maxY,
            alignment: BarChartAlignment.spaceAround,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    '${rod.toY.toInt()} kali',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                },
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 1,
              getDrawingHorizontalLine: (_) => const FlLine(
                color: AppColors.hairlineSoft,
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: 1,
                  getTitlesWidget: (value, meta) => Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.muted,
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= data.length) {
                      return const SizedBox.shrink();
                    }
                    if (index % labelInterval != 0) {
                      return const SizedBox.shrink();
                    }
                    final tgl = data[index].tanggal;
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        '${tgl.day}/${tgl.month}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.muted,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: [
              for (int i = 0; i < data.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: data[i].jumlahDiambil.toDouble(),
                      width: data.length > 15 ? 7 : 16,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(5),
                      ),
                      gradient: const LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Color(0xFF8C85FF), Color(0xFF5F56E8)],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKepatuhanChart() {
    return FutureBuilder<KepatuhanModel>(
      future: _kepatuhanFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoading();
        }
        if (snapshot.hasError) {
          return _buildEmptyState(
            icon: Icons.cloud_off_outlined,
            text: 'Data kepatuhan belum dapat dimuat.',
          );
        }

        final data = snapshot.data;
        if (data == null || data.total == 0) {
          return _buildEmptyState(
            icon: Icons.verified_outlined,
            text: 'Belum ada data kepatuhan.',
          );
        }

        final persen = data.persenKepatuhan;

        return Row(
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      startDegreeOffset: -90,
                      sectionsSpace: 3,
                      centerSpaceRadius: 50,
                      sections: [
                        if (data.diambil > 0)
                          PieChartSectionData(
                            value: data.diambil.toDouble(),
                            color: AppColors.success,
                            title: '',
                            radius: 20,
                          ),
                        if (data.gagalVerifikasi > 0)
                          PieChartSectionData(
                            value: data.gagalVerifikasi.toDouble(),
                            color: AppColors.warning,
                            title: '',
                            radius: 20,
                          ),
                        if (data.terlewat > 0)
                          PieChartSectionData(
                            value: data.terlewat.toDouble(),
                            color: AppColors.error,
                            title: '',
                            radius: 20,
                          ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${persen.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      const Text(
                        'kepatuhan',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 4,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegenda(
                    AppColors.success,
                    Icons.check_circle_outline,
                    'Diambil',
                    data.diambil,
                  ),
                  const SizedBox(height: 8),
                  _buildLegenda(
                    AppColors.warning,
                    Icons.help_outline,
                    'Gagal verifikasi',
                    data.gagalVerifikasi,
                  ),
                  const SizedBox(height: 8),
                  _buildLegenda(
                    AppColors.error,
                    Icons.schedule_outlined,
                    'Terlewat',
                    data.terlewat,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLegenda(
    Color warna,
    IconData icon,
    String label,
    int jumlah,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: warna.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: warna, size: 17),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.body,
              ),
            ),
          ),
          Text(
            '$jumlah',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: warna,
            ),
          ),
        ],
      ),
    );
  }
}
