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

  static const int jumlahKompartemen = 6;
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
    final obatController = TextEditingController(text: jadwalLama?.namaObat ?? '');
    final jumlahController = TextEditingController(
      text: (jadwalLama?.jumlahAngka ?? 1).toString(),
    );
    String satuanTerpilih = jadwalLama?.satuan ?? 'tablet';
    if (!pilihanSatuan.contains(satuanTerpilih)) satuanTerpilih = 'tablet';

    int urutanTerpilih = jadwalLama?.urutanKompartemen ?? 0;
    if (urutanTerpilih < 0 || urutanTerpilih >= jumlahKompartemen) {
      urutanTerpilih = 0;
    }
    TimeOfDay jamTerpilih = _parseJamAwal(jadwalLama?.jam);

    final simpan = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(jadwalLama == null ? 'Tambah Jadwal' : 'Edit Jadwal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.access_time),
                  title: const Text('Jam Pengambilan'),
                  subtitle: Text(_formatJam(jamTerpilih)),
                  onTap: () async {
                    final dipilih = await showTimePicker(
                      context: dialogContext,
                      initialTime: jamTerpilih,
                    );
                    if (dipilih != null) {
                      setDialogState(() => jamTerpilih = dipilih);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: obatController,
                  decoration: const InputDecoration(labelText: 'Nama Obat'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: jumlahController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Jumlah Obat dalam Kompartemen',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: satuanTerpilih,
                  decoration: const InputDecoration(labelText: 'Jenis / Satuan'),
                  items: pilihanSatuan
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
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
                  decoration: const InputDecoration(labelText: 'Kompartemen Carousel'),
                  items: List.generate(
                    jumlahKompartemen,
                    (i) => DropdownMenuItem(
                      value: i,
                      child: Text('Kompartemen #$i'),
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
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );

    if (simpan != true) return;

    final jumlahAngka = int.tryParse(jumlahController.text.trim());
    if (obatController.text.trim().isEmpty || jumlahAngka == null || jumlahAngka <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama obat dan jumlah yang valid wajib diisi.')),
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
                ? 'Kompartemen #$urutanTerpilih sudah dipakai jadwal aktif lain.'
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
        content: Text('Jadwal ${jadwal.namaObat} pukul ${jadwal.jam} akan dinonaktifkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
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

  @override
  Widget build(BuildContext context) {
    final online = context.watch<DeviceProvider>().isMqttConnected;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _bukaDialogJadwal(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Jadwal'),
      ),
      body: Column(
        children: [
          if (!online)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.warning.withValues(alpha: 0.12),
              child: const Row(
                children: [
                  Icon(Icons.cloud_done_outlined, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Dispenser offline. Jadwal tetap disimpan ke Supabase dan akan disinkronkan saat perangkat online.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: FutureBuilder<List<JadwalObatModel>>(
              future: _jadwalFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Gagal memuat jadwal: ${snapshot.error}'));
                }

                final daftar = snapshot.data ?? [];
                if (daftar.isEmpty) {
                  return const Center(child: Text('Belum ada jadwal obat.'));
                }

                return RefreshIndicator(
                  onRefresh: () async => _muatUlang(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                    itemCount: daftar.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final jadwal = daftar[index];
                      return Card(
                        elevation: 0,
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text('#${jadwal.urutanKompartemen}'),
                          ),
                          title: Text(jadwal.namaObat),
                          subtitle: Text('${jadwal.jam} • ${jadwal.jumlahLabel}'),
                          trailing: Wrap(
                            spacing: 2,
                            children: [
                              IconButton(
                                tooltip: 'Edit',
                                onPressed: () => _bukaDialogJadwal(jadwalLama: jadwal),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                              IconButton(
                                tooltip: 'Hapus',
                                onPressed: () => _hapusJadwal(jadwal),
                                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
