import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'supabase_service.dart';

class CsvExportService {
  final _client = SupabaseService.client;

  Future<int> exportRiwayatKonsumsi({
    required String lansiaId,
    required int hari,
  }) async {
    if (lansiaId.isEmpty) {
      throw Exception('Data Lansia belum tersedia.');
    }

    final sejak = DateTime.now().subtract(Duration(days: hari));

    final response = await _client
        .from('riwayat_konsumsi')
        .select(
          'nama_obat,jumlah,satuan,waktu_jadwal,waktu_diambil,status,created_at',
        )
        .eq('lansia_id', lansiaId)
        .gte('created_at', sejak.toIso8601String())
        .order('created_at', ascending: false);

    final rows = List<Map<String, dynamic>>.from(response as List);

    if (rows.isEmpty) {
      throw Exception('Belum ada riwayat konsumsi untuk $hari hari terakhir.');
    }

    final csv = StringBuffer();
    // BOM membuat karakter UTF-8 terbaca dengan baik saat dibuka di Excel.
    csv.write('\uFEFF');
    csv.writeln(
      'Tanggal,Waktu Jadwal,Waktu Diambil,Nama Obat,Jumlah,Satuan,Status',
    );

    for (final row in rows) {
      final createdAt = _parseDateTime(row['created_at']);
      final waktuDiambil = _parseDateTime(row['waktu_diambil']);

      csv.writeln([
        _formatTanggal(createdAt),
        _formatWaktuJadwal(row['waktu_jadwal']),
        waktuDiambil == null ? '-' : _formatJam(waktuDiambil),
        row['nama_obat']?.toString() ?? '-',
        row['jumlah']?.toString() ?? '-',
        row['satuan']?.toString() ?? '-',
        _formatStatus(row['status']?.toString() ?? ''),
      ].map(_escapeCsv).join(','));
    }

    final directory = await getTemporaryDirectory();
    final now = DateTime.now();
    final filename =
        'riwayat_konsumsi_${hari}hari_${now.year}${_dua(now.month)}${_dua(now.day)}_${_dua(now.hour)}${_dua(now.minute)}.csv';
    final file = File('${directory.path}/$filename');
    await file.writeAsString(csv.toString(), flush: true);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      subject: 'Riwayat Konsumsi Obat Remindora',
      text: 'Riwayat konsumsi obat $hari hari terakhir dari Remindora.',
    );

    return rows.length;
  }

  DateTime? _parseDateTime(dynamic value) {
    final raw = value?.toString();
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }

  String _formatTanggal(DateTime? value) {
    if (value == null) return '-';
    return '${_dua(value.day)}/${_dua(value.month)}/${value.year}';
  }

  String _formatJam(DateTime value) => '${_dua(value.hour)}:${_dua(value.minute)}';

  String _formatWaktuJadwal(dynamic value) {
    final raw = value?.toString() ?? '';
    if (raw.isEmpty) return '-';
    return raw.length >= 5 ? raw.substring(0, 5) : raw;
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'diambil':
        return 'Diambil';
      case 'terlewat':
        return 'Terlewat';
      case 'gagal_verifikasi':
        return 'Gagal verifikasi';
      case 'terlambat':
        return 'Terlambat';
      default:
        return status.isEmpty ? '-' : status;
    }
  }

  String _escapeCsv(dynamic value) {
    final text = value?.toString() ?? '';
    if (text.contains(',') || text.contains('"') || text.contains('\n')) {
      return '"${text.replaceAll('"', '""')}"';
    }
    return text;
  }

  String _dua(int value) => value.toString().padLeft(2, '0');
}
