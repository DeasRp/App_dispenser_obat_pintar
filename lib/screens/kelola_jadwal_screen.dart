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

  // Harus SAMA dengan JUMLAH_KOMPARTEMEN di firmware ESP32
  // (dispenser_obat_pintar_fixed.ino). Kalau nanti jumlah kompartemen
  // fisik carousel berubah, ubah nilai ini juga.
  static const int jumlahKompartemen = 6;

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
    int urutanTerpilih = jadwalLama?.urutanKompartemen ?? 0;
    if (urutanTerpilih < 0 || urutanTerpilih >= jumlahKompartemen) {
      urutanTerpilih = 0; // jaga-jaga kalau data lama di luar rentang baru
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
                  DropdownButtonFormField<int>(
                    value: urutanTerpilih,
                    decoration: const InputDecoration(
                      labelText: 'Kompartemen Carousel',
                    ),
                    items: List.generate(jumlahKompartemen, (i) => i)
                        .map((i) => DropdownMenuItem(
                              value: i,
                              child: Text('Kompartemen #$i'),
                            ))
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

    final jadwalBaru = JadwalObatModel(
      lansiaId: widget.lansiaId,
      jam: _formatJam(jamTerpilih),
      namaObat: obatController.text.trim(),
      jumlah: jumlahController.text.trim(),
      // Track audio ditentukan otomatis dari jam, user tidak perlu isi manual.
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
      appBar: AppBar(
        title: const Text('Kelola Jadwal Obat'),
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: Container(
        decoration: BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.3),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ) as Decoration?,
        child: FloatingActionButton.extended(
          onPressed: () => _bukaDialogJadwal(),
          elevation: 3,
          icon: const Icon(Icons.add),
          label: const Text('Tambah Jadwal', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        style: TextStyle(
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
                        const Icon(Icons.access_time, size: 14, color: AppColors.muted),
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
                        Container(
                          width: 3,
                          height: 3,
                          decoration: const BoxDecoration(
                            color: AppColors.mutedSoft,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.medication, size: 14, color: AppColors.muted),
                        const SizedBox(width: 4),
                        Text(
                          jadwal.jumlah,
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
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.edit_outlined, color: Color(0xFF3B82F6), size: 20),
                          onPressed: () => _bukaDialogJadwal(jadwalLama: jadwal),
                          tooltip: 'Edit',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                          onPressed: () => _hapusJadwal(jadwal),
                          tooltip: 'Hapus',
                        ),
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