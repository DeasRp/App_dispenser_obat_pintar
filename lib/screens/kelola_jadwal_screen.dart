import 'package:flutter/material.dart';
import '../models/jadwal_obat_model.dart';
import '../repositories/jadwal_repository.dart';
import '../core/services/mqtt_service.dart';
import '../core/constants/mqtt_config.dart';
import '../core/utils/audio_track_helper.dart';
import '../core/theme/app_theme.dart';

/// Screen untuk keluarga mengatur jadwal obat lansia.
/// Setelah setiap perubahan, kirim perintah MQTT supaya ESP32 langsung
/// menyinkronkan jadwal terbaru tanpa perlu menunggu jadwal sync
/// berkala (interval 30 menit di firmware).
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

  /// Parse string "HH:mm" (dari data lama) jadi TimeOfDay,
  /// dipakai sebagai nilai awal TimePicker saat mode edit.
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
    final jumlahController = TextEditingController(text: jadwalLama?.jumlah ?? '1 tablet');
    final urutanController = TextEditingController(
      text: (jadwalLama?.urutanKompartemen ?? 0).toString(),
    );

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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.hairline, width: 1),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        color: AppColors.canvas,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, color: AppColors.muted, size: 20),
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
                  TextField(
                    controller: jumlahController,
                    decoration: const InputDecoration(
                      labelText: 'Jumlah',
                      hintText: 'Misal: 1 tablet',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: urutanController,
                    decoration: const InputDecoration(
                      labelText: 'Urutan Kompartemen Carousel',
                      hintText: '0, 1, 2, ...',
                    ),
                    keyboardType: TextInputType.number,
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

    final jadwalBaru = JadwalObatModel(
      lansiaId: widget.lansiaId,
      jam: _formatJam(jamTerpilih),
      namaObat: obatController.text.trim(),
      jumlah: jumlahController.text.trim(),
      // Track audio ditentukan otomatis dari jam, user tidak perlu isi manual.
      trackAudio: tentukanTrackAudio(jamTerpilih),
      urutanKompartemen: int.tryParse(urutanController.text.trim()) ?? 0,
    );

    if (jadwalLama == null) {
      await _repo.tambahJadwal(jadwalBaru);
    } else {
      await _repo.updateJadwal(jadwalLama.id!, jadwalBaru);
    }

    _sinkronKeESP32();
    _muatUlang();
  }

  Future<void> _hapusJadwal(JadwalObatModel jadwal) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Jadwal?'),
        content: Text('Jadwal ${jadwal.namaObat} pukul ${jadwal.jam} akan dinonaktifkan.'),
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
      appBar: AppBar(title: const Text('Kelola Jadwal Obat')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _bukaDialogJadwal(),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<JadwalObatModel>>(
        future: _jadwalFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Gagal memuat jadwal: ${snapshot.error}'));
          }

          final daftarJadwal = snapshot.data ?? [];
          if (daftarJadwal.isEmpty) {
            return Center(
              child: Text(
                'Belum ada jadwal, tekan + untuk menambah.',
                style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: daftarJadwal.length,
            itemBuilder: (context, index) {
              final jadwal = daftarJadwal[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.surfaceStrong,
                        child: Text(
                          jadwal.urutanKompartemen.toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              jadwal.namaObat,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Pukul ${jadwal.jam} • ${jadwal.jumlah}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: AppColors.muted, size: 22),
                        onPressed: () => _bukaDialogJadwal(jadwalLama: jadwal),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.muted, size: 22),
                        onPressed: () => _hapusJadwal(jadwal),
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