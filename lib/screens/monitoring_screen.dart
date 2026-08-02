import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/monitoring_model.dart';
import '../repositories/monitoring_repository.dart';
import '../core/theme/app_theme.dart';

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
    setState(() {
      _stokFuture = _repo.getHistoriStok(lansiaId: widget.lansiaId, hariTerakhir: 30);
      _frekuensiFuture = _repo.getFrekuensiPengambilan(
        lansiaId: widget.lansiaId,
        rentang: _rentangFrekuensi,
      );
      _kepatuhanFuture = _repo.getKepatuhan(
        lansiaId: widget.lansiaId,
        rentang: _rentangFrekuensi,
      );
    });
  }

  void _ubahRentang(RentangWaktu baru) {
    setState(() => _rentangFrekuensi = baru);
    _muatSemua();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => _muatSemua(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildJudulSeksi('Stok Obat (30 hari terakhir)'),
            const SizedBox(height: 8),
            _buildKartuChart(child: _buildStokChart()),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildJudulSeksi('Frekuensi Pengambilan'),
                DropdownButton<RentangWaktu>(
                  value: _rentangFrekuensi,
                  items: const [
                    DropdownMenuItem(
                      value: RentangWaktu.mingguan,
                      child: Text('7 hari'),
                    ),
                    DropdownMenuItem(
                      value: RentangWaktu.bulanan,
                      child: Text('30 hari'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) _ubahRentang(value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildKartuChart(child: _buildFrekuensiChart()),
            const SizedBox(height: 24),

            _buildJudulSeksi('Persentase Kepatuhan'),
            const SizedBox(height: 8),
            _buildKartuChart(child: _buildKepatuhanChart()),
          ],
        ),
      ),
    );
  }

  Widget _buildJudulSeksi(String judul) {
    return Text(
      judul,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w600,
          ),
    );
  }

  Widget _buildKartuChart({required Widget child}) {
    return Container(
      height: 260,
      padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.hairlineSoft, width: 1),
      ),
      child: child,
    );
  }

  // ---------------- STOK OBAT (LineChart) ----------------
  Widget _buildStokChart() {
    return FutureBuilder<List<RiwayatStokModel>>(
      future: _stokFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data ?? [];
        if (data.isEmpty) {
          return const Center(child: Text('Belum ada data stok.'));
        }

        final spots = <FlSpot>[];
        for (int i = 0; i < data.length; i++) {
          spots.add(FlSpot(i.toDouble(), data[i].persen.toDouble()));
        }

        return LineChart(
          LineChartData(
            minY: 0,
            maxY: 100,
            gridData: const FlGridData(show: true, drawVerticalLine: false),
            titlesData: FlTitlesData(
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  interval: 25,
                  getTitlesWidget: (value, meta) => Text('${value.toInt()}%'),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: (data.length / 4).clamp(1, data.length).toDouble(),
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= data.length) return const SizedBox.shrink();
                    final tgl = data[index].createdAt;
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('${tgl.day}/${tgl.month}', style: const TextStyle(fontSize: 10)),
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
                barWidth: 2,
                color: Theme.of(context).colorScheme.primary,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------- FREKUENSI PENGAMBILAN (BarChart) ----------------
  Widget _buildFrekuensiChart() {
    return FutureBuilder<List<FrekuensiHarianModel>>(
      future: _frekuensiFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data ?? [];
        if (data.isEmpty) {
          return const Center(child: Text('Belum ada data.'));
        }

        // Kalau rentang bulanan (30 titik), label sumbu-x terlalu padat
        // kalau ditampilkan semua, jadi kita beri interval otomatis.
        final labelInterval = data.length > 10 ? (data.length / 6).ceil() : 1;

        return BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            gridData: const FlGridData(show: true, drawVerticalLine: false),
            titlesData: FlTitlesData(
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 28),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= data.length) return const SizedBox.shrink();
                    if (index % labelInterval != 0) return const SizedBox.shrink();
                    final tgl = data[index].tanggal;
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('${tgl.day}/${tgl.month}', style: const TextStyle(fontSize: 10)),
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
                      color: Theme.of(context).colorScheme.primary,
                      width: data.length > 15 ? 6 : 14,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  // ---------------- KEPATUHAN (PieChart / Donut) ----------------
  Widget _buildKepatuhanChart() {
    return FutureBuilder<KepatuhanModel>(
      future: _kepatuhanFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data;
        if (data == null || data.total == 0) {
          return const Center(child: Text('Belum ada data kepatuhan.'));
        }

        final warnaSukses = AppColors.success;
        final warnaGagal = AppColors.warning;
        final warnaTerlewat = AppColors.error;

        return Row(
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 45,
                      sections: [
                        PieChartSectionData(
                          value: data.diambil.toDouble(),
                          color: warnaSukses,
                          title: '',
                          radius: 45,
                        ),
                        if (data.gagalVerifikasi > 0)
                          PieChartSectionData(
                            value: data.gagalVerifikasi.toDouble(),
                            color: warnaGagal,
                            title: '',
                            radius: 45,
                          ),
                        if (data.terlewat > 0)
                          PieChartSectionData(
                            value: data.terlewat.toDouble(),
                            color: warnaTerlewat,
                            title: '',
                            radius: 45,
                          ),
                      ],
                    ),
                  ),
                  Text(
                    '${data.persenKepatuhan.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegenda(warnaSukses, 'Diambil', data.diambil),
                  const SizedBox(height: 8),
                  _buildLegenda(warnaGagal, 'Gagal verifikasi', data.gagalVerifikasi),
                  const SizedBox(height: 8),
                  _buildLegenda(warnaTerlewat, 'Terlewat', data.terlewat),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLegenda(Color warna, String label, int jumlah) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: warna,
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label ($jumlah)',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.body,
            ),
          ),
        ),
      ],
    );
  }
}
