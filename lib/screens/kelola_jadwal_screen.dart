import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/audio_track_helper.dart';
import '../models/jadwal_obat_model.dart';
import '../providers/device_provider.dart';
import '../repositories/jadwal_repository.dart';

class KelolaJadwalScreen extends StatefulWidget {
  final String lansiaId;

  const KelolaJadwalScreen({
    super.key,
    required this.lansiaId,
  });

  @override
  State<KelolaJadwalScreen> createState() => _KelolaJadwalScreenState();
}

class _KelolaJadwalScreenState extends State<KelolaJadwalScreen> {
  final _repo = JadwalRepository();
  late Future<List<JadwalObatModel>> _jadwalFuture;

  static const int jumlahKompartemen = 5;
  static const List<String> pilihanSatuan = ['tablet', 'kapsul', 'butir'];

  @override
  void initState() {
    super.initState();
    _muatUlang();
  }

  void _muatUlang() {
    _jadwalFuture = _repo.getJadwalByLansia(widget.lansiaId);
    if (mounted) setState(() {});
  }

  Future<void> _refresh() async {
    _muatUlang();
    await _jadwalFuture;
  }

  int _nomorKompartemen(int indeks) => indeks + 1;

  void _beriStatusSinkronisasi() {
    final tersinkron = context.read<DeviceProvider>().publishScheduleSync();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tersinkron
              ? 'Jadwal tersimpan dan perintah sinkronisasi dikirim ke dispenser.'
              : 'Jadwal tersimpan di Supabase. Menunggu dispenser kembali online untuk sinkronisasi.',
        ),
      ),
    );
  }

  TimeOfDay _parseJamAwal(String? jam) {
    if (jam == null) return const TimeOfDay(hour: 8, minute: 0);
    final parts = jam.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts.first) ?? 8,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
  }

  String _formatJam(TimeOfDay jam) {
    final jj = jam.hour.toString().padLeft(2, '0');
    final mm = jam.minute.toString().padLeft(2, '0');
    return '$jj:$mm';
  }

  Future<void> _bukaDialogJadwal({JadwalObatModel? jadwalLama}) async {
    final obatController = TextEditingController(
      text: jadwalLama?.namaObat ?? '',
    );
    final jumlahController = TextEditingController(
      text: (jadwalLama?.jumlahAngka ?? 1).toString(),
    );

    String satuanTerpilih = jadwalLama?.satuan ?? 'tablet';
    if (!pilihanSatuan.contains(satuanTerpilih)) {
      satuanTerpilih = 'tablet';
    }

    int urutanTerpilih = jadwalLama?.urutanKompartemen ?? 0;
    if (urutanTerpilih < 0 || urutanTerpilih >= jumlahKompartemen) {
      urutanTerpilih = 0;
    }

    TimeOfDay jamTerpilih = _parseJamAwal(jadwalLama?.jam);

    final simpan = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  jadwalLama == null ? Icons.add_alarm_outlined : Icons.edit_calendar_outlined,
                  color: AppColors.primary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  jadwalLama == null ? 'Tambah Jadwal Obat' : 'Edit Jadwal Obat',
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  onTap: () async {
                    final dipilih = await showTimePicker(
                      context: dialogContext,
                      initialTime: jamTerpilih,
                    );
                    if (dipilih != null) {
                      setDialogState(() => jamTerpilih = dipilih);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: AppColors.hairline),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, color: AppColors.primary),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Jam Pengambilan',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _formatJam(jamTerpilih),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: obatController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nama Obat',
                    prefixIcon: Icon(Icons.medication_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: jumlahController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Jumlah Obat dalam Kompartemen',
                    prefixIcon: Icon(Icons.numbers),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: satuanTerpilih,
                  decoration: const InputDecoration(
                    labelText: 'Jenis / Satuan',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: pilihanSatuan
                      .map(
                        (satuan) => DropdownMenuItem(
                          value: satuan,
                          child: Text(satuan),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => satuanTerpilih = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: urutanTerpilih,
                  decoration: const InputDecoration(
                    labelText: 'Kompartemen Carousel',
                    prefixIcon: Icon(Icons.grid_view_rounded),
                  ),
                  items: List.generate(
                    jumlahKompartemen,
                    (i) => DropdownMenuItem(
                      value: i,
                      child: Text('Kompartemen #${_nomorKompartemen(i)}'),
                    ),
                  ),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => urutanTerpilih = value);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.save_outlined, size: 18),
              label: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );

    if (simpan != true) return;

    final jumlahAngka = int.tryParse(jumlahController.text.trim());
    if (obatController.text.trim().isEmpty ||
        jumlahAngka == null ||
        jumlahAngka <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama obat dan jumlah yang valid wajib diisi.'),
        ),
      );
      return;
    }

    final jadwalBaru = JadwalObatModel(
      lansiaId: widget.lansiaId,
      jam: _formatJam(jamTerpilih),
      namaObat: obatController.text.trim(),
      jumlahAngka: jumlahAngka,
      satuan: satuanTerpilih,
      trackAudio: tentukanTrackAudio(jamTerpilih),
      urutanKompartemen: urutanTerpilih,
    );

    try {
      if (jadwalLama == null) {
        await _repo.tambahJadwal(jadwalBaru);
      } else {
        await _repo.updateJadwal(jadwalLama.id!, jadwalBaru);
      }

      _muatUlang();
      _beriStatusSinkronisasi();
    } catch (e) {
      if (!mounted) return;

      final duplicate = e.toString().contains('duplicate') ||
          e.toString().contains('uq_kompartemen_aktif_per_lansia');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            duplicate
                ? 'Kompartemen #${_nomorKompartemen(urutanTerpilih)} sudah dipakai jadwal aktif lain.'
                : 'Gagal menyimpan jadwal: $e',
          ),
        ),
      );
    }
  }

  Future<void> _hapusJadwal(JadwalObatModel jadwal) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Jadwal?'),
        content: Text(
          'Jadwal ${jadwal.namaObat} pukul ${jadwal.jam} akan dinonaktifkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (konfirmasi != true) return;

    await _repo.nonaktifkanJadwal(jadwal.id!);
    _muatUlang();
    _beriStatusSinkronisasi();
  }

  Widget _buildHero(bool online) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 14),
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
              Icons.calendar_month_outlined,
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
                  'Kelola Jadwal Obat',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Atur waktu, jumlah obat, dan kompartemen dispenser.',
                  style: TextStyle(
                    color: Color(0xFFFFEEF1),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: online ? const Color(0xFF7EE2A8) : Colors.white70,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  online ? 'Online' : 'Offline',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.18)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.cloud_off_outlined, color: AppColors.warning, size: 19),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Dispenser offline. Jadwal tetap tersimpan di Supabase dan akan disinkronkan saat perangkat kembali online.',
              style: TextStyle(
                color: AppColors.body,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(List<JadwalObatModel> daftar) {
    final kompartemenTerpakai = daftar.map((e) => e.urutanKompartemen).toSet().length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              icon: Icons.schedule_outlined,
              value: '${daftar.length}',
              label: 'Jadwal aktif',
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildSummaryItem(
              icon: Icons.grid_view_rounded,
              value: '$kompartemenTerpakai/$jumlahKompartemen',
              label: 'Kompartemen',
              color: const Color(0xFF6C63FF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairlineSoft),
        boxShadow: AppShadows.card,
      ),
      child: Row(
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
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJadwalCard(JadwalObatModel jadwal) {
    final nomor = _nomorKompartemen(jadwal.urutanKompartemen);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.hairlineSoft),
        boxShadow: AppShadows.card,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.medication_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '#$nomor',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          jadwal.namaObat,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: const Text(
                          'Aktif',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _buildMetaChip(Icons.access_time, jadwal.jam),
                      _buildMetaChip(Icons.medication_liquid_outlined, jadwal.jumlahLabel),
                      _buildMetaChip(Icons.grid_view_rounded, 'Kompartemen $nomor'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _bukaDialogJadwal(jadwalLama: jadwal),
                          icon: const Icon(Icons.edit_outlined, size: 17),
                          label: const Text('Edit'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 40),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.outlined(
                        tooltip: 'Hapus',
                        onPressed: () => _hapusJadwal(jadwal),
                        icon: const Icon(Icons.delete_outline, color: AppColors.error),
                        style: IconButton.styleFrom(
                          side: BorderSide(color: AppColors.error.withValues(alpha: 0.35)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.muted),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.body,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 72, 24, 120),
        children: [
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.event_note_outlined,
                size: 34,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Belum ada jadwal obat',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tambahkan jadwal pertama agar dispenser dapat mengeluarkan obat secara otomatis.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final online = context.watch<DeviceProvider>().isMqttConnected;

    return ColoredBox(
      color: AppColors.surfaceSoft,
      child: Column(
        children: [
          _buildHero(online),
          if (!online) _buildOfflineBanner(),
          Expanded(
            child: FutureBuilder<List<JadwalObatModel>>(
              future: _jadwalFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.error_outline,
                              color: AppColors.error,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Jadwal belum dapat dimuat',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: _muatUlang,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Coba lagi'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final daftar = snapshot.data ?? [];
                if (daftar.isEmpty) return _buildEmptyState();

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 110),
                    children: [
                      _buildSummary(daftar),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 4, 16, 10),
                        child: Text(
                          'Daftar Jadwal',
                          style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      for (int i = 0; i < daftar.length; i++) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildJadwalCard(daftar[i]),
                        ),
                        if (i != daftar.length - 1) const SizedBox(height: 10),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: () => _bukaDialogJadwal(),
                  icon: const Icon(Icons.add_alarm_outlined),
                  label: const Text(
                    'Tambah Jadwal Baru',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}