import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/services/mqtt_service.dart';
import '../core/services/supabase_service.dart';
import '../core/constants/mqtt_config.dart';
import '../models/device_status.dart';

class DeviceProvider with ChangeNotifier {
  MqttService? _mqttService;

  // Getter publik agar shell bisa meneruskan ke KelolaJadwalScreen.
  // Nullable karena init() berjalan async -- widget yang membaca ini
  // sebelum init() selesai harus menangani null (lihat isSiap di bawah).
  MqttService? get mqttService => _mqttService;

  // True setelah MqttService selesai dibuat, aman dipakai widget lain.
  bool get isSiap => _mqttService != null;

  // Diisi otomatis dari Supabase berdasarkan user yang sedang login.
  String? _lansiaId;
  String get lansiaId => _lansiaId ?? '';

  DeviceStatus status = DeviceStatus.initial();
  bool isLoading = false;
  bool isMqttConnected = false;

  /// Ambil UUID baris "lansia" milik user yang sedang login, sekaligus
  /// namanya untuk ditampilkan di header sapaan dashboard.
  /// Perlu dipanggil sebelum connect MQTT supaya bisa langsung
  /// diprovisioning ke ESP32.
  Future<void> _muatLansiaId() async {
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('Tidak ada user login, lansiaId tidak bisa dimuat.');
      return;
    }

    try {
      final response = await SupabaseService.client
          .from('lansia')
          .select('id, nama')
          .eq('user_id', userId)
          .maybeSingle();

      _lansiaId = response?['id'] as String?;

      final nama = response?['nama'] as String?;
      if (nama != null && nama.isNotEmpty) {
        status = status.copyWith(namaLansia: nama);
      }

      if (_lansiaId == null) {
        debugPrint('Data lansia untuk user ini belum ditemukan di Supabase.');
      }
    } catch (e) {
      debugPrint('Gagal memuat lansiaId dari Supabase: $e');
    }
  }

  Future<void> init() async {
    isLoading = true;
    notifyListeners();

    await _muatLansiaId();

    final mqtt = MqttService(
      broker: MqttConfig.broker,
      port: MqttConfig.port,
      clientId: 'flutter_dispenser_obat_${DateTime.now().millisecondsSinceEpoch}',
      username: MqttConfig.username,
      password: MqttConfig.password,
    );
    _mqttService = mqtt;

    final connected = await mqtt.connect(
      _handleMessage,
      onConnectionChanged: (isConnected) {
        isMqttConnected = isConnected;
        notifyListeners();
      },
    );

    if (connected) {
      isMqttConnected = true;

      mqtt.subscribe(MqttConfig.topicMedicineStatus);
      mqtt.subscribe(MqttConfig.topicMedicineStock);
      mqtt.subscribe(MqttConfig.topicMedicineGlass);
      mqtt.subscribe(MqttConfig.topicMedicineSchedule);
      mqtt.subscribe(MqttConfig.topicMedicineHistory);
      mqtt.subscribe(MqttConfig.topicMedicineNotify);

      // Kirim Lansia ID ke ESP32 supaya alat tahu jadwal siapa yang harus
      // diambil dari Supabase. Aman dikirim berulang setiap connect;
      // ESP32 hanya menyimpan ulang ke memori jika ID berbeda.
      if (_lansiaId != null) {
        mqtt.publish(MqttConfig.topicCmdSetLansia, _lansiaId!);
      }

      await Future.delayed(const Duration(milliseconds: 500));
      await refreshDeviceStatus();
    }

    isLoading = false;
    notifyListeners();
  }

  void _handleMessage(String topic, String payload) {
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;

      switch (topic) {
        case MqttConfig.topicMedicineStatus:
          status = status.copyWith(
            isDeviceOnline: data['online'] ?? false,
            wifiStatusText: data['wifi'] ?? 'Tidak terhubung',
          );
          break;

        case MqttConfig.topicMedicineStock:
          status = status.copyWith(
            stokObatPercent: data['percent'] ?? 0,
          );
          break;

        case MqttConfig.topicMedicineGlass:
          status = status.copyWith(
            statusGelasTerisi: data['filled'] ?? false,
          );
          break;

        case MqttConfig.topicMedicineSchedule:
          final nextData = data['next'] as Map<String, dynamic>?;
          if (nextData != null) {
            status = status.copyWith(
              nextScheduleTime: nextData['time'] ?? '--:--',
              nextScheduleObat: nextData['obat'] ?? '-',
              nextScheduleJumlah: nextData['jumlah'] ?? '-',
            );
          }

          final todayData = data['today'] as List<dynamic>?;
          if (todayData != null) {
            final schedules = todayData
                .map((item) => JadwalItem.fromJson(item as Map<String, dynamic>))
                .toList();
            status = status.copyWith(todaySchedule: schedules);
          }
          break;

        default:
          break;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error parsing MQTT payload dari topic $topic: $e');
    }
  }

  Future<void> refreshDeviceStatus() async {
    _mqttService?.publish(MqttConfig.topicCmdRefresh, '1');
  }

  void publishDispenseCommand() {
    _mqttService?.publish(MqttConfig.topicCmdDispense, '1');
  }

  @override
  void dispose() {
    _mqttService?.disconnect();
    super.dispose();
  }
}