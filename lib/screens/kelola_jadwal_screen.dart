import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/mqtt_config.dart';
import '../core/services/mqtt_service.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/audio_track_helper.dart';
import '../models/jadwal_obat_model.dart';
import '../repositories/jadwal_repository.dart';

class KelolaJadwalScreen extends StatefulWidget {
  final String lansiaId;
  final MqttService mqttService;

  const KelolaJadwalScreen({
    super.key,
    required this.lansiaId,
    required this.mqttService,
  });

  @override
  State<KelolaJadwalScreen> createState() => _KelolaJadwalScreenState();
}

class _KelolaJadwalScreenState extends State<KelolaJadwalScreen> {
  final _repo = JadwalRepository();
  late Future<List<JadwalObatModel>> _jadwalFuture;

  static const int jumlahKompartemen = 6;
  static const List<String> pilihanSatuan = [
    'tablet',
    'kapsul',
    'butir',
    'sendok',
  ];

  @override
  void initState() {
    super.initState();
    _muatUlang();
  }

  void _muatUlang() {
    setState(() {
      _jadwalFuture = _repo.getJadwalByLansia(widget.lansiaId);
    });
  }

  void _sinkronKeESP32() {
    widget.mqttService.publish(MqttConfig.topicCmdSyncJadwal, '1');
  }

  TimeOfDay _parseJamAwal(String? jam) {
    if (jam == null) return const TimeOfDay(hour: 8, minute: 0);
    final parts = jam.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 8,
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
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(jadwalLama == null ? 'Tambah Jadwal' : 'Edit Jadwal'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final dipilih = await showTimePicker(
                        context: context,
                        initialTime: jamTerpilih,
                      );
                      if (dipilih != null) {
                        setDialogState(() => jamTerpilih = dipilih);
                      }
                    },
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.hairline, width: 1),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        color: AppColors.canvas,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: AppColors.muted,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Jam Pengambilan',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.muted,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatJam(jamTerpilih),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: obatController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Obat',
                      hintText: 'Masukkan nama obat',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: jumlahController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(
                            labelText: 'Jumlah',
                            hintText: '1',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: satuanTerpilih,
                          decoration: const InputDecoration(
                            labelText: 'Satuan',
                          ),
                          items: pilihanSatuan
                              .map(
                                (satuan) => DropdownMenuItem(
                                  value: satuan,
                                  child: Text(satuan),
                                ),
                              )
                              .toList(),
                          onChanged: (nilai) {
                            if (nilai != null) {
                              setDialogState(() => satuanTerpilih = nilai);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: urutanTerpilih,
                    decoration: const InputDecoration(
                      labelText: 'Kompartemen Carousel',
                    ),
                    items: List.generate(jumlahKompartemen, (i) => i)
                        .map(
                          (i) => DropdownMenuItem(
                            value: i,
                            child: Text('Kompartemen #$i'),
                          ),
                        )
                        .toList(),
                    onChanged: (nilai) {
                      if (nilai != null) {
                        setDialogState(() => urutanTerpilih = nilai);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Simpan'),
              ),
            ],
          );
        },
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
    } catch (e) {
      if (!mounted) return;
      final pesan = e.toString().contains('duplicate') ||
              e.toString().contains('uq_kompartemen_aktif_per_lansia')
          ? 'Kompartemen #$urutanTerpilih sudah dipakai jadwal aktif lain. Pilih kompartemen lain.'
          : 'Gagal menyimpan jadwal. Coba lagi.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan)));
      return;
    }

    _sinkronKeESP32();
    _muatUlang();
  }

  Future<void> _hapusJadwal(JadwalObatModel jadwal) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Jadwal?'),
        content: Text(
          'Jadwal ${jadwal.namaObat} pukul ${jadwal.jam} akan dinonaktifkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (konfirmasi != true) return;

    await _repo.nonaktifkanJadwal(jadwal.id!);
    _sinkronKeESP32();
    _muatUlang();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Jadwal Obat'),
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _bukaDialogJadwal(),
        elevation: 3,
        icon: const Icon(Icons.add),
        label: const Text(
          'Tambah Jadwal',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: FutureBuilder<List<JadwalObatModel>>(
        future: _jadwalFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Gagal memuat jadwal: ${snapshot.error}'),
            );
          }

          final daftarJadwal = snapshot.data ?? [];
          if (daftarJadwal.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 64,
                    color: AppColors.muted.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada jadwal obat',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap tombol + untuk menambah jadwal',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.mutedSoft,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: daftarJadwal.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final jadwal = daftarJadwal[index];

              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: AppColors.canvas,
                  border: Border.all(color: AppColors.hairline, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '#${jadwal.urutanKompartemen}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    jadwal.namaObat,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: AppColors.ink,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppColors.muted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          jadwal.jam,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.body,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('•'),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.medication,
                          size: 14,
                          color: AppColors.muted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          jadwal.jumlahLabel,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.body,
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _bukaDialogJadwal(jadwalLama: jadwal),
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppColors.error,
                        ),
                        onPressed: () => _hapusJadwal(jadwal),
                        tooltip: 'Hapus',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
