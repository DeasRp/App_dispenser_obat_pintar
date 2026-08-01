import 'package:flutter/material.dart';
import '../models/jadwal_obat_model.dart';
import '../repositories/jadwal_repository.dart';
import '../core/services/mqtt_service.dart';
import '../core/constants/mqtt_config.dart';

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

  Future<void> _bukaDialogJadwal({JadwalObatModel? jadwalLama}) async {
    final jamController = TextEditingController(text: jadwalLama?.jam ?? '08:00');
    final obatController = TextEditingController(text: jadwalLama?.namaObat ?? '');
    final jumlahController = TextEditingController(text: jadwalLama?.jumlah ?? '1 tablet');
    final trackController = TextEditingController(
      text: (jadwalLama?.trackAudio ?? 1).toString(),
    );
    final urutanController = TextEditingController(
      text: (jadwalLama?.urutanKompartemen ?? 0).toString(),
    );

    final simpan = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(jadwalLama == null ? 'Tambah jadwal' : 'Edit jadwal'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: jamController,
                decoration: const InputDecoration(labelText: 'Jam (HH:mm)'),
              ),
              TextField(
                controller: obatController,
                decoration: const InputDecoration(labelText: 'Nama obat'),
              ),
              TextField(
                controller: jumlahController,
                decoration: const InputDecoration(labelText: 'Jumlah (mis. 1 tablet)'),
              ),
              TextField(
                controller: trackController,
                decoration: const InputDecoration(
                  labelText: 'Nomor track audio DFPlayer',
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: urutanController,
                decoration: const InputDecoration(
                  labelText: 'Urutan kompartemen carousel (0, 1, 2, ...)',
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
      ),
    );

    if (simpan != true) return;

    final jadwalBaru = JadwalObatModel(
      lansiaId: widget.lansiaId,
      jam: jamController.text.trim(),
      namaObat: obatController.text.trim(),
      jumlah: jumlahController.text.trim(),
      trackAudio: int.tryParse(trackController.text.trim()) ?? 1,
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
        title: const Text('Hapus jadwal?'),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola jadwal obat')),
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
            return const Center(child: Text('Belum ada jadwal, tekan + untuk menambah.'));
          }

          return ListView.builder(
            itemCount: daftarJadwal.length,
            itemBuilder: (context, index) {
              final jadwal = daftarJadwal[index];
              return ListTile(
                leading: CircleAvatar(child: Text(jadwal.urutanKompartemen.toString())),
                title: Text('${jadwal.jam} - ${jadwal.namaObat}'),
                subtitle: Text(jadwal.jumlah),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _bukaDialogJadwal(jadwalLama: jadwal),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _hapusJadwal(jadwal),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
