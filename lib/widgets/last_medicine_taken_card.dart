import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Menampilkan info konsumsi obat terakhir (nama obat, waktu, status).
/// Data diambil sekali saat dashboard dibuka / refresh, dari
/// riwayat_konsumsi (baris terbaru).
class LastMedicineTakenCard extends StatelessWidget {
  final bool isLoading;
  final String? namaObatTerakhir;
  final DateTime? waktuTerakhir;
  final String? statusTerakhir; // 'diambil' | 'gagal_verifikasi'

  const LastMedicineTakenCard({
    super.key,
    required this.isLoading,
    this.namaObatTerakhir,
    this.waktuTerakhir,
    this.statusTerakhir,
  });

  String _formatWaktuRelatif(DateTime waktu) {
    final selisih = DateTime.now().difference(waktu);
    if (selisih.inMinutes < 1) return 'Baru saja';
    if (selisih.inMinutes < 60) return '${selisih.inMinutes} menit lalu';
    if (selisih.inHours < 24) return '${selisih.inHours} jam lalu';
    return '${waktu.day}/${waktu.month}/${waktu.year} ${waktu.hour.toString().padLeft(2, '0')}:${waktu.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final berhasil = statusTerakhir == 'diambil';

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isLoading
                  ? AppColors.surfaceStrong
                  : (berhasil ? const Color(0xFFEAF7EE) : const Color(0xFFFFF7E6)),
              child: Icon(
                berhasil ? Icons.check_circle_outline : Icons.history,
                color: berhasil ? AppColors.success : AppColors.warning,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Obat terakhir diambil',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (isLoading)
                    const SizedBox(
                      height: 14,
                      width: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else if (namaObatTerakhir == null)
                    Text(
                      'Belum ada riwayat',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.ink,
                      ),
                    )
                  else
                    Text(
                      '$namaObatTerakhir • ${_formatWaktuRelatif(waktuTerakhir!)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
