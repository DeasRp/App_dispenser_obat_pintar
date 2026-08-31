import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/notifikasi_model.dart';
import '../repositories/notifikasi_repository.dart';

class NotifikasiScreen extends StatefulWidget {
  final String lansiaId;

  const NotifikasiScreen({
    super.key,
    required this.lansiaId,
  });

  @override
  State<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen> {
  final _repo = NotifikasiRepository();
  late Future<List<NotifikasiModel>> _future;

  @override
  void initState() {
    super.initState();
    _muatUlang();
  }

  void _muatUlang() {
    _future = _repo.getNotifikasi(lansiaId: widget.lansiaId);
  }

  Future<void> _refresh() async {
    setState(_muatUlang);
    await _future;
  }

  Future<void> _tandaiSemuaDibaca() async {
    try {
      await _repo.tandaiSemuaDibaca(widget.lansiaId);
      if (!mounted) return;
      setState(_muatUlang);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memperbarui notifikasi.')),
      );
    }
  }

  IconData _ikonUntuk(String jenis) {
    switch (jenis.toLowerCase()) {
      case 'diambil':
      case 'obat_diambil':
      case 'berhasil':
        return Icons.check_circle_outline;
      case 'terlambat':
      case 'telat':
        return Icons.schedule;
      case 'terlewat':
        return Icons.error_outline;
      case 'stok_rendah':
      case 'stok_menipis':
        return Icons.inventory_2_outlined;
      default:
        return Icons.notifications_none;
    }
  }

  Color _warnaUntuk(String jenis) {
    switch (jenis.toLowerCase()) {
      case 'diambil':
      case 'obat_diambil':
      case 'berhasil':
        return AppColors.success;
      case 'terlambat':
      case 'telat':
        return AppColors.warning;
      case 'terlewat':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  String _formatWaktu(DateTime waktu) {
    final lokal = waktu.toLocal();
    final now = DateTime.now();
    final hariSama = now.year == lokal.year &&
        now.month == lokal.month &&
        now.day == lokal.day;

    final jam = lokal.hour.toString().padLeft(2, '0');
    final menit = lokal.minute.toString().padLeft(2, '0');

    if (hariSama) return 'Hari ini, $jam:$menit';

    final tanggal = lokal.day.toString().padLeft(2, '0');
    final bulan = lokal.month.toString().padLeft(2, '0');
    return '$tanggal/$bulan/${lokal.year}, $jam:$menit';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_outlined),
            SizedBox(width: 8),
            Text('Notifikasi'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _tandaiSemuaDibaca,
            child: const Text('Baca semua'),
          ),
        ],
      ),
      body: FutureBuilder<List<NotifikasiModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 52),
                    const SizedBox(height: 12),
                    const Text(
                      'Gagal memuat notifikasi.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => setState(_muatUlang),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          final items = snapshot.data ?? const <NotifikasiModel>[];

          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 150),
                  Icon(Icons.notifications_none, size: 72, color: AppColors.muted),
                  SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Belum ada notifikasi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: 6),
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Aktivitas pengambilan obat dan peringatan stok akan muncul di sini.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                final warna = _warnaUntuk(item.jenis);

                return Material(
                  color: item.dibaca
                      ? AppColors.canvas
                      : AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () async {
                      if (!item.dibaca) {
                        await _repo.tandaiDibaca(item.id);
                        if (mounted) setState(_muatUlang);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.hairline),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: warna.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(_ikonUntuk(item.jenis), color: warna),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.judul,
                                        style: TextStyle(
                                          fontWeight: item.dibaca
                                              ? FontWeight.w600
                                              : FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    if (!item.dibaca)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                if (item.pesan.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    item.pesan,
                                    style: const TextStyle(color: AppColors.body),
                                  ),
                                ],
                                const SizedBox(height: 7),
                                Text(
                                  _formatWaktu(item.createdAt),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
